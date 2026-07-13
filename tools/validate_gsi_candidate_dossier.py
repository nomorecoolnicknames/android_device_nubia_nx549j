#!/usr/bin/env python3
"""Fail-closed validator for an NX549J experimental A-only GSI dossier.

The dossier is evidence metadata only. A successful validation is not a flash
approval and does not establish on-device compatibility.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any

REQUIRED_FIELDS = {"schema_version": str, "candidate": dict, "artifacts": dict,
                   "static_checks": dict, "limitations": list}
REQUIRED_ARTIFACTS = ("gsi_system_image", "vendor_image", "boot_image")
REQUIRED_CHECKS = ("strict_vndk_audit", "target_files_vintf", "binder_config")
HEX_DIGITS = frozenset("0123456789abcdef")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def validate_sha256(value: Any, field: str) -> str | None:
    if not isinstance(value, str) or len(value) != 64:
        return f"{field} must be a 64-character SHA-256 string"
    if any(character not in HEX_DIGITS for character in value.lower()):
        return f"{field} must be hexadecimal"
    return None


def validate(dossier: Any, base_directory: Path, verify_files: bool) -> list[str]:
    errors: list[str] = []
    if not isinstance(dossier, dict):
        return ["top-level JSON value must be an object"]
    for field, expected_type in REQUIRED_FIELDS.items():
        if field not in dossier:
            errors.append(f"missing required field: {field}")
        elif not isinstance(dossier[field], expected_type):
            errors.append(f"{field} must be a {expected_type.__name__}")
    if errors:
        return errors
    if dossier["schema_version"] != "nx549j-gsi-candidate/v1":
        errors.append("schema_version must equal nx549j-gsi-candidate/v1")

    candidate = dossier["candidate"]
    for field in ("name", "source", "architecture", "ab_mode"):
        if not isinstance(candidate.get(field), str) or not candidate[field]:
            errors.append(f"candidate.{field} must be a non-empty string")
    if candidate.get("architecture") != "arm64":
        errors.append("candidate.architecture must be arm64")
    if candidate.get("ab_mode") != "a-only":
        errors.append("candidate.ab_mode must be a-only")

    base = base_directory.resolve()
    for name in REQUIRED_ARTIFACTS:
        artifact = dossier["artifacts"].get(name)
        if not isinstance(artifact, dict):
            errors.append(f"artifacts.{name} must be an object")
            continue
        relative_path = artifact.get("path")
        if not isinstance(relative_path, str) or not relative_path:
            errors.append(f"artifacts.{name}.path must be a non-empty relative path")
            continue
        artifact_path = (base / relative_path).resolve()
        if artifact_path == base or base not in artifact_path.parents:
            errors.append(f"artifacts.{name}.path escapes dossier directory")
            continue
        digest_error = validate_sha256(artifact.get("sha256"), f"artifacts.{name}.sha256")
        if digest_error:
            errors.append(digest_error)
        if verify_files:
            if not artifact_path.is_file():
                errors.append(f"artifacts.{name}.path is not a regular file: {relative_path}")
            elif not digest_error and sha256_file(artifact_path).lower() != artifact["sha256"].lower():
                errors.append(f"artifacts.{name} SHA-256 does not match {relative_path}")

    for name in REQUIRED_CHECKS:
        check = dossier["static_checks"].get(name)
        if not isinstance(check, dict) or check.get("status") != "pass":
            errors.append(f"static_checks.{name}.status must be pass")
        elif not isinstance(check.get("evidence"), str) or not check["evidence"]:
            errors.append(f"static_checks.{name}.evidence must be a non-empty string")

    required_limitations = {"device boot and mount verification", "linker and SELinux verification",
                            "encryption and recovery verification", "hardware VINTF and Binder verification"}
    if any(not isinstance(item, str) for item in dossier["limitations"]):
        errors.append("limitations entries must be strings")
    else:
        missing = required_limitations - set(dossier["limitations"])
        if missing:
            errors.append("limitations must disclose: " + ", ".join(sorted(missing)))
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dossier", type=Path, help="JSON candidate dossier")
    parser.add_argument("--verify-files", action="store_true", help="hash referenced local artifacts")
    arguments = parser.parse_args()
    try:
        dossier = json.loads(arguments.dossier.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR: cannot read dossier: {exc}", file=sys.stderr)
        return 2
    errors = validate(dossier, arguments.dossier.parent, arguments.verify_files)
    if errors:
        for message in errors:
            print(f"ERROR: {message}", file=sys.stderr)
        return 1
    print("PASS: dossier is structurally complete; device-only gates remain unverified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
