# Bytecode Analysis

How to answer questions about what an APK's compiled code actually does, with
evidence. Covers when to read smali, when to read decompiled Java, and how to
cross-check a finding against upstream library sources.

## Contents

- [Choosing a View of the Bytecode](#choosing-a-view-of-the-bytecode)
- [Workflow](#workflow)
- [Smali Basics](#smali-basics)
- [Limits of Static Analysis](#limits-of-static-analysis)
- [Evidence Rules](#evidence-rules)
- [Cross-Checking Against Upstream Sources](#cross-checking-against-upstream-sources)

## Choosing a View of the Bytecode

| Tool                                                         | Use it for                                                                       | Caveats                                                                                                                           |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| smali ([baksmali](https://github.com/google/smali), apktool) | Evidence and deterministic checks: overrides, call sites, annotations, constants | Verbose; register-based, so data flow takes reading                                                                               |
| [jadx](https://github.com/skylot/jadx)                       | Understanding logic and intent quickly                                           | Lossy: decompilation can fail, reorder, or invent code; never cite it as the only evidence, and confirm every claim against smali |
| `dexdump` (Android SDK build-tools)                          | Fallback when neither baksmali nor apktool is available                          | Hides annotations unless `-a` is passed; one large text stream rather than one file per class                                     |

Smali is the default for anything you will report as a finding because it is a
lossless rendering of the DEX file:

- One file per class, and the file path is the class descriptor
  (`Lcom/example/Foo;` lives at `com/example/Foo.smali`), so a class can be
  located without searching.
- Annotations (with their values), constants, and complete method descriptors on
  every `invoke-*` instruction are written inline, so a single `grep` or
  `apk-smali find` answers most "does the app do X" questions.

## Workflow

1. **Disassemble once, query many times.** `apk-smali disassemble app.apk`
   merges every DEX file of every split into one tree and prints its path. A
   pre-disassembled smali archive (any ZIP or directory of baksmali output) can
   be queried directly; `find` and `show` read ZIP archives in place.
1. **Anchor on manifest-declared names.** Classes named in `AndroidManifest.xml`
   (activities, services, receivers, providers, the application class) cannot be
   renamed by R8, so start from them: `apk-info manifest app.apk` gives the
   name, and `apk-smali show annotations TREE com.example.MyService` or
   `apk-smali show class TREE com.example.MyService` gives the bytecode.
1. **Search structurally, not textually.** Prefer `apk-smali find` predicates
   (`--declares`, `--calls`, `--extends`, `--implements`, `--annotated-with`) to
   grepping for names, which R8 may have renamed. Library class names that are
   part of a public API are usually kept; app-internal names usually are not.
1. **Read the code path.**
   `apk-smali show method TREE CLASS 'name(desc)' --depth 2` prints a method
   together with the same-class helpers it calls.
1. **Use jadx for orientation only**, then return to smali to confirm.

## Smali Basics

### Type Descriptors

| Descriptor                  | Java type                                            |
| --------------------------- | ---------------------------------------------------- |
| `V`                         | `void`                                               |
| `Z` `B` `S` `C`             | `boolean` `byte` `short` `char`                      |
| `I` `J` `F` `D`             | `int` `long` `float` `double`                        |
| `Lcom/example/Foo;`         | `com.example.Foo`                                    |
| `Lcom/example/Foo$Bar;`     | nested class `Foo.Bar` (or a lambda/anonymous class) |
| `[I`, `[Ljava/lang/String;` | `int[]`, `String[]`                                  |

A method reference is `CLASS->name(PARAMS)RETURN`, for example
`Landroid/app/Service;->onTrimMemory(I)V` is `void onTrimMemory(int)` on
`android.app.Service`. A field reference is `CLASS->name:TYPE`.

### Class Structure

- `.class` declares the class and its access flags (`interface`, `abstract`,
  `annotation`, `enum`, `synthetic`).
- `.super` is the direct superclass; `.implements` lines list the directly
  implemented interfaces. Neither includes inherited types, so walk up the
  hierarchy with repeated `show class` calls when needed.
- `.method` blocks hold one method each, ending with `.end method`. A method
  with the same name and descriptor as one in a superclass is an override.

### Invoke Instructions

| Instruction        | Meaning                                                                                                                                                                 |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `invoke-virtual`   | Normal virtual call; the receiver's runtime type decides which override runs.                                                                                           |
| `invoke-interface` | Virtual call through an interface type.                                                                                                                                 |
| `invoke-direct`    | Non-virtual call: constructors (`<init>`) and private methods.                                                                                                          |
| `invoke-static`    | Static method call; no receiver.                                                                                                                                        |
| `invoke-super`     | Calls the superclass implementation; the class in the reference is the superclass, so `invoke-super {p0}, Landroid/app/Service;->onCreate()V` means `super.onCreate()`. |

`/range` variants (`invoke-virtual/range {v0 .. v5}`) are the same calls with
more registers. In instance methods `p0` is `this`.

### Constants

`const/4`, `const/16`, `const`, and `const-wide` load literal values; the value
is written in hex. `const/high16 v0, 0x7f010000` loads only the top 16 bits (the
low 16 bits are zero), which is common for resource IDs and flag masks. When a
call takes a flags argument, find the `const*` that last wrote the argument
register before the `invoke-*` and decode the bits against the platform
constants (for example `0x3c` is 60, `TRIM_MEMORY_MODERATE`).

### Annotations

- `.annotation runtime` is visible to reflection at run time (Java
  `RetentionPolicy.RUNTIME`). These are the ones libraries look up.
- `.annotation system` is compiler bookkeeping (`Ldalvik/annotation/Signature;`,
  `InnerClass`, `EnclosingMethod`, `MemberClasses`, `Throws`,
  `SourceDebugExtension`).
- `.annotation build` is retained in the DEX file but not visible at run time.
- `Lkotlin/Metadata;` is emitted for every Kotlin class.

Class literals in annotation values appear as descriptors, for example
`value = Lcom/example/MyWidget;`. `apk-smali show annotations` hides
`Lkotlin/Metadata;` and `Ldalvik/annotation/*` unless `--all` is given.

## Limits of Static Analysis

- **Native code.** Logic in `lib/*/*.so` (JNI) is invisible to smali; a `native`
  method has no body.
- **Code loaded at run time.** Dynamically loaded DEX files, downloaded code,
  and reflection by string name (`Class.forName`, `getMethod`) do not show up as
  `invoke-*` targets.
- **R8 optimization.** Inlining removes small methods (a call you expect may be
  folded into its caller); class merging can collapse several classes into one
  descriptor; renaming gives unrelated classes short names like `La/b;`, so name
  matches on obfuscated names are coincidences, not evidence. Absence of a call
  is only meaningful once you have accounted for inlining.
- **Incomplete inputs.** A single APK from an App Bundle install may be only the
  base split; feature splits carry their own DEX files. Multi-dex apps spread
  classes across `classes.dex`, `classes2.dex`, and so on. Disassemble every
  split and every DEX file (`apk-smali disassemble` does this) before concluding
  that something is missing.

## Evidence Rules

- Quote the smali lines that support a finding, together with the file path
  within the tree (`com/example/MyService.smali`) and the method they belong to.
  Keep quotes short: the `.method` line plus the relevant instructions.
- State negative findings precisely ("no `invoke-*` of `...->triggerUpdate` in
  any class") and say which tree was searched (APK, version, splits included).
- When a finding depends on library behavior, link the library source at the
  release tag that matches the version bundled in the APK (`apk-info libraries`
  lists them), not a moving branch.
- Treat jadx output as a hint and say so if it is quoted.

## Cross-Checking Against Upstream Sources

To decide whether a behavior comes from the app or from a library it bundles,
and whether it has since been fixed upstream:

1. Find the bundled library version: `apk-info libraries app.apk`.
1. Download the matching artifact from
   [Maven Central](https://central.sonatype.com/) or
   [Google Maven](https://maven.google.com/web/index.html): the `.aar` or `.jar`
   and, where published, the `-sources.jar`. For AndroidX libraries the
   `jetpack` skill can resolve versions and download sources.
1. Disassemble the library's compiled classes for a like-for-like comparison:
   unzip `classes.jar` from the `.aar` and run `javap -c -p` on the class of
   interest (or convert it to DEX and disassemble with baksmali).
1. Compare against the bundled smali for the same class. R8 may have renamed or
   inlined it, so match on structure (method descriptors, constants, call
   sequence) rather than names.
1. Repeat with the newest release. If the newest release differs in the relevant
   code, the issue is "fixed upstream" and the remedy is a dependency update; if
   it does not, the issue is "still live".
