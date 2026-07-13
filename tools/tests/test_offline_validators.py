#!/usr/bin/env python3
"""Focused regression tests for offline, read-only GSI validators."""

import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parents[1]
DOSSIER_VALIDATOR = TOOLS / "validate_gsi_candidate_dossier.py"
VNDK_AUDIT = TOOLS / "audit_strict_vndk.py"


class OfflineValidatorTests(unittest.TestCase):
    def dossier(self, directory: Path) -> Path:
        artifacts = {}
        for name in ("gsi_system_image", "vendor_image", "boot_image"):
            artifact = directory / f"{name}.img"
            artifact.write_bytes(name.encode())
            artifacts[name] = {"path": artifact.name, "sha256": hashlib.sha256(artifact.read_bytes()).hexdigest()}
        dossier = {
            "schema_version": "nx549j-gsi-candidate/v1",
            "candidate": {"name": "test", "source": "local", "architecture": "arm64", "ab_mode": "a-only"},
            "artifacts": artifacts,
            "static_checks": {name: {"status": "pass", "evidence": "test"} for name in ("strict_vndk_audit", "target_files_vintf", "binder_config")},
            "limitations": ["device boot and mount verification", "linker and SELinux verification", "encryption and recovery verification", "hardware VINTF and Binder verification"],
        }
        path = directory / "dossier.json"
        path.write_text(json.dumps(dossier), encoding="utf-8")
        return path

    def test_valid_dossier_with_hashes_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            result = subprocess.run([sys.executable, str(DOSSIER_VALIDATOR), "--verify-files", str(self.dossier(Path(temporary)))], text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_missing_device_limitations_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = self.dossier(Path(temporary))
            data = json.loads(path.read_text(encoding="utf-8"))
            data["limitations"] = []
            path.write_text(json.dumps(data), encoding="utf-8")
            result = subprocess.run([sys.executable, str(DOSSIER_VALIDATOR), str(path)], text=True, capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn("limitations must disclose", result.stderr)

    def test_current_static_configuration_passes(self) -> None:
        result = subprocess.run([sys.executable, str(VNDK_AUDIT)], text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
