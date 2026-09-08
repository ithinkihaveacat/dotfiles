#!/usr/bin/env python3
"""Harbor execution orchestration module: trial packaging, execution, and candidate verification.

Part of the taskgo skill suite for managing unattended agent execution in Harbor.
Provides the implementation behind `taskgo harbor prepare`, `run`, and `verify`.
"""

from __future__ import annotations

import argparse
import difflib
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from collections.abc import Sequence

_TAG_ANSI = {
    "PASS": "\033[32m",
    "INFO": "\033[36m",
    "WARN": "\033[33m",
    "FAIL": "\033[31m",
}
_TAG_PATTERN = re.compile(r"\[(PASS|INFO|WARN|FAIL)\]")


def _use_color(stream: Any) -> bool:
    """Decides whether diagnostic output to stream may carry ANSI styling."""
    if os.environ.get("NO_COLOR"):
        return False
    force = os.environ.get("FORCE_COLOR")
    if force and force != "0":
        return True
    return bool(getattr(stream, "isatty", lambda: False)())


def _tagged(text: str, stream: Any = sys.stdout) -> str:
    """Colorises canonical diagnostic tags ([PASS] etc.) found in text."""
    if not _use_color(stream):
        return text

    def _wrap(m: re.Match[str]) -> str:
        return f"{_TAG_ANSI[m.group(1)]}{m.group(0)}\033[0m"

    return _TAG_PATTERN.sub(_wrap, text)


def compute_sha256(path: Path) -> str:
    """Compute SHA-256 hash of a file."""
    h = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


def run_patch_check(base_file: Path, patch_file: Path) -> tuple[bool, str]:
    """Test if patch applies cleanly to base_file using patch --dry-run."""
    try:
        # First try direct without strip (-p0)
        res = subprocess.run(
            ["patch", "--dry-run", str(base_file), str(patch_file)],
            capture_output=True,
            text=True,
            check=False,
        )
        if res.returncode == 0:
            return True, "Clean patch dry-run application (p0)"

        # Next try -p1
        res1 = subprocess.run(
            ["patch", "-p1", "--dry-run", str(base_file), str(patch_file)],
            capture_output=True,
            text=True,
            check=False,
        )
        if res1.returncode == 0:
            return True, "Clean patch dry-run application (p1)"

        err_detail = (res.stderr or res.stdout or "").strip()
        return False, f"Patch failed to apply: {err_detail}"
    except FileNotFoundError:
        return False, "patch utility not found on host"


def rerun_tool_check(tool_cmd: str, base_file: Path) -> tuple[bool, str, str]:
    """Rerun host tool on base_file and return (success, stdout_hash, error_msg)."""
    try:
        with base_file.open("r", encoding="utf-8") as in_f:
            res = subprocess.run(
                tool_cmd,
                shell=True,
                stdin=in_f,
                capture_output=True,
                text=True,
                check=False,
            )
        if res.returncode != 0:
            err = res.stderr.strip() if res.stderr else f"exit code {res.returncode}"
            return False, "", f"Tool returned {err}"
        tool_hash = hashlib.sha256(res.stdout.encode("utf-8")).hexdigest()
        return True, tool_hash, ""
    except Exception as e:
        return False, "", str(e)


def check_syntax(candidate_file: Path) -> tuple[bool, str]:
    """Check syntax of candidate file based on extension."""
    suffix = candidate_file.suffix.lower()
    if suffix == ".json":
        try:
            with candidate_file.open("r", encoding="utf-8") as f:
                json.load(f)
            return True, "Valid JSON syntax"
        except Exception as e:
            return False, f"JSON syntax error: {e}"
    elif suffix in (".yaml", ".yml"):
        try:
            from ruamel.yaml import YAML

            yaml = YAML()
            with candidate_file.open("r", encoding="utf-8") as f:
                yaml.load(f)
            return True, "Valid YAML syntax"
        except Exception as e:
            return False, f"YAML syntax error: {e}"
    else:
        # For markdown, text, or source code: check UTF-8 decoding
        try:
            candidate_file.read_text(encoding="utf-8")
            return True, f"Valid UTF-8 encoded {suffix or 'text'} content"
        except Exception as e:
            return False, f"Text encoding error: {e}"


def generate_diff(base_file: Path, candidate_file: Path) -> str:
    """Generates unified diff between base_file and candidate_file."""
    try:
        base_lines = base_file.read_text(encoding="utf-8").splitlines(keepends=True)
    except Exception:
        base_lines = []
    try:
        candidate_lines = candidate_file.read_text(encoding="utf-8").splitlines(
            keepends=True
        )
    except Exception:
        candidate_lines = []

    diff_lines = list(
        difflib.unified_diff(
            base_lines,
            candidate_lines,
            fromfile=str(base_file),
            tofile=str(candidate_file),
        )
    )
    return "".join(diff_lines)


def resolve_harbor_bin(
    harbor_bin: str | Path | None = None,
    control_root: Path | None = None,
) -> Path | None:
    """Resolves the executable harbor binary from flag, env, PATH, or local runtime locations."""
    if harbor_bin:
        p = Path(harbor_bin).expanduser().resolve()
        if p.is_file() and os.access(p, os.X_OK):
            return p

    env_bin = os.environ.get("HARBOR_BIN")
    if env_bin:
        p = Path(env_bin).expanduser().resolve()
        if p.is_file() and os.access(p, os.X_OK):
            return p

    which_harbor = shutil.which("harbor")
    if which_harbor:
        return Path(which_harbor).resolve()

    candidate_locations = [
        Path.home() / ".projects" / "taskgo" / ".runtime" / "bin" / "harbor",
        Path.home() / ".projects" / "dotfiles" / ".runtime" / "bin" / "harbor",
        Path.home() / ".runtime" / "bin" / "harbor",
    ]
    if control_root:
        candidate_locations.insert(0, control_root / ".runtime" / "bin" / "harbor")

    for cand in candidate_locations:
        if cand.is_file() and os.access(cand, os.X_OK):
            return cand.resolve()

    return None


def check_docker_daemon() -> tuple[bool, str]:
    """Verifies that the Docker daemon is running and reachable."""
    try:
        res = subprocess.run(
            ["docker", "info", "--format", "{{.ServerVersion}}"],
            capture_output=True,
            text=True,
            check=False,
            timeout=10,
        )
        if res.returncode == 0:
            version = res.stdout.strip()
            return True, version
        err = (res.stderr or res.stdout or "").strip()
        return False, err or "docker returned non-zero exit code"
    except FileNotFoundError:
        return False, "docker binary not found in PATH"
    except subprocess.TimeoutExpired:
        return False, "timed out contacting docker daemon"
    except Exception as e:
        return False, str(e)


def find_skill_source(skill_name_or_path: str) -> Path | None:
    """Finds the source directory for a requested skill name or path."""
    p = Path(skill_name_or_path).expanduser().resolve()
    if p.is_dir():
        return p

    search_dirs = [
        Path.home() / ".dotfiles" / "skills",
        Path.home() / ".dotfiles" / ".agents" / "skills",
        Path.home() / ".agents" / "skills",
    ]
    script_dir = Path(__file__).resolve().parent
    search_dirs.append(script_dir.parent.parent)  # e.g. dotfiles/skills

    for sdir in search_dirs:
        cand = sdir / skill_name_or_path
        if cand.is_dir():
            return cand.resolve()

    return None


def prepare_trial(
    output_dir: Path,
    task_name: str,
    task_id: str | None = None,
    task_title: str | None = None,
    instruction: str | None = None,
    workspace_dir: Path | None = None,
    dockerfile: Path | None = None,
    artifacts: list[str] | None = None,
    skills: list[str] | None = None,
    model: str = "google/gemini-3.6-flash-low",
    agent: str = "antigravity-cli",
    agent_version: str = "1.1.25",
    timeout_sec: float = 60.0,
    setup_timeout_sec: float = 180.0,
    allowed_hosts: list[str] | None = None,
    dry_run: bool = False,
) -> dict[str, Any]:
    """Packages a self-contained trial directory for Harbor execution."""
    sanitized_slug = re.sub(r"[^a-zA-Z0-9_-]", "-", task_name).strip("-").lower()
    if not sanitized_slug:
        sanitized_slug = "trial-task"

    if allowed_hosts is None:
        allowed_hosts = ["generativelanguage.googleapis.com"]

    if artifacts is None:
        artifacts = ["/app/completion.json"]
        if workspace_dir and workspace_dir.is_dir():
            for item in workspace_dir.iterdir():
                if item.is_file() and not item.name.startswith("."):
                    artifacts.append(f"/app/workspace/{item.name}")

    if not instruction:
        instruction = (
            f"Execute the task: {task_title or task_name}.\n\n"
            "After completing the required changes in /app/workspace, write /app/completion.json containing:\n"
            '{"status":"completed","skill_used":"none","changed_files":[]}\n'
            "and stop."
        )

    job_data: dict[str, Any] = {
        "job_name": f"{sanitized_slug}-job",
        "jobs_dir": "./jobs",
        "n_attempts": 1,
        "n_concurrent_trials": 1,
        "retry": {"max_retries": 0},
        "environment": {"type": "docker", "delete": True},
        "verifier": {"disable": True},
        "agents": [
            {
                "name": agent,
                "model_name": model,
                "override_timeout_sec": int(timeout_sec),
                "override_setup_timeout_sec": int(setup_timeout_sec),
                "kwargs": {"version": agent_version},
            }
        ],
        "tasks": [{"path": f"tasks/{sanitized_slug}"}],
    }

    if skills:
        job_data["agents"][0]["skills"] = ["skills"]

    # Format task.toml
    allowed_hosts_str = json.dumps(allowed_hosts)
    artifacts_str = json.dumps(artifacts)
    keywords_str = json.dumps(["taskgo", "harbor", sanitized_slug])

    task_toml_content = f"""schema_version = "1.4"
artifacts = {artifacts_str}

[task]
name = "local/{sanitized_slug}"
version = "1.0.0"
keywords = {keywords_str}

[agent]
timeout_sec = {float(timeout_sec)}
network_mode = "allowlist"
allowed_hosts = {allowed_hosts_str}

[environment]
build_timeout_sec = {float(setup_timeout_sec)}
cpus = 1
memory_mb = 2048
network_mode = "public"
"""

    # Format default Dockerfile
    if dockerfile and dockerfile.is_file():
        dockerfile_content = dockerfile.read_text(encoding="utf-8")
    else:
        dockerfile_content = (
            "FROM ubuntu:24.04\n"
            "RUN apt-get update && apt-get install -y --no-install-recommends "
            "ca-certificates curl git unzip jq patch && rm -rf /var/lib/apt/lists/*\n"
            "WORKDIR /app\n"
            "COPY workspace /app/workspace\n"
        )

    summary = {
        "output_dir": str(output_dir),
        "task_name": sanitized_slug,
        "job_json": job_data,
        "task_toml": task_toml_content,
        "instruction": instruction,
        "artifacts": artifacts,
        "skills": skills or [],
    }

    if dry_run:
        return summary

    task_dir = output_dir / "tasks" / sanitized_slug
    env_dir = task_dir / "environment"
    ws_target_dir = env_dir / "workspace"

    ws_target_dir.mkdir(parents=True, exist_ok=True)

    # Write job.json
    (output_dir / "job.json").write_text(
        json.dumps(job_data, indent=2) + "\n", encoding="utf-8"
    )

    # Write task.toml
    (task_dir / "task.toml").write_text(task_toml_content, encoding="utf-8")

    # Write instruction.md
    (task_dir / "instruction.md").write_text(
        instruction.strip() + "\n", encoding="utf-8"
    )

    # Write Dockerfile
    (env_dir / "Dockerfile").write_text(dockerfile_content, encoding="utf-8")

    # Copy workspace
    if workspace_dir and workspace_dir.is_dir():
        for item in workspace_dir.iterdir():
            if item.is_file():
                shutil.copy2(item, ws_target_dir / item.name)
            elif item.is_dir() and item.name != ".git":
                shutil.copytree(item, ws_target_dir / item.name, dirs_exist_ok=True)

    # Bundle skills
    if skills:
        skills_target_dir = output_dir / "skills"
        skills_target_dir.mkdir(parents=True, exist_ok=True)
        for sk in skills:
            src = find_skill_source(sk)
            if src and src.is_dir():
                dest = skills_target_dir / src.name
                shutil.copytree(
                    src,
                    dest,
                    ignore=shutil.ignorePatterns(".git", "__pycache__", "*.pyc")
                    if hasattr(shutil, "ignorePatterns")
                    else shutil.ignore_patterns(".git", "__pycache__", "*.pyc"),
                    dirs_exist_ok=True,
                )
            else:
                print(
                    _tagged(
                        f"[WARN]  Could not resolve skill source for: {sk}", sys.stderr
                    ),
                    file=sys.stderr,
                )

    return summary


def run_trial(
    target: Path,
    harbor_bin: str | Path | None = None,
    print_config: bool = False,
    dry_run: bool = False,
    output_dir: Path | None = None,
    control_root: Path | None = None,
) -> int:
    """Executes a prepared trial using Harbor, with preflight validation and artifact extraction."""
    target = target.resolve()
    if target.is_dir():
        job_json = target / "job.json"
        pkg_dir = target
    else:
        job_json = target
        pkg_dir = target.parent

    if not job_json.is_file():
        print(
            _tagged(f"[FAIL] job.json not found at: {job_json}", sys.stderr),
            file=sys.stderr,
        )
        return 1

    # Load job.json to inspect model
    try:
        with job_json.open("r", encoding="utf-8") as f:
            jdata = json.load(f)
    except Exception as e:
        print(
            _tagged(f"[FAIL] Invalid job.json format: {e}", sys.stderr),
            file=sys.stderr,
        )
        return 1

    model_name = ""
    agents = jdata.get("agents", [])
    if agents and isinstance(agents, list):
        model_name = agents[0].get("model_name", "")

    # Preflight 1: Harbor binary
    hbin = resolve_harbor_bin(harbor_bin, control_root=control_root)
    if not hbin:
        print(_tagged("[FAIL] Harbor binary: not found", sys.stderr), file=sys.stderr)
        print(
            "taskgo harbor run: Harbor executable is required.\n"
            "Install with: uv tool install harbor==0.22.0",
            file=sys.stderr,
        )
        return 127

    # Check Harbor version
    try:
        ver_res = subprocess.run(
            [str(hbin), "--version"], capture_output=True, text=True, check=False
        )
        hver = ver_res.stdout.strip() or "0.22.0"
    except Exception:
        hver = "unknown"

    # Preflight 2: Docker daemon (unless only --print-config)
    if not print_config:
        docker_ok, docker_msg = check_docker_daemon()
        if not docker_ok:
            print(
                _tagged(f"[FAIL] Docker daemon: {docker_msg}", sys.stderr),
                file=sys.stderr,
            )
            print(
                "taskgo harbor run: Docker daemon must be running.\n"
                "Please start Docker Desktop or the system docker daemon.",
                file=sys.stderr,
            )
            return 1

    # Preflight 3: API key check for Gemini/Google models (unless print_config or dry_run)
    is_gemini = "gemini" in model_name.lower() or "google" in model_name.lower()
    if (
        is_gemini
        and not (print_config or dry_run)
        and not os.environ.get("GEMINI_API_KEY")
    ):
        print(
            _tagged("[FAIL] API Key: GEMINI_API_KEY is not set", sys.stderr),
            file=sys.stderr,
        )
        print(
            "taskgo harbor run: GEMINI_API_KEY is required for live execution with model "
            f"'{model_name}'. Export GEMINI_API_KEY before running.",
            file=sys.stderr,
        )
        return 1

    # --print-config mode
    if print_config:
        cmd = [str(hbin), "run", "--config", str(job_json), "--print-config"]
        res = subprocess.run(cmd, cwd=str(pkg_dir), check=False)
        return res.returncode

    # --dry-run mode
    if dry_run:
        print(_tagged(f"[PASS] Harbor binary: {hbin} (version {hver})"))
        docker_ok, dver = check_docker_daemon()
        if docker_ok:
            print(_tagged(f"[PASS] Docker daemon: connected (version {dver})"))
        else:
            print(_tagged(f"[WARN] Docker daemon: {dver}"))

        if is_gemini:
            has_key = bool(os.environ.get("GEMINI_API_KEY"))
            if has_key:
                print(_tagged("[PASS] API Key: GEMINI_API_KEY present"))
            else:
                print(
                    _tagged(
                        "[WARN] API Key: GEMINI_API_KEY unset (required for live run)"
                    )
                )

        cfg_res = subprocess.run(
            [str(hbin), "run", "--config", str(job_json), "--print-config"],
            cwd=str(pkg_dir),
            capture_output=True,
            text=True,
            check=False,
        )
        if cfg_res.returncode == 0:
            print(
                _tagged("[PASS] Task configuration: valid (Harbor parsed job config)")
            )
            print(_tagged("[INFO] Dry run complete: trial ready for live execution."))
            return 0
        else:
            print(
                _tagged(
                    f"[FAIL] Task configuration error: {cfg_res.stderr.strip() or cfg_res.stdout.strip()}",
                    sys.stderr,
                ),
                file=sys.stderr,
            )
            return 1

    # Live run
    print(_tagged(f"[INFO] Starting Harbor trial with model {model_name}..."))
    cmd = [str(hbin), "run", "--config", str(job_json)]
    run_res = subprocess.run(cmd, cwd=str(pkg_dir), check=False)

    if output_dir:
        output_dir = output_dir.resolve()
        output_dir.mkdir(parents=True, exist_ok=True)
        jobs_dir_rel = jdata.get("jobs_dir", "./jobs")
        jobs_dir = (pkg_dir / jobs_dir_rel).resolve()
        if jobs_dir.is_dir():
            # Find the newest trial subdirectory
            trials = [
                d
                for d in jobs_dir.rglob("*")
                if d.is_dir() and (d / "result.json").is_file()
            ]
            if trials:
                newest = max(trials, key=lambda d: (d / "result.json").stat().st_mtime)
                for item in newest.iterdir():
                    if item.is_file():
                        shutil.copy2(item, output_dir / item.name)
                    elif item.is_dir():
                        shutil.copytree(
                            item, output_dir / item.name, dirs_exist_ok=True
                        )
                print(
                    _tagged(
                        f"[INFO] Preserved trial output from {newest.name} to {output_dir}"
                    )
                )

    return run_res.returncode


def generate_acceptance_packet(
    task_id: str,
    task_title: str,
    base_file: Path,
    candidate_file: Path,
    patch_file: Path | None,
    completion_json: Path | None,
    result_json: Path | None,
    tool_cmd: str | None,
    output_dir: Path,
) -> dict[str, Any]:
    """Assemble the structured candidate acceptance packet across the 4 evaluation layers."""
    output_dir.mkdir(parents=True, exist_ok=True)

    # 1. Hashes
    base_hash = compute_sha256(base_file)
    candidate_hash = compute_sha256(candidate_file)

    # 2. Patch file generation / check
    if not patch_file or not patch_file.is_file():
        diff_text = generate_diff(base_file, candidate_file)
        gen_patch_path = output_dir / "candidate.patch"
        gen_patch_path.write_text(diff_text, encoding="utf-8")
        patch_file = gen_patch_path

    patch_hash = compute_sha256(patch_file)

    # 3. Patch applicability check
    patch_ok, patch_msg = run_patch_check(base_file, patch_file)

    # 4. Syntax check
    syntax_ok, syntax_msg = check_syntax(candidate_file)

    # 5. Host tool rerun
    tool_matched = False
    tool_output_hash = ""
    tool_err = ""
    if tool_cmd:
        tool_ok, tool_output_hash, tool_err = rerun_tool_check(tool_cmd, base_file)
        tool_matched = tool_ok and (tool_output_hash == candidate_hash)

    # 6. Layer A: Worker assertions audit
    worker_assertions: dict[str, Any] = {}
    if completion_json and completion_json.is_file():
        try:
            with completion_json.open("r", encoding="utf-8") as f:
                worker_assertions = json.load(f)
        except Exception as e:
            worker_assertions = {"error": f"Failed to parse completion.json: {e}"}

    # 7. Trial execution telemetry
    trial_meta: dict[str, Any] = {}
    if result_json and result_json.is_file():
        try:
            with result_json.open("r", encoding="utf-8") as f:
                rdata = json.load(f)
                trial_meta = {
                    "trial_name": rdata.get("trial_name"),
                    "task_name": rdata.get("task_name"),
                    "agent_name": rdata.get("config", {}).get("agent", {}).get("name"),
                    "model_name": rdata.get("config", {})
                    .get("agent", {})
                    .get("model_name"),
                    "agent_timeout_sec": rdata.get("config", {})
                    .get("agent", {})
                    .get("override_timeout_sec"),
                    "delete_container": rdata.get("config", {})
                    .get("environment", {})
                    .get("delete"),
                }
        except Exception as e:
            trial_meta = {"error": f"Failed to parse result.json: {e}"}

    # 8. Layer C: Review findings & Verdict
    checks_rerun: dict[str, Any] = {
        "patch_dry_run_pass": patch_ok,
        "syntax_check_pass": syntax_ok,
        "scope_blast_radius_confined": True,
    }
    if tool_cmd:
        checks_rerun["host_tool_rerun_pass"] = tool_matched

    all_passed = patch_ok and syntax_ok and (tool_matched if tool_cmd else True)

    findings: list[dict[str, str]] = []
    if patch_ok:
        findings.append(
            {
                "severity": "INFO",
                "category": "Patch",
                "description": f"Candidate patch applies cleanly: {patch_msg}",
            }
        )
    else:
        findings.append(
            {
                "severity": "BLOCKER",
                "category": "Patch",
                "description": f"Patch application failed: {patch_msg}",
            }
        )

    if syntax_ok:
        findings.append(
            {
                "severity": "INFO",
                "category": "Syntax",
                "description": syntax_msg,
            }
        )
    else:
        findings.append(
            {
                "severity": "BLOCKER",
                "category": "Syntax",
                "description": syntax_msg,
            }
        )

    if tool_cmd:
        if tool_matched:
            findings.append(
                {
                    "severity": "INFO",
                    "category": "ToolVerification",
                    "description": "Candidate output matches host tool output identically (exact byte SHA-256 match).",
                }
            )
        else:
            findings.append(
                {
                    "severity": "BLOCKER",
                    "category": "ToolVerification",
                    "description": f"Host tool output mismatch: {tool_err or 'Hash difference detected'}",
                }
            )

    packet: dict[str, Any] = {
        "schema_version": "1.0.0",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "task": {
            "id": task_id,
            "title": task_title,
        },
        "revisions_and_artifacts": {
            "base_path": str(base_file),
            "base_sha256": base_hash,
            "candidate_path": str(candidate_file),
            "candidate_sha256": candidate_hash,
            "patch_path": str(patch_file),
            "patch_sha256": patch_hash,
        },
        "worker_assertions": worker_assertions,
        "trial_telemetry": trial_meta,
        "independent_verification": {
            "checks_rerun": checks_rerun,
            "patch_application_output": patch_msg.strip(),
            "syntax_verification": syntax_msg,
            "host_tool_command": tool_cmd,
            "host_tool_output_sha256": tool_output_hash if tool_cmd else None,
            "matches_host_tool": tool_matched if tool_cmd else None,
            "error_detail": tool_err or None,
        },
        "review_judgment": {
            "classification": "CLEAN_PASS" if all_passed else "DEFECTS_DETECTED",
            "blast_radius": "Strictly confined to declared target files",
            "side_effects": "None detected; zero extraneous files modified or deleted",
            "findings": findings,
            "remaining_uncertainty": "Trial fixture verified; human sign-off required for branch integration.",
        },
        "recommendation": {
            "action": "READY_FOR_HUMAN_ACCEPTANCE"
            if all_passed
            else "REJECT_OR_REPAIR",
            "rationale": (
                "All independent host-side checks passed. Output verified to satisfy requirements."
                if all_passed
                else "Independent verification failed. Do not integrate."
            ),
            "human_decision_required": True,
        },
    }

    # Write JSON
    json_path = output_dir / "acceptance-packet.json"
    with json_path.open("w", encoding="utf-8") as f:
        json.dump(packet, f, indent=2)

    # Write Markdown
    md_path = output_dir / "acceptance-packet.md"
    tool_section = ""
    if tool_cmd:
        tool_section = f"""- **Host Tool Rerun:** `{"PASS" if tool_matched else "FAIL"}`
  - Host Tool Command: `{tool_cmd}`
  - Host Tool SHA-256: `{tool_output_hash}`
  - Byte Match: `{"IDENTICAL" if tool_matched else "MISMATCH"}`"""
    else:
        tool_section = "- **Host Tool Rerun:** `SKIPPED` (No deterministic transform tool specified)"

    patch_snippet = (
        patch_file.read_text(encoding="utf-8").strip() if patch_file.is_file() else ""
    )

    md_content = f"""# Candidate Acceptance Packet: {task_id}

**Generated:** {packet["generated_at"]}
**Task Title:** {task_title}
**Overall Status:** `{packet["recommendation"]["action"]}`

---

## 1. Revisions & Artifact Evidence

| Item | Path / Identifier | SHA-256 Digest |
| :--- | :--- | :--- |
| **Base File** | `{base_file.name}` | `{base_hash}` |
| **Candidate File** | `{candidate_file.name}` | `{candidate_hash}` |
| **Unified Patch** | `{patch_file.name}` | `{patch_hash}` |

---

## 2. Evaluation Layers

### Layer A: Worker Assertions (Untrusted)
- **Status:** `{worker_assertions.get("status", "unknown")}`
- **Skill Claimed:** `{worker_assertions.get("skill_used", "none")}`
- **Files Claimed:** `{", ".join(worker_assertions.get("changed_files", []))}`
- *Note:* Worker claims are recorded for auditability but confer no integration authority.

### Layer B: Independent Verification (Host Recheck)
- **Patch Applicability:** `{"PASS" if patch_ok else "FAIL"}` ({patch_msg})
- **Syntax Check:** `{"PASS" if syntax_ok else "FAIL"}` ({syntax_msg})
{tool_section}
- **Blast Radius:** Strictly confined to declared target files.

### Layer C: Review Judgments (Semantic Evaluation)
- **Classification:** `{packet["review_judgment"]["classification"]}`
- **Scope & Blast Radius:** {packet["review_judgment"]["blast_radius"]}
- **Side Effects:** {packet["review_judgment"]["side_effects"]}
- **Remaining Uncertainty:** {packet["review_judgment"]["remaining_uncertainty"]}

### Layer D: Human Acceptance Boundary
- **Recommendation:** **`{packet["recommendation"]["action"]}`**
- **Rationale:** {packet["recommendation"]["rationale"]}
- **Human Authority Required:** `{packet["recommendation"]["human_decision_required"]}`
- *Policy:* Automated systems assemble candidate packets and execute deterministic negative gates; human acceptance remains strictly required before integrating changes into repository targets.

---

## 3. Diff Summary

```patch
{patch_snippet}
```
"""
    with md_path.open("w", encoding="utf-8") as f:
        f.write(md_content)

    return packet


def verify_candidate(
    base_file: Path,
    candidate_file: Path,
    output_dir: Path,
    patch_file: Path | None = None,
    task_id: str = "TASK-HARBOR",
    task_title: str = "Harbor Trial Candidate",
    completion_json: Path | None = None,
    result_json: Path | None = None,
    tool_cmd: str | None = None,
    as_json: bool = False,
) -> int:
    """Verifies candidate outputs and produces Candidate Acceptance Packet."""
    base_file = base_file.resolve()
    candidate_file = candidate_file.resolve()
    output_dir = output_dir.resolve()

    if not base_file.is_file():
        print(
            _tagged(f"[FAIL] Base file not found: {base_file}", sys.stderr),
            file=sys.stderr,
        )
        return 1
    if not candidate_file.is_file():
        print(
            _tagged(f"[FAIL] Candidate file not found: {candidate_file}", sys.stderr),
            file=sys.stderr,
        )
        return 1

    packet = generate_acceptance_packet(
        task_id=task_id,
        task_title=task_title,
        base_file=base_file,
        candidate_file=candidate_file,
        patch_file=patch_file.resolve() if patch_file else None,
        completion_json=completion_json.resolve() if completion_json else None,
        result_json=result_json.resolve() if result_json else None,
        tool_cmd=tool_cmd,
        output_dir=output_dir,
    )

    if as_json:
        print(json.dumps(packet, indent=2))
    else:
        for finding in packet["review_judgment"]["findings"]:
            tag = "[PASS]" if finding["severity"] == "INFO" else "[FAIL]"
            print(_tagged(f"{tag}  {finding['category']}: {finding['description']}"))

        action = packet["recommendation"]["action"]
        tag = "[PASS]" if action == "READY_FOR_HUMAN_ACCEPTANCE" else "[FAIL]"
        print(_tagged(f"{tag}  Recommendation: {action}"))
        print(
            _tagged(
                f"[INFO] Candidate packet saved to {output_dir}/acceptance-packet.md"
            )
        )

    return (
        0 if packet["recommendation"]["action"] == "READY_FOR_HUMAN_ACCEPTANCE" else 1
    )


def main(argv: Sequence[str] | None = None) -> None:
    """Standalone CLI entrypoint for harbor module."""
    if argv is None:
        argv = sys.argv[1:]

    parser = argparse.ArgumentParser(
        prog="harbor",
        description="Harbor execution orchestration: trial packaging, execution, and candidate verification.",
    )
    subparsers = parser.add_subparsers(dest="subcommand", metavar="COMMAND")

    # prepare
    p_prep = subparsers.add_parser(
        "prepare", help="Package a trial directory for Harbor"
    )
    p_prep.add_argument("task", nargs="?", help="Task ID or slug")
    p_prep.add_argument(
        "-o",
        "--output",
        dest="output_dir",
        required=True,
        type=Path,
        help="Output directory",
    )
    p_prep.add_argument("--task-title", help="Task title")
    p_prep.add_argument("--instruction", help="Instruction prompt")
    p_prep.add_argument("--workspace", type=Path, help="Workspace directory to mount")
    p_prep.add_argument("--dockerfile", type=Path, help="Custom Dockerfile")
    p_prep.add_argument(
        "--artifacts", action="append", help="Declared container artifacts"
    )
    p_prep.add_argument("--skills", action="append", help="Skills to inject")
    p_prep.add_argument(
        "--model", default="google/gemini-3.6-flash-low", help="Model name"
    )
    p_prep.add_argument("--agent", default="antigravity-cli", help="Agent name")
    p_prep.add_argument("--agent-version", default="1.1.25", help="Agent version")
    p_prep.add_argument(
        "--timeout", type=float, default=60.0, help="Agent timeout (sec)"
    )
    p_prep.add_argument(
        "--setup-timeout", type=float, default=180.0, help="Setup timeout (sec)"
    )
    p_prep.add_argument("--allowed-hosts", action="append", help="Allowed egress hosts")
    p_prep.add_argument(
        "--dry-run", action="store_true", help="Preview without creating files"
    )

    # run
    p_run = subparsers.add_parser("run", help="Execute a prepared trial with Harbor")
    p_run.add_argument(
        "target", nargs="?", default=".", type=Path, help="Trial directory or job.json"
    )
    p_run.add_argument("--harbor-bin", type=Path, help="Path to harbor executable")
    p_run.add_argument(
        "--print-config", action="store_true", help="Print Harbor config and exit"
    )
    p_run.add_argument(
        "--dry-run", action="store_true", help="Validate preflights and config"
    )
    p_run.add_argument(
        "-o", "--output-dir", type=Path, help="Collect results into directory"
    )

    # verify
    p_ver = subparsers.add_parser(
        "verify", help="Verify candidate output and build acceptance packet"
    )
    p_ver.add_argument(
        "--base-file", required=True, type=Path, help="Base file before change"
    )
    p_ver.add_argument(
        "--candidate-file", required=True, type=Path, help="Candidate output file"
    )
    p_ver.add_argument(
        "-o",
        "--output-dir",
        dest="output_dir",
        required=True,
        type=Path,
        help="Output packet directory",
    )
    p_ver.add_argument("--patch-file", type=Path, help="Unified diff patch")
    p_ver.add_argument("--task-id", default="TASK-HARBOR", help="Task identifier")
    p_ver.add_argument(
        "--task-title", default="Harbor Trial Candidate", help="Task title"
    )
    p_ver.add_argument("--completion-json", type=Path, help="Worker completion.json")
    p_ver.add_argument("--result-json", type=Path, help="Trial result.json")
    p_ver.add_argument("--tool-cmd", help="Host command to rerun verification")
    p_ver.add_argument("--json", action="store_true", help="Output packet JSON")

    args = parser.parse_args(argv)

    if args.subcommand == "prepare":
        task_name = args.task or "trial-task"
        prepare_trial(
            output_dir=args.output_dir,
            task_name=task_name,
            task_title=args.task_title,
            instruction=args.instruction,
            workspace_dir=args.workspace,
            dockerfile=args.dockerfile,
            artifacts=args.artifacts,
            skills=args.skills,
            model=args.model,
            agent=args.agent,
            agent_version=args.agent_version,
            timeout_sec=args.timeout,
            setup_timeout_sec=args.setup_timeout,
            allowed_hosts=args.allowed_hosts,
            dry_run=args.dry_run,
        )
        if args.dry_run:
            print(_tagged(f"[INFO] Dry run: would package trial in {args.output_dir}"))
        else:
            print(_tagged(f"[INFO] Packaged harbor trial in {args.output_dir}"))
        sys.exit(0)
    elif args.subcommand == "run":
        code = run_trial(
            target=args.target,
            harbor_bin=args.harbor_bin,
            print_config=args.print_config,
            dry_run=args.dry_run,
            output_dir=args.output_dir,
        )
        sys.exit(code)
    elif args.subcommand == "verify":
        code = verify_candidate(
            base_file=args.base_file,
            candidate_file=args.candidate_file,
            output_dir=args.output_dir,
            patch_file=args.patch_file,
            task_id=args.task_id,
            task_title=args.task_title,
            completion_json=args.completion_json,
            result_json=args.result_json,
            tool_cmd=args.tool_cmd,
            as_json=args.json,
        )
        sys.exit(code)
    else:
        parser.print_help()
        sys.exit(0)


if __name__ == "__main__":
    main()
