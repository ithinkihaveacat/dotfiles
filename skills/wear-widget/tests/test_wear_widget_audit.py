"""Hermetic unit tests for wear-widget-audit."""

from __future__ import annotations

import contextlib
import glob
import importlib.machinery
import importlib.util
import io
import json
import os
import stat
import struct
import subprocess
import sys
import tempfile
import unittest
import zipfile
import zlib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

SKILL_DIR = Path(__file__).resolve().parent.parent
SCRIPT_PATH = SKILL_DIR / "scripts" / "wear-widget-audit"


def _load_audit_module() -> Any:
    loader = importlib.machinery.SourceFileLoader(
        "wear_widget_audit_mod", str(SCRIPT_PATH)
    )
    spec = importlib.util.spec_from_loader("wear_widget_audit_mod", loader)
    assert spec is not None
    assert spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


WWA = _load_audit_module()


def _uleb128(val: int) -> bytes:
    out = bytearray()
    while True:
        byte = val & 0x7F
        val >>= 7
        if val:
            out.append(byte | 0x80)
        else:
            out.append(byte)
            break
    return bytes(out)


def _png_chunk(ctype: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(ctype + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + ctype + data + struct.pack(">I", crc)


def build_rgba_png(
    width: int,
    height: int,
    *,
    fill_rgba: tuple[int, int, int, int] = (24, 28, 36, 255),
    corner_alphas: tuple[int, int, int, int] | None = None,
    circular_mask: bool = False,
    seed_byte: int = 0,
) -> bytes:
    """Create a valid RGBA PNG using only the Python standard library."""
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    raw_rows = bytearray()
    cx = (width - 1) / 2.0
    cy = (height - 1) / 2.0
    rx = width / 2.0
    ry = height / 2.0

    for y in range(height):
        raw_rows.append(0)  # Filter type 0 (None)
        for x in range(width):
            r, g, b, a = fill_rgba
            if x == width // 2 and y == height // 2:
                r = (r + seed_byte) & 0xFF
            if circular_mask:
                dx = (x - cx) / rx if rx else 0.0
                dy = (y - cy) / ry if ry else 0.0
                if dx * dx + dy * dy > 1.0:
                    a = 0
            if corner_alphas is not None:
                if x == 0 and y == 0:
                    a = corner_alphas[0]
                elif x == width - 1 and y == 0:
                    a = corner_alphas[1]
                elif x == 0 and y == height - 1:
                    a = corner_alphas[2]
                elif x == width - 1 and y == height - 1:
                    a = corner_alphas[3]
            raw_rows.extend((r, g, b, a))

    compressed = zlib.compress(bytes(raw_rows), level=1)
    return (
        b"\x89PNG\r\n\x1a\n"
        + _png_chunk(b"IHDR", ihdr)
        + _png_chunk(b"IDAT", compressed)
        + _png_chunk(b"IEND", b"")
    )


@dataclass
class SyntheticClassSpec:
    descriptor: str
    superclass: str = "Landroidx/glance/wear/GlanceWearWidgetService;"
    runtime_annotations: list[tuple[str, str | None]] = field(default_factory=list)
    build_annotations: list[tuple[str, str | None]] = field(default_factory=list)
    init_mode: str = "di_empty"  # "direct" | "di_empty" | "koin_lazy" | "bind_only"
    init_widget_desc: str | None = None


def build_synthetic_dex(
    classes: list[SyntheticClassSpec],
    *,
    include_live_reader: bool = False,
    include_mutf8_null_string: bool = True,
    include_design_tokens: bool = False,
) -> bytes:
    """Build a spec-compliant Dalvik DEX 035 binary for hermetic C06 tests."""
    strings_set: set[str] = {
        "",
        "V",
        "VL",
        "L",
        "<init>",
        "onCreate",
        "onBind",
        "discover",
        "lazy",
        "a",
        "d1",
        "widget",
        "widget$delegate",
        "Ljava/lang/Object;",
        "Landroid/content/pm/PackageManager;",
        "Lkotlin/Lazy;",
        "Lkotlin/LazyKt;",
        "Lkotlin/Metadata;",
        "queryIntentServices",
        "getAnnotation",
        WWA.ACTION_WIDGET,
    }
    if include_mutf8_null_string:
        strings_set.add("\x00synthetic_kotlin_metadata_header")
    if include_design_tokens:
        strings_set.add("Landroidx/glance/wear/WearWidgetParams;")
        strings_set.add("usableWidthDp")
        strings_set.add("WearM3")
        strings_set.add("remoteColorScheme")

    all_classes = list(classes)
    if include_live_reader:
        all_classes.append(
            SyntheticClassSpec(
                descriptor="Landroidx/glance/wear/GlanceWearWidgetManager$State;",
                superclass="Ljava/lang/Object;",
                init_mode="reader",
            )
        )

    type_set: set[str] = {
        "V",
        "Ljava/lang/Object;",
        "Landroid/content/pm/PackageManager;",
        "Lkotlin/Lazy;",
        "Lkotlin/LazyKt;",
        "Lkotlin/Metadata;",
    }

    for c in all_classes:
        strings_set.add(c.descriptor)
        strings_set.add(c.superclass)
        type_set.add(c.descriptor)
        type_set.add(c.superclass)
        for adesc, cval in c.runtime_annotations + c.build_annotations:
            strings_set.add(adesc)
            type_set.add(adesc)
            if cval:
                strings_set.add(cval)
                type_set.add(cval)
        if c.init_widget_desc:
            strings_set.add(c.init_widget_desc)
            type_set.add(c.init_widget_desc)
        if c.init_mode in ("koin_lazy", "r8_inlined_lazy"):
            lam = c.descriptor[:-1] + "$special$$inlined$inject$1;"
            strings_set.add(lam)
            type_set.add(lam)
        if c.init_mode == "r8_inlined_lazy":
            strings_set.add("Lc03;")
            type_set.add("Lc03;")

    sorted_strings = sorted(strings_set, key=lambda s: tuple(ord(ch) for ch in s))
    str_idx = {s: i for i, s in enumerate(sorted_strings)}

    sorted_types = sorted(type_set, key=lambda t: str_idx[t])
    type_idx = {t: i for i, t in enumerate(sorted_types)}

    # Protos: (return_type, params_tuple, shorty)
    proto_set: set[tuple[str, tuple[str, ...], str]] = {
        ("V", (), "V"),
        ("Lkotlin/Lazy;", ("Ljava/lang/Object;",), "LL"),
        ("V", ("Ljava/lang/Object;",), "VL"),
    }
    strings_set_extra = False
    for c in all_classes:
        if c.init_mode in ("koin_lazy", "r8_inlined_lazy"):
            proto_set.add(("V", (c.descriptor,), "VL"))
    if "LL" not in str_idx:
        sorted_strings = sorted(
            strings_set | {"LL"}, key=lambda s: tuple(ord(ch) for ch in s)
        )
        str_idx = {s: i for i, s in enumerate(sorted_strings)}
        sorted_types = sorted(type_set, key=lambda t: str_idx[t])
        type_idx = {t: i for i, t in enumerate(sorted_types)}
        _ = strings_set_extra

    sorted_protos = sorted(
        proto_set,
        key=lambda p: (type_idx[p[0]], tuple(type_idx[x] for x in p[1])),
    )
    proto_idx = {(p[0], p[1]): i for i, p in enumerate(sorted_protos)}

    # Fields & Methods
    fields_set: set[tuple[str, str, str]] = set()  # (owner, ftype, name)
    methods_set: set[tuple[str, tuple[str, tuple[str, ...]], str]] = {
        ("Landroid/content/pm/PackageManager;", ("V", ()), "queryIntentServices"),
        ("Lkotlin/LazyKt;", ("Lkotlin/Lazy;", ("Ljava/lang/Object;",)), "lazy"),
    }

    for c in all_classes:
        methods_set.add((c.superclass, ("V", ()), "<init>"))
        methods_set.add((c.descriptor, ("V", ()), "<init>"))
        if c.init_mode == "direct" and c.init_widget_desc:
            methods_set.add((c.init_widget_desc, ("V", ()), "<init>"))
            fields_set.add((c.descriptor, c.init_widget_desc, "widget"))
        elif c.init_mode == "di_empty":
            methods_set.add((c.descriptor, ("V", ()), "onCreate"))
        elif c.init_mode == "koin_lazy":
            lam = c.descriptor[:-1] + "$special$$inlined$inject$1;"
            methods_set.add((lam, ("V", (c.descriptor,)), "<init>"))
            fields_set.add((c.descriptor, "Lkotlin/Lazy;", "widget$delegate"))
        elif c.init_mode == "r8_inlined_lazy":
            lam = c.descriptor[:-1] + "$special$$inlined$inject$1;"
            methods_set.add((lam, ("V", (c.descriptor,)), "<init>"))
            methods_set.add(("Lc03;", ("V", ("Ljava/lang/Object;",)), "<init>"))
            fields_set.add((c.descriptor, "Lc03;", "widget$delegate"))
        elif c.init_mode == "bind_only":
            methods_set.add((c.descriptor, ("V", ()), "onBind"))
        elif c.init_mode == "reader":
            methods_set.add((c.descriptor, ("V", ()), "discover"))

    sorted_fields = sorted(
        fields_set, key=lambda f: (type_idx[f[0]], str_idx[f[2]], type_idx[f[1]])
    )
    field_idx = {f: i for i, f in enumerate(sorted_fields)}

    sorted_methods = sorted(
        methods_set,
        key=lambda m: (type_idx[m[0]], str_idx[m[2]], proto_idx[m[1]]),
    )
    method_idx = {m: i for i, m in enumerate(sorted_methods)}

    # Layout fixed tables after 112-byte header
    buf = bytearray(112)

    def align4() -> None:
        while len(buf) % 4 != 0:
            buf.append(0)

    string_ids_off = len(buf)
    buf.extend(b"\x00" * (4 * len(sorted_strings)))

    type_ids_off = len(buf)
    for t in sorted_types:
        buf.extend(struct.pack("<I", str_idx[t]))

    proto_ids_off = len(buf)
    buf.extend(b"\x00" * (12 * len(sorted_protos)))

    field_ids_off = len(buf)
    for owner, ftype, fname in sorted_fields:
        buf.extend(
            struct.pack("<HHI", type_idx[owner], type_idx[ftype], str_idx[fname])
        )

    method_ids_off = len(buf)
    for owner, pkey, mname in sorted_methods:
        buf.extend(
            struct.pack("<HHI", type_idx[owner], proto_idx[pkey], str_idx[mname])
        )

    class_defs_off = len(buf)
    buf.extend(b"\x00" * (32 * len(all_classes)))

    align4()
    data_off = len(buf)

    # 1. Proto param type_lists
    for i, (ret_t, params, shorty) in enumerate(sorted_protos):
        params_off = 0
        if params:
            align4()
            params_off = len(buf)
            buf.extend(struct.pack("<I", len(params)))
            for pt in params:
                buf.extend(struct.pack("<H", type_idx[pt]))
        struct.pack_into(
            "<3I",
            buf,
            proto_ids_off + i * 12,
            str_idx[shorty],
            type_idx[ret_t],
            params_off,
        )

    # 2. String data items (encode U+0000 as MUTF-8 0xC0 0x80)
    for i, s in enumerate(sorted_strings):
        s_off = len(buf)
        struct.pack_into("<I", buf, string_ids_off + i * 4, s_off)
        mutf8 = bytearray()
        for ch in s:
            if ch == "\x00":
                mutf8.extend(b"\xc0\x80")
            else:
                mutf8.extend(ch.encode("utf-8"))
        buf.extend(_uleb128(len(s)))
        buf.extend(mutf8)
        buf.append(0)

    def make_code_item(registers: int, ins: int, outs: int, words: list[int]) -> int:
        align4()
        off = len(buf)
        buf.extend(struct.pack("<4H2I", registers, ins, outs, 0, 0, len(words)))
        for w in words:
            buf.extend(struct.pack("<H", w & 0xFFFF))
        return off

    def make_annotations_dir(
        rt_annos: list[tuple[str, str | None]],
        bld_annos: list[tuple[str, str | None]],
    ) -> int:
        if not rt_annos and not bld_annos:
            return 0
        item_offs: list[int] = []
        for vis, alist in ((0x01, rt_annos), (0x00, bld_annos)):
            for adesc, cval in alist:
                a_off = len(buf)
                buf.append(vis)
                buf.extend(_uleb128(type_idx[adesc]))
                if cval is not None:
                    buf.extend(_uleb128(1))
                    buf.extend(_uleb128(str_idx["a"]))
                    t_val = type_idx[cval]
                    raw_t = t_val.to_bytes(2, "little")
                    buf.append(0x18 | (1 << 5))  # VALUE_TYPE, size=2
                    buf.extend(raw_t)
                else:
                    buf.extend(_uleb128(0))
                item_offs.append(a_off)
        align4()
        set_off = len(buf)
        buf.extend(struct.pack("<I", len(item_offs)))
        for ioff in item_offs:
            buf.extend(struct.pack("<I", ioff))
        align4()
        dir_off = len(buf)
        buf.extend(struct.pack("<4I", set_off, 0, 0, 0))
        return dir_off

    # 3. Class defs, annotations, code items, and class_data_items
    for c_i, c in enumerate(all_classes):
        anno_dir_off = make_annotations_dir(c.runtime_annotations, c.build_annotations)

        ifields: list[tuple[int, int]] = []
        dmethods: list[tuple[int, int, int]] = []
        vmethods: list[tuple[int, int, int]] = []

        super_init_m = method_idx[(c.superclass, ("V", ()), "<init>")]
        self_init_m = method_idx[(c.descriptor, ("V", ()), "<init>")]

        if c.init_mode == "direct" and c.init_widget_desc:
            w_t = type_idx[c.init_widget_desc]
            w_init_m = method_idx[(c.init_widget_desc, ("V", ()), "<init>")]
            f_i = field_idx[(c.descriptor, c.init_widget_desc, "widget")]
            ifields.append((f_i, 0x0012))
            # registers=2 (v0=local, v1=this), ins=1
            words = [
                0x1070,
                super_init_m,
                0x0001,  # invoke-direct {v1}, super.<init>
                0x0022,
                w_t,  # new-instance v0, Widget
                0x1070,
                w_init_m,
                0x0000,  # invoke-direct {v0}, Widget.<init>
                0x105B,
                f_i,  # iput-object v0, v1, Service.widget
                0x000E,  # return-void
            ]
            c_off = make_code_item(2, 1, 1, words)
            dmethods.append((self_init_m, 0x10001, c_off))

        elif c.init_mode == "koin_lazy":
            lam = c.descriptor[:-1] + "$special$$inlined$inject$1;"
            lam_t = type_idx[lam]
            lam_init_m = method_idx[(lam, ("V", (c.descriptor,)), "<init>")]
            lazy_m = method_idx[
                ("Lkotlin/LazyKt;", ("Lkotlin/Lazy;", ("Ljava/lang/Object;",)), "lazy")
            ]
            f_i = field_idx[(c.descriptor, "Lkotlin/Lazy;", "widget$delegate")]
            ifields.append((f_i, 0x0012))
            # registers=2 (v0=local, v1=this), ins=1
            words = [
                0x1070,
                super_init_m,
                0x0001,  # invoke-direct {v1}, super.<init>
                0x0022,
                lam_t,  # new-instance v0, Lambda
                0x2070,
                lam_init_m,
                0x0010,  # invoke-direct {v0, v1}, Lambda.<init>(this)
                0x1071,
                lazy_m,
                0x0000,  # invoke-static {v0}, LazyKt.lazy
                0x000C,  # move-result-object v0
                0x105B,
                f_i,  # iput-object v0, v1, Service.widget$delegate
                0x000E,  # return-void
            ]
            c_off = make_code_item(2, 1, 2, words)
            dmethods.append((self_init_m, 0x10001, c_off))

        elif c.init_mode == "r8_inlined_lazy":
            lam = c.descriptor[:-1] + "$special$$inlined$inject$1;"
            lam_t = type_idx[lam]
            lam_init_m = method_idx[(lam, ("V", (c.descriptor,)), "<init>")]
            c03_t = type_idx["Lc03;"]
            c03_init_m = method_idx[("Lc03;", ("V", ("Ljava/lang/Object;",)), "<init>")]
            f_i = field_idx[(c.descriptor, "Lc03;", "widget$delegate")]
            ifields.append((f_i, 0x0012))
            # registers=3 (v0=lambda, v1=SynchronizedLazyImpl, v2=this), ins=1
            words = [
                0x1070,
                super_init_m,
                0x0002,  # invoke-direct {v2}, super.<init>
                0x0022,
                lam_t,  # new-instance v0, Lambda
                0x2070,
                lam_init_m,
                0x0020,  # invoke-direct {v0, v2}, Lambda.<init>(this)
                0x0122,
                c03_t,  # new-instance v1, Lc03;
                0x2070,
                c03_init_m,
                0x0001,  # invoke-direct {v1, v0}, Lc03;.<init>(lambda)
                0x215B,
                f_i,  # iput-object v1, v2, Service.widget$delegate
                0x000E,  # return-void
            ]
            c_off = make_code_item(3, 1, 2, words)
            dmethods.append((self_init_m, 0x10001, c_off))

        elif c.init_mode == "bind_only":
            init_off = make_code_item(1, 1, 1, [0x1070, super_init_m, 0x0000, 0x000E])
            dmethods.append((self_init_m, 0x10001, init_off))
            on_bind_m = method_idx[(c.descriptor, ("V", ()), "onBind")]
            bind_s = str_idx[WWA.ACTION_WIDGET]
            b_off = make_code_item(2, 1, 0, [0x001A, bind_s, 0x000E])
            vmethods.append((on_bind_m, 0x0001, b_off))

        elif c.init_mode == "reader":
            init_off = make_code_item(1, 1, 1, [0x1070, super_init_m, 0x0000, 0x000E])
            dmethods.append((self_init_m, 0x10001, init_off))
            disc_m = method_idx[(c.descriptor, ("V", ()), "discover")]
            bind_s = str_idx[WWA.ACTION_WIDGET]
            qis_m = method_idx[
                (
                    "Landroid/content/pm/PackageManager;",
                    ("V", ()),
                    "queryIntentServices",
                )
            ]
            r_off = make_code_item(
                2,
                1,
                1,
                [
                    0x001A,
                    bind_s,  # const-string v0, BIND_WIDGET_PROVIDER
                    0x106E,
                    qis_m,
                    0x0000,  # invoke-virtual {v0}, queryIntentServices
                    0x000E,  # return-void
                ],
            )
            vmethods.append((disc_m, 0x0001, r_off))

        else:  # "di_empty"
            init_off = make_code_item(1, 1, 1, [0x1070, super_init_m, 0x0000, 0x000E])
            dmethods.append((self_init_m, 0x10001, init_off))
            oc_m = method_idx[(c.descriptor, ("V", ()), "onCreate")]
            oc_off = make_code_item(1, 1, 0, [0x000E])
            vmethods.append((oc_m, 0x0001, oc_off))

        ifields.sort(key=lambda x: x[0])
        dmethods.sort(key=lambda x: x[0])
        vmethods.sort(key=lambda x: x[0])

        cdata_off = len(buf)
        buf.extend(_uleb128(0))
        buf.extend(_uleb128(len(ifields)))
        buf.extend(_uleb128(len(dmethods)))
        buf.extend(_uleb128(len(vmethods)))

        prev_f = 0
        for f_i, flg in ifields:
            buf.extend(_uleb128(f_i - prev_f))
            buf.extend(_uleb128(flg))
            prev_f = f_i

        prev_m = 0
        for m_i, flg, coff in dmethods:
            buf.extend(_uleb128(m_i - prev_m))
            buf.extend(_uleb128(flg))
            buf.extend(_uleb128(coff))
            prev_m = m_i

        prev_m = 0
        for m_i, flg, coff in vmethods:
            buf.extend(_uleb128(m_i - prev_m))
            buf.extend(_uleb128(flg))
            buf.extend(_uleb128(coff))
            prev_m = m_i

        struct.pack_into(
            "<8I",
            buf,
            class_defs_off + c_i * 32,
            type_idx[c.descriptor],
            0x0001,
            type_idx[c.superclass],
            0,
            0xFFFFFFFF,
            anno_dir_off,
            cdata_off,
            0,
        )

    align4()
    file_size = len(buf)
    data_size = file_size - data_off

    # Fill DEX header
    buf[0:8] = b"dex\n035\x00"
    struct.pack_into("<I", buf, 32, file_size)
    struct.pack_into("<I", buf, 36, 112)
    struct.pack_into("<I", buf, 40, 0x12345678)
    struct.pack_into(
        "<14I",
        buf,
        56,
        len(sorted_strings),
        string_ids_off,
        len(sorted_types),
        type_ids_off,
        len(sorted_protos),
        proto_ids_off,
        len(sorted_fields),
        field_ids_off,
        len(sorted_methods),
        method_ids_off,
        len(all_classes),
        class_defs_off,
        data_size,
        data_off,
    )
    adler = zlib.adler32(bytes(buf[12:])) & 0xFFFFFFFF
    struct.pack_into("<I", buf, 8, adler)
    return bytes(buf)


def build_manifest_xml(
    *,
    package: str = "com.example.watch",
    version_name: str = "1.4.0",
    version_code: int = 10400,
    min_sdk: int = 30,
    target_sdk: int = 35,
    compile_sdk: int = 36,
    standalone: str | None = "true",
    widget_services: list[dict[str, Any]] | None = None,
    tile_services: list[dict[str, Any]] | None = None,
    activities: list[dict[str, Any]] | None = None,
) -> str:
    standalone_xml = (
        f'<meta-data android:name="com.google.android.wearable.standalone" android:value="{standalone}"/>'
        if standalone is not None
        else ""
    )
    svc_blocks: list[str] = []
    for ws in widget_services or []:
        name = ws["name"]
        exported = ws.get("exported", "true")
        perm = ws.get("permission", WWA.PERM_BIND_TILE)
        perm_attr = f'android:permission="{perm}"' if perm else ""
        prov = ws.get("provider", "@xml/widget_info")
        extra_tile_prev = ws.get("tile_preview")
        extra_meta = (
            f'<meta-data android:name="androidx.wear.tiles.PREVIEW" android:resource="{extra_tile_prev}"/>'
            if extra_tile_prev
            else ""
        )
        multi = ws.get("multi_instance")
        multi_meta = (
            f'<meta-data android:name="com.google.android.clockwork.tiles.MULTI_INSTANCES_SUPPORTED" android:value="{multi}"/>'
            if multi
            else ""
        )
        svc_blocks.append(
            f"""
            <service android:name="{name}" android:exported="{exported}" {perm_attr} android:label="Example Widget">
                <intent-filter>
                    <action android:name="androidx.glance.wear.action.BIND_WIDGET_PROVIDER"/>
                </intent-filter>
                <meta-data android:name="androidx.glance.wear.widget.provider" android:resource="{prov}"/>
                {extra_meta}
                {multi_meta}
            </service>
            """
        )

    for ts in tile_services or []:
        name = ts["name"]
        exported = ts.get("exported", "true")
        perm = ts.get("permission", WWA.PERM_BIND_TILE)
        prev = ts.get("preview", "@drawable/tile_preview")
        svc_blocks.append(
            f"""
            <service android:name="{name}" android:exported="{exported}" android:permission="{perm}" android:label="Example Tile">
                <intent-filter>
                    <action android:name="androidx.wear.tiles.action.BIND_TILE_PROVIDER"/>
                </intent-filter>
                <meta-data android:name="androidx.wear.tiles.PREVIEW" android:resource="{prev}"/>
            </service>
            """
        )

    act_blocks: list[str] = []
    for act in activities or []:
        aname = act["name"]
        action = act["action"]
        cats = "".join(
            f'<category android:name="{c}"/>' for c in act.get("categories", [])
        )
        act_blocks.append(
            f"""
            <activity android:name="{aname}" android:exported="true">
                <intent-filter>
                    <action android:name="{action}"/>
                    <category android:name="android.intent.category.DEFAULT"/>
                    {cats}
                </intent-filter>
            </activity>
            """
        )

    return f"""<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="{package}"
    android:versionCode="{version_code}"
    android:versionName="{version_name}"
    android:compileSdkVersion="{compile_sdk}">
    <uses-sdk android:minSdkVersion="{min_sdk}" android:targetSdkVersion="{target_sdk}"/>
    <application android:label="Example Watch">
        {standalone_xml}
        {"".join(svc_blocks)}
        {"".join(act_blocks)}
    </application>
</manifest>
"""


def build_provider_xml(
    *,
    group: str | None = "com.example.watch.ExampleTileService",
    preferred_type: str = "LARGE",
    config_action: str | None = None,
    containers: list[tuple[str, str]] | None = None,
) -> str:
    if containers is None:
        containers = [
            ("SMALL", "@drawable/widget_preview_small"),
            ("LARGE", "@drawable/widget_preview_large"),
        ]
    grp_attr = f'group="{group}"' if group is not None else ""
    cfg_attr = f'configIntentAction="{config_action}"' if config_action else ""
    c_xml = "\n".join(
        f'    <container android:type="{ctype}" android:previewImage="{pref}"/>'
        for ctype, pref in containers
    )
    return f"""<?xml version="1.0" encoding="utf-8"?>
<wearwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:label="Example Widget"
    android:description="Displays workout progress"
    {grp_attr}
    preferredType="{preferred_type}"
    {cfg_attr}>
{c_xml}
</wearwidget-provider>
"""


class WearWidgetAuditTests(unittest.TestCase):
    """Comprehensive hermetic tests for wear-widget-audit."""

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory(prefix="wwa_unit_test_")
        self.work_dir = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def _write_apk(self, apk_path: Path, entries: dict[str, bytes | str]) -> Path:
        apk_path.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(apk_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            for name, content in entries.items():
                data = content.encode("utf-8") if isinstance(content, str) else content
                zf.writestr(name, data)
        return apk_path

    # -------------------------------------------------------------------------
    # 1. All 5 Obfuscation-Proof C06 States (Binary DEX + dexdump fallback)
    # -------------------------------------------------------------------------

    def test_c06_state1_pass_annotated_and_unmerged_obfuscated(self) -> None:
        dex = build_synthetic_dex(
            [
                SyntheticClassSpec(
                    descriptor="Lcom/example/watch/AlphaWidgetService;",
                    runtime_annotations=[
                        ("Lkotlin/Metadata;", None),
                        ("Lgvl;", "Lwrh;"),  # Obfuscated @AssociateWithGlanceWearWidget
                    ],
                    init_mode="di_empty",
                ),
                SyntheticClassSpec(
                    descriptor="Lcom/example/watch/BetaWidgetService;",
                    runtime_annotations=[
                        ("Lgvl;", "Lxyz;"),
                    ],
                    init_mode="di_empty",
                ),
            ],
            include_live_reader=True,
            include_mutf8_null_string=True,
            include_design_tokens=True,
        )
        apk = self._write_apk(
            self.work_dir / "annotated.apk",
            {
                "AndroidManifest.xml": build_manifest_xml(
                    widget_services=[
                        {"name": ".AlphaWidgetService", "provider": "@xml/alpha_info"},
                        {"name": ".BetaWidgetService", "provider": "@xml/beta_info"},
                    ],
                    tile_services=[{"name": ".ExampleTileService"}],
                ),
                "res/xml/alpha_info.xml": build_provider_xml(
                    containers=[
                        ("SMALL", "@drawable/alpha_small"),
                        ("LARGE", "@drawable/alpha_large"),
                    ]
                ),
                "res/xml/beta_info.xml": build_provider_xml(
                    containers=[
                        ("SMALL", "@drawable/beta_small"),
                        ("LARGE", "@drawable/beta_large"),
                    ]
                ),
                "res/drawable-nodpi/alpha_small.png": build_rgba_png(
                    448, 168, seed_byte=1
                ),
                "res/drawable-nodpi/alpha_large.png": build_rgba_png(
                    464, 288, seed_byte=2
                ),
                "res/drawable-nodpi/beta_small.png": build_rgba_png(
                    448, 168, seed_byte=3
                ),
                "res/drawable-nodpi/beta_large.png": build_rgba_png(
                    464, 288, seed_byte=4
                ),
                "res/drawable-nodpi/tile_preview.png": build_rgba_png(
                    400, 400, seed_byte=5
                ),
                "META-INF/androidx.glance.wear_wear.version": "1.0.0-alpha18\n",
                "META-INF/androidx.compose.remote_remote-creation-compose.version": "1.0.0-alpha19\n",
                "META-INF/androidx.wear.tiles_tiles.version": "1.6.2\n",
                "lib/arm64-v8a/libnative.so": b"\x7fELF",
                "classes.dex": dex,
            },
        )
        report = WWA.audit_target(str(apk))
        assert report["checks"]["C06"].startswith("PASS:")
        assert report["c06_analysis"]["state"] == "pass_annotated_unmerged"
        assert report["c06_analysis"]["annotated_mappings"] == {
            "AlphaWidgetService": "Lwrh;",
            "BetaWidgetService": "Lxyz;",
        }
        for cid in (
            "C01",
            "C02",
            "C03",
            "C04",
            "C05",
            "C08",
            "C09",
            "C10",
            "C11",
            "C12",
            "C13",
            "C14",
            "C15",
        ):
            assert report["checks"][cid].startswith("PASS:"), (
                f"Expected {cid} PASS, got {report['checks'][cid]}"
            )
        for cid in ("C16", "C17", "C18", "C19"):
            assert report["checks"][cid] == WWA.RUNTIME_GAP_DEFAULT

    def test_c06_state2_pass_r8_shaken_out_without_live_reader(self) -> None:
        # Even if BIND_WIDGET_PROVIDER literal appears in Service.onBind without
        # queryIntentServices/getAnnotation, live_recovery_reader must stay False!
        dex = build_synthetic_dex(
            [
                SyntheticClassSpec(
                    descriptor="Lcom/example/watch/QuickNoteWidgetService;",
                    runtime_annotations=[("Lkotlin/Metadata;", None)],
                    build_annotations=[
                        ("La/b;", "Lcom/example/watch/QuickNoteWidget;")
                    ],
                    init_mode="bind_only",
                )
            ],
            include_live_reader=False,
        )
        apk = self._write_apk(
            self.work_dir / "shaken.apk",
            {
                "AndroidManifest.xml": build_manifest_xml(
                    widget_services=[{"name": ".QuickNoteWidgetService"}],
                ),
                "res/xml/widget_info.xml": build_provider_xml(),
                "res/drawable-nodpi/widget_preview_small.png": build_rgba_png(
                    448, 168, seed_byte=1
                ),
                "res/drawable-nodpi/widget_preview_large.png": build_rgba_png(
                    464, 288, seed_byte=2
                ),
                "classes.dex": dex,
            },
        )
        report = WWA.audit_target(str(apk))
        assert report["checks"]["C06"].startswith("PASS:")
        assert report["c06_analysis"]["state"] == "pass_r8_shaken_out"
        assert not report["c06_analysis"]["live_recovery_reader"]

    def test_c06_state3_fail_r8_horizontal_class_merging(self) -> None:
        dex = build_synthetic_dex(
            [
                SyntheticClassSpec(
                    descriptor="Lcom/example/compass/AltitudeWidgetService;",
                    runtime_annotations=[("Lj1;", "Lo9;")],
                    init_mode="di_empty",
                ),
                SyntheticClassSpec(
                    descriptor="Lcom/example/compass/BearingWidgetService;",
                    runtime_annotations=[("Lj1;", "Lo9;")],
                    init_mode="di_empty",
                ),
            ],
            include_live_reader=False,
        )
        apk = self._write_apk(
            self.work_dir / "merged.apk",
            {
                "AndroidManifest.xml": build_manifest_xml(
                    package="com.example.compass",
                    widget_services=[
                        {"name": ".AltitudeWidgetService"},
                        {"name": ".BearingWidgetService"},
                    ],
                ),
                "res/xml/widget_info.xml": build_provider_xml(),
                "res/drawable-nodpi/widget_preview_small.png": build_rgba_png(
                    448, 168, seed_byte=1
                ),
                "res/drawable-nodpi/widget_preview_large.png": build_rgba_png(
                    464, 288, seed_byte=2
                ),
                "classes.dex": dex,
            },
        )
        report = WWA.audit_target(str(apk))
        assert report["checks"]["C06"].startswith("FAIL:")
        assert report["c06_analysis"]["state"] == "fail_r8_class_merged"
        assert "Lo9;" in report["checks"]["C06"]
        assert report["c06_analysis"]["merged_collisions"] == {
            "Lo9;": ["AltitudeWidgetService", "BearingWidgetService"],
        }

    def test_c06_state4_fail_live_reader_missing_annotation_di_and_koin(self) -> None:
        for mode in ("di_empty", "koin_lazy", "r8_inlined_lazy"):
            with self.subTest(init_mode=mode):
                dex = build_synthetic_dex(
                    [
                        SyntheticClassSpec(
                            descriptor="Lcom/example/battery/BatteryWidgetService;",
                            runtime_annotations=[("Lkotlin/Metadata;", None)],
                            init_mode=mode,
                        )
                    ],
                    include_live_reader=True,
                )
                apk = self._write_apk(
                    self.work_dir / f"di_{mode}.apk",
                    {
                        "AndroidManifest.xml": build_manifest_xml(
                            package="com.example.battery",
                            widget_services=[{"name": ".BatteryWidgetService"}],
                        ),
                        "res/xml/widget_info.xml": build_provider_xml(),
                        "res/drawable-nodpi/widget_preview_small.png": build_rgba_png(
                            448, 168, seed_byte=1
                        ),
                        "res/drawable-nodpi/widget_preview_large.png": build_rgba_png(
                            464, 288, seed_byte=2
                        ),
                        "classes.dex": dex,
                    },
                )
                report = WWA.audit_target(str(apk))
                assert report["checks"]["C06"].startswith("FAIL:")
                assert report["c06_analysis"]["state"] == "fail_missing_annotation_di"
                assert (
                    "BatteryWidgetService"
                    in report["c06_analysis"]["di_uninitialized_services"]
                )

    def test_c06_state5_warn_live_reader_missing_annotation_direct_init_fallback(
        self,
    ) -> None:
        dex = build_synthetic_dex(
            [
                SyntheticClassSpec(
                    descriptor="Lcom/example/chat/RecentChatsWidgetService;",
                    init_mode="direct",
                    init_widget_desc="Lcom/example/chat/RecentChatsWidget;",
                ),
                SyntheticClassSpec(
                    descriptor="Lcom/example/chat/VoiceNoteWidgetService;",
                    init_mode="direct",
                    init_widget_desc="Lcom/example/chat/VoiceNoteWidget;",
                ),
            ],
            include_live_reader=True,
        )
        apk = self._write_apk(
            self.work_dir / "init_fallback.apk",
            {
                "AndroidManifest.xml": build_manifest_xml(
                    package="com.example.chat",
                    widget_services=[
                        {"name": ".RecentChatsWidgetService"},
                        {"name": ".VoiceNoteWidgetService"},
                    ],
                ),
                "res/xml/widget_info.xml": build_provider_xml(),
                "res/drawable-nodpi/widget_preview_small.png": build_rgba_png(
                    448, 168, seed_byte=1
                ),
                "res/drawable-nodpi/widget_preview_large.png": build_rgba_png(
                    464, 288, seed_byte=2
                ),
                "classes.dex": dex,
            },
        )
        report = WWA.audit_target(str(apk))
        assert report["checks"]["C06"].startswith("WARN:")
        assert report["c06_analysis"]["state"] == "warn_init_fallback"
        assert report["c06_analysis"]["init_fallback_mappings"] == {
            "RecentChatsWidgetService": "Lcom/example/chat/RecentChatsWidget;",
            "VoiceNoteWidgetService": "Lcom/example/chat/VoiceNoteWidget;",
        }

    def test_parse_dexdump_output_annotations_before_class_header(self) -> None:
        sample_dexdump = """\
Class #3 annotations:
Annotations on class
  VISIBILITY_RUNTIME Lkotlin/Metadata; k=1
  VISIBILITY_RUNTIME La/b; a=Lcom/example/watch/MergedWidget;

Class #3            -
  Class descriptor  : 'Lcom/example/watch/FirstService;'
  Access flags      : 0x0011 (PUBLIC FINAL)
  Superclass        : 'Landroidx/glance/wear/GlanceWearWidgetService;'
  Direct methods    -
    #0              : (in Lcom/example/watch/FirstService;)
      name          : '<init>'
      type          : '()V'
      registers     : 1
000100: 7010 0100 0000 |0000: invoke-direct {v0}, Landroidx/glance/wear/GlanceWearWidgetService;.<init>:()V

Class #4 annotations:
Annotations on class
  VISIBILITY_RUNTIME La/b; a=Lcom/example/watch/MergedWidget;

Class #4            -
  Class descriptor  : 'Lcom/example/watch/SecondService;'
  Superclass        : 'Landroidx/glance/wear/GlanceWearWidgetService;'

Class #5            -
  Class descriptor  : 'Landroidx/glance/wear/GlanceWearWidgetManager;'
000200: 1a00 1000 |0000: const-string v0, "androidx.glance.wear.action.BIND_WIDGET_PROVIDER"
000204: 6e20 2000 |0002: invoke-virtual {v0}, Landroid/content/pm/PackageManager;.queryIntentServices:(Landroid/content/Intent;I)Ljava/util/List;
"""
        summary = WWA.DexAuditSummary()
        svcs = {
            "Lcom/example/watch/FirstService;",
            "Lcom/example/watch/SecondService;",
        }
        WWA.parse_dexdump_output(sample_dexdump, svcs, summary)
        assert summary.live_recovery_reader
        svc_records = [
            WWA.ServiceRecord(
                name="com.example.watch.FirstService",
                descriptor="Lcom/example/watch/FirstService;",
                exported=True,
                enabled=True,
                permission=WWA.PERM_BIND_TILE,
                label_ref=None,
                label=None,
                actions=[WWA.ACTION_WIDGET],
                meta_data={},
            ),
            WWA.ServiceRecord(
                name="com.example.watch.SecondService",
                descriptor="Lcom/example/watch/SecondService;",
                exported=True,
                enabled=True,
                permission=WWA.PERM_BIND_TILE,
                label_ref=None,
                label=None,
                actions=[WWA.ACTION_WIDGET],
                meta_data={},
            ),
        ]
        c06_str, details = WWA.evaluate_c06(svc_records, summary)
        assert c06_str.startswith("FAIL:")
        assert details["state"] == "fail_r8_class_merged"

    # -------------------------------------------------------------------------
    # 2. Previews (C10-C15): Masked, Partial, Vector,mdpi, Ratios, Duplicate SHA
    # -------------------------------------------------------------------------

    def test_previews_masked_square_mdpi_duplicate_and_non400_tile(self) -> None:
        # 400x400 circularly masked PNG in baseline drawable/ (mdpi) shared across SMALL, LARGE, TILE
        masked_square = build_rgba_png(400, 400, circular_mask=True, seed_byte=9)
        tile_288 = build_rgba_png(288, 288, seed_byte=11)
        dex = build_synthetic_dex(
            [
                SyntheticClassSpec(
                    descriptor="Lcom/example/watch/MainWidgetService;",
                    runtime_annotations=[("La/b;", "Lcom/example/watch/MainWidget;")],
                )
            ]
        )
        apk = self._write_apk(
            self.work_dir / "bad_previews.apk",
            {
                "AndroidManifest.xml": build_manifest_xml(
                    widget_services=[
                        {
                            "name": ".MainWidgetService",
                            "tile_preview": "@drawable/shared_circle",
                        }
                    ],
                    tile_services=[
                        {"name": ".LegacyTileService", "preview": "@drawable/tile_288"}
                    ],
                ),
                "res/xml/widget_info.xml": build_provider_xml(
                    containers=[
                        ("SMALL", "@drawable/shared_circle"),
                        ("LARGE", "@drawable/shared_circle"),
                    ]
                ),
                "res/drawable/shared_circle.png": masked_square,
                "res/drawable-nodpi/tile_288.png": tile_288,
                "classes.dex": dex,
            },
        )
        report = WWA.audit_target(str(apk))
        assert report["checks"]["C05"].startswith("WARN:")  # redundant TILE PREVIEW
        assert report["checks"]["C10"].startswith("FAIL:")  # default/mdpi
        assert report["checks"]["C11"].startswith("WARN:")  # 288x288 != 400x400
        assert report["checks"]["C12"].startswith("FAIL:")  # 1.00:1 != ~2.67:1
        assert report["checks"]["C13"].startswith("FAIL:")  # 1.00:1 != ~1.61:1
        assert report["checks"]["C14"].startswith("FAIL:")  # duplicate SHA-256
        assert report["checks"]["C15"].startswith("FAIL:")  # 4/4 transparent corners

    def test_previews_vector_xml_and_partial_corner_warn(self) -> None:
        dex = build_synthetic_dex(
            [
                SyntheticClassSpec(
                    descriptor="Lcom/example/watch/VecWidgetService;",
                    runtime_annotations=[("La/b;", "Lcom/example/watch/VecWidget;")],
                )
            ]
        )
        # Vector XML -> C10, C12, C13, C15 FAIL
        vec_apk = self._write_apk(
            self.work_dir / "vector_preview.apk",
            {
                "AndroidManifest.xml": build_manifest_xml(
                    widget_services=[{"name": ".VecWidgetService"}],
                ),
                "res/xml/widget_info.xml": build_provider_xml(
                    containers=[
                        ("SMALL", "@drawable/ic_vec"),
                        ("LARGE", "@drawable/ic_vec"),
                    ]
                ),
                "res/drawable/ic_vec.xml": '<vector xmlns:android="http://schemas.android.com/apk/res/android"/>',
                "classes.dex": dex,
            },
        )
        rep_vec = WWA.audit_target(str(vec_apk))
        assert rep_vec["checks"]["C10"].startswith("FAIL:")
        assert rep_vec["checks"]["C12"].startswith("FAIL:")
        assert rep_vec["checks"]["C13"].startswith("FAIL:")
        assert rep_vec["checks"]["C15"].startswith("FAIL:")

        # 1 transparent corner (<5% overall) -> C15 WARN
        partial_small = build_rgba_png(
            448, 168, corner_alphas=(0, 255, 255, 255), seed_byte=21
        )
        opaque_large = build_rgba_png(464, 288, seed_byte=22)
        warn_apk = self._write_apk(
            self.work_dir / "partial_corner.apk",
            {
                "AndroidManifest.xml": build_manifest_xml(
                    widget_services=[{"name": ".VecWidgetService"}],
                ),
                "res/xml/widget_info.xml": build_provider_xml(),
                "res/drawable-nodpi/widget_preview_small.png": partial_small,
                "res/drawable-nodpi/widget_preview_large.png": opaque_large,
                "classes.dex": dex,
            },
        )
        rep_warn = WWA.audit_target(str(warn_apk))
        assert rep_warn["checks"]["C15"].startswith("WARN:")

        # Also verify pure-stdlib PNG decoder directly when Pillow is bypassed
        w, h, corners, trans_pct = WWA._decode_png_stdlib(partial_small)
        assert (w, h) == (448, 168)
        assert corners[0][3] == 0
        assert corners[1][3] == 255
        assert trans_pct < 1.0

    # -------------------------------------------------------------------------
    # 3. Split-APK Merging, Shortened Paths, Config Categories, & CLI / Temp Leak
    # -------------------------------------------------------------------------

    def test_split_apk_bundle_with_mock_aapt2_and_shortened_resources(self) -> None:
        split_dir = self.work_dir / "com.example.splitapp"
        split_dir.mkdir(parents=True)

        dex = build_synthetic_dex(
            [
                SyntheticClassSpec(
                    descriptor="Lcom/example/splitapp/StreakWidgetService;",
                    runtime_annotations=[
                        ("La/b;", "Lcom/example/splitapp/StreakWidget;")
                    ],
                )
            ],
            include_live_reader=True,
        )

        # base.apk carries binary-marker resources.arsc + shortened res/3X.xml
        self._write_apk(
            split_dir / "base.apk",
            {
                "resources.arsc": b"ARSC_MOCK",
                "AndroidManifest.xml": b"\x03\x00\x08\x00BINARY_XML",
                "res/3X.xml": b"\x03\x00\x08\x00BINARY_PROVIDER_XML",
                "META-INF/androidx.glance.wear_wear.version": "1.0.0-alpha12\n",
                "classes.dex": dex,
            },
        )
        # ABI split without resources.arsc (must NOT crash aapt2 dump resources!)
        self._write_apk(
            split_dir / "config.arm64_v8a.apk",
            {
                "AndroidManifest.xml": b"\x03\x00\x08\x00",
                "lib/arm64-v8a/libengine.so": b"\x7fELF",
            },
        )
        # Density/drawable split carrying shortened res/v1.png & res/v2.png with "(name removed)"
        self._write_apk(
            split_dir / "config.xxhdpi.apk",
            {
                "resources.arsc": b"ARSC_MOCK_SPLIT",
                "res/v1.png": build_rgba_png(448, 168, seed_byte=31),
                "res/v2.png": build_rgba_png(464, 288, seed_byte=32),
            },
        )
        # Locale split
        self._write_apk(
            split_dir / "config.es.apk",
            {
                "resources.arsc": b"ARSC_MOCK_ES",
            },
        )

        # Create hermetic mock aapt2 executable
        mock_aapt2 = self.work_dir / "mock-aapt2"
        mock_aapt2.write_text(
            """#!/usr/bin/env python3
import sys

args = sys.argv[1:]
if args[:2] == ["dump", "resources"]:
    apk = args[2]
    if apk.endswith("config.arm64_v8a.apk"):
        sys.stderr.write("Failed to retrieve resource table\\n")
        sys.exit(1)
    if apk.endswith("base.apk"):
        print('''Package name=com.example.splitapp id=7f
  type xml id=14 entryCount=1
    resource 0x7f140001 xml/(name removed)
      () (file) res/3X.xml type=XML
  type string id=10 entryCount=1
    resource 0x7f100001 string/app_name
      () "Split Watch"
      (fr-rFR) "Montre"
      (sw360dp) "Split Watch Large"''')
    elif apk.endswith("config.xxhdpi.apk"):
        print('''Package name=com.example.splitapp id=7f
  type drawable id=08 entryCount=2
    resource 0x7f080010 drawable/(name removed)
      (nodpi-v4) (file) res/v1.png type=PNG
    resource 0x7f080011 drawable/(name removed)
      (nodpi-v4) (file) res/v2.png type=PNG''')
    elif apk.endswith("config.es.apk"):
        print('''Package name=com.example.splitapp id=7f
  type string id=10 entryCount=1
    resource 0x7f100001 string/app_name
      (es) "Reloj"''')
    sys.exit(0)

if args[:2] == ["dump", "xmltree"]:
    target_file = args[args.index("--file") + 1] if "--file" in args else ""
    if target_file == "AndroidManifest.xml":
        print('''N: android=http://schemas.android.com/apk/res/android
  E: manifest (line=2)
    A: package="com.example.splitapp" (Raw: "com.example.splitapp")
    A: android:versionCode(0x0101021b)=(type 0x10)0x3e8
    A: android:versionName(0x0101021c)="2.5.0" (Raw: "2.5.0")
    A: android:compileSdkVersion(0x01010572)=(type 0x10)0x24
    E: uses-sdk (line=5)
      A: android:minSdkVersion(0x0101020c)=(type 0x10)0x1e
      A: android:targetSdkVersion(0x01010270)=(type 0x10)0x23
    E: application (line=8)
      E: meta-data (line=9)
        A: android:name(0x01010003)="com.google.android.wearable.standalone" (Raw: "com.google.android.wearable.standalone")
        A: android:value(0x01010024)=(type 0x12)0x0
      E: service (line=12)
        A: android:name(0x01010003)="com.example.splitapp.StreakWidgetService" (Raw: "com.example.splitapp.StreakWidgetService")
        A: android:permission(0x01010006)="com.google.android.wearable.permission.BIND_TILE_PROVIDER" (Raw: "com.google.android.wearable.permission.BIND_TILE_PROVIDER")
        A: android:exported(0x01010010)=(type 0x12)0xffffffff
        E: intent-filter (line=16)
          E: action (line=17)
            A: android:name(0x01010003)="androidx.glance.wear.action.BIND_WIDGET_PROVIDER" (Raw: "androidx.glance.wear.action.BIND_WIDGET_PROVIDER")
        E: meta-data (line=19)
          A: android:name(0x01010003)="androidx.glance.wear.widget.provider" (Raw: "androidx.glance.wear.widget.provider")
          A: android:resource(0x01010025)=@0x7f140001
      E: activity (line=25)
        A: android:name(0x01010003)="com.example.splitapp.ConfigActivity" (Raw: "com.example.splitapp.ConfigActivity")
        A: android:exported(0x01010010)=(type 0x12)0xffffffff
        E: intent-filter (line=28)
          E: action (line=29)
            A: android:name(0x01010003)="com.example.splitapp.CONFIGURE_STREAK" (Raw: "com.example.splitapp.CONFIGURE_STREAK")
          E: category (line=30)
            A: android:name(0x01010003)="androidx.wear.tiles.category.PROVIDER_CONFIG" (Raw: "androidx.wear.tiles.category.PROVIDER_CONFIG")''')
    elif target_file == "res/3X.xml":
        print('''N: android=http://schemas.android.com/apk/res/android
  E: wearwidget-provider (line=2)
    A: android:label(0x01010001)=@0x7f100001
    A: group="com.example.splitapp.StreakGroup" (Raw: "com.example.splitapp.StreakGroup")
    A: preferredType="SMALL" (Raw: "SMALL")
    A: configIntentAction="com.example.splitapp.CONFIGURE_STREAK" (Raw: "com.example.splitapp.CONFIGURE_STREAK")
    E: container (line=8)
      A: android:type(0x01010000)=(type 0x10)0x2
      A: android:previewImage(0x01010001)=@0x7f080010
    E: container (line=11)
      A: android:type(0x01010000)=(type 0x10)0x1
      A: android:previewImage(0x01010001)=@0x7f080011''')
    sys.exit(0)
sys.exit(1)
""",
            encoding="utf-8",
        )
        mock_aapt2.chmod(mock_aapt2.stat().st_mode | stat.S_IXUSR)

        old_env = os.environ.get("WEAR_WIDGET_AUDIT_AAPT2")
        os.environ["WEAR_WIDGET_AUDIT_AAPT2"] = str(mock_aapt2)
        try:
            report = WWA.audit_target(str(split_dir))
        finally:
            if old_env is None:
                os.environ.pop("WEAR_WIDGET_AUDIT_AAPT2", None)
            else:
                os.environ["WEAR_WIDGET_AUDIT_AAPT2"] = old_env

        assert report["header"]["packaging"] == "split_apk_bundle"
        assert report["header"]["version_code"] == 1000
        assert report["checks"]["C01"].startswith("PASS:")
        assert report["checks"]["C02"].startswith("PASS:")  # arm64-v8a from split!
        assert report["checks"]["C03"].startswith("WARN:")  # alpha12 < alpha14
        assert report["checks"]["C06"].startswith("PASS:")
        # Config activity missing com.google.android.clockwork.tiles.category.PROVIDER_CONFIG -> FAIL
        assert report["checks"]["C07"].startswith("FAIL:")
        assert report["checks"]["C09"].startswith("PASS:")  # 0x2=SMALL + 0x1=LARGE
        assert report["checks"]["C10"].startswith(
            "PASS:"
        )  # resolved from config.xxhdpi.apk!
        assert report["checks"]["C12"].startswith("PASS:")
        assert report["checks"]["C13"].startswith("PASS:")
        assert report["checks"]["C14"].startswith("PASS:")
        assert report["checks"]["C15"].startswith("PASS:")
        assert "2 string locale(s)" in report["attributes"]["D12"]  # es + fr-rFR

    def test_manifest_c01_c02_c04_c07_c09_edge_cases(self) -> None:
        dex = build_synthetic_dex(
            [
                SyntheticClassSpec(
                    descriptor="Lcom/example/watch/OnlySmallService;",
                    runtime_annotations=[
                        ("La/b;", "Lcom/example/watch/OnlySmallWidget;")
                    ],
                )
            ]
        )
        apk = self._write_apk(
            self.work_dir / "noncompliant.apk",
            {
                "AndroidManifest.xml": build_manifest_xml(
                    target_sdk=33,
                    widget_services=[
                        {
                            "name": ".OnlySmallService",
                            "exported": "false",
                            "permission": "",
                        }
                    ],
                    activities=[
                        {
                            "name": ".CfgActivity",
                            "action": "com.example.watch.CFG",
                            "categories": [
                                WWA.CAT_ANDROIDX_CONFIG,
                                WWA.CAT_CLOCKWORK_CONFIG,
                            ],
                        }
                    ],
                ),
                "res/xml/widget_info.xml": build_provider_xml(
                    group=None,
                    config_action="com.example.watch.CFG",
                    containers=[("SMALL", "@drawable/widget_preview_small")],
                ),
                "res/drawable-nodpi/widget_preview_small.png": build_rgba_png(448, 168),
                "lib/armeabi-v7a/liblegacy.so": b"\x7fELF",
                "classes.dex": dex,
            },
        )
        report = WWA.audit_target(str(apk))
        assert report["checks"]["C01"].startswith("FAIL:")  # targetSdk 33 < 34
        assert report["checks"]["C02"].startswith("FAIL:")  # 32-bit only
        assert report["checks"]["C04"].startswith(
            "FAIL:"
        )  # exported=false & missing perm
        assert report["checks"]["C07"].startswith(
            "PASS:"
        )  # both config categories present
        assert report["checks"]["C08"].startswith("WARN:")  # group missing
        assert report["checks"]["C09"].startswith("FAIL:")  # missing LARGE container
        assert report["checks"]["C13"].startswith("N/A:")

    def test_manifest_only_zip_bundle_runtime_overrides_cli_and_zero_temp_leak(
        self,
    ) -> None:
        before_tmp = set(glob.glob("/tmp/wear_widget_audit_*"))

        # 1. Manifest-only directory
        mdir = self.work_dir / "manifest_only_pkg"
        mdir.mkdir()
        (mdir / "AndroidManifest.xml").write_text(
            build_manifest_xml(
                package="com.example.manifestonly",
                widget_services=[{"name": ".WordWidgetService"}],
            ),
            encoding="utf-8",
        )

        # 2. Split .zip archive
        sdir = self.work_dir / "zip_src"
        sdir.mkdir()
        base_apk = self._write_apk(
            sdir / "base.apk",
            {
                "AndroidManifest.xml": build_manifest_xml(
                    package="com.example.zipped",
                    widget_services=[{"name": ".ZippedWidgetService"}],
                ),
                "res/xml/widget_info.xml": build_provider_xml(
                    containers=[("LARGE", "@drawable/widget_preview_large")]
                ),
                "classes.dex": build_synthetic_dex(
                    [
                        SyntheticClassSpec(
                            descriptor="Lcom/example/zipped/ZippedWidgetService;",
                            runtime_annotations=[
                                ("La/b;", "Lcom/example/zipped/ZippedWidget;")
                            ],
                        )
                    ]
                ),
            },
        )
        dpi_apk = self._write_apk(
            sdir / "config.nodpi.apk",
            {
                "res/drawable-nodpi/widget_preview_large.png": build_rgba_png(464, 288),
            },
        )
        bundle_zip = self.work_dir / "bundle.apks"
        with zipfile.ZipFile(bundle_zip, "w") as zf:
            zf.write(base_apk, "base.apk")
            zf.write(dpi_apk, "config.nodpi.apk")

        rt_json = self.work_dir / "runtime.json"
        rt_json.write_text(
            json.dumps(
                {
                    "com.example.zipped": {
                        "C16": "PASS: Zero clipped text across 12 specs",
                        "D13": "18.4 KB RemoteCompose wire payload",
                    }
                }
            ),
            encoding="utf-8",
        )
        out_json = self.work_dir / "out.json"

        # Invoke CLI via main()
        help_buf = io.StringIO()
        with contextlib.redirect_stdout(help_buf):
            rc_help = WWA.main(["--help"])
        assert rc_help == 0
        assert "Usage:" in help_buf.getvalue()

        rc = WWA.main(
            [
                "--compact",
                "--runtime-json",
                str(rt_json),
                "-o",
                str(out_json),
                str(mdir),
                str(bundle_zip),
            ]
        )
        assert rc == 0
        parsed = json.loads(out_json.read_text(encoding="utf-8"))
        assert len(parsed) == 2
        assert parsed[0]["header"]["packaging"] == "manifest_only"
        assert parsed[0]["checks"]["C06"].startswith("[GAP]")
        assert parsed[1]["header"]["packaging"] == "split_apk_archive"
        assert parsed[1]["checks"]["C09"].startswith("WARN:")  # LARGE only
        assert parsed[1]["checks"]["C16"] == "PASS: Zero clipped text across 12 specs"
        assert parsed[1]["attributes"]["D13"] == "18.4 KB RemoteCompose wire payload"

        # Summary mode + error path must also leak zero /tmp/wear_widget_audit_* dirs
        out_sum = self.work_dir / "summary.txt"
        assert WWA.main(["--summary", "-o", str(out_sum), str(bundle_zip)]) == 0
        assert "com.example.zipped" in out_sum.read_text(encoding="utf-8")

        rc_missing = subprocess.run(
            [
                sys.executable,
                str(SCRIPT_PATH),
                str(self.work_dir / "does-not-exist.apk"),
            ],
            capture_output=True,
            text=True,
            check=False,
        ).returncode
        assert rc_missing == 1

        after_tmp = set(glob.glob("/tmp/wear_widget_audit_*"))
        assert after_tmp - before_tmp == set()


if __name__ == "__main__":
    unittest.main()
