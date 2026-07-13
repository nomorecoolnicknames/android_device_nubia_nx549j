#!/usr/bin/env python3
"""Read-only fail-closed static audit for NX549J strict-VNDK GSI opt-in."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


def require(content: str, source: Path, needle: str, errors: list[str]) -> None:
    if needle not in content:
        errors.append(f"{source}: missing required text: {needle}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device-root", type=Path, default=Path(__file__).resolve().parents[1])
    arguments = parser.parse_args()
    device_root = arguments.device_root.resolve()
    common_root = device_root.parent / "msm8953-common"
    sources = {
        "common_board": common_root / "BoardConfigCommon.mk",
        "common_rootdir": common_root / "rootdir" / "Android.mk",
        "gsi_fstab": common_root / "rootdir" / "etc" / "fstab_gsi_aonly.qcom",
        "device_board": device_root / "BoardConfig.mk",
        "device_config": device_root / "device.mk",
    }
    try:
        content = {name: path.read_text(encoding="utf-8") for name, path in sources.items()}
    except OSError as exc:
        print(f"ERROR: unable to read audit input: {exc}", file=sys.stderr)
        return 2
    errors: list[str] = []
    for needle in ("PRODUCT_FULL_TREBLE_OVERRIDE := true", "BOARD_VNDK_VERSION := current",
                   "ifeq ($(NX549J_EXPERIMENTAL_GSI_AONLY),true)",
                   "BOARD_VNDK_RUNTIME_DISABLE := false", "BOARD_VNDK_RUNTIME_DISABLE := true"):
        require(content["common_board"], sources["common_board"], needle, errors)
    require(content["common_rootdir"], sources["common_rootdir"],
            "LOCAL_SRC_FILES    := etc/fstab_gsi_aonly.qcom", errors)
    fstab = content["gsi_fstab"]
    for expected in ("/by-name/boot", "/by-name/recovery", "/by-name/system", "/by-name/oem",
                     "\t/vendor", "first_stage_mount"):
        require(fstab, sources["gsi_fstab"], expected, errors)
    active_fstab = "\n".join(line for line in fstab.splitlines() if not line.lstrip().startswith("#"))
    if "slotselect" in active_fstab or re.search(r"/by-name/[^\t ]*_(?:a|b)(?:\t| )", active_fstab):
        errors.append(f"{sources['gsi_fstab']}: A-only fstab contains slot selection syntax")
    for needle in ("BOARD_USES_RECOVERY_AS_BOOT   := false", "BOARD_SKIP_RECOVERY_FROM_BOOT := true",
                   "BOARD_BUILD_SYSTEM_ROOT_IMAGE := false", "BOARD_VENDORIMAGE_PARTITION_SIZE   := 300384256",
                   "BOARD_VENDORIMAGE_EXTFS_INODE_COUNT := 4096"):
        require(content["device_board"], sources["device_board"], needle, errors)
    for needle in ("BUILD_BROKEN_PREBUILT_ELF_FILES := true", "FP_COMPAT_V28 :="):
        require(content["device_board"] + content["device_config"], device_root, needle, errors)
    if errors:
        for message in errors:
            print(f"ERROR: {message}", file=sys.stderr)
        return 1
    print("PASS: opt-in-only strict-VNDK static configuration is internally consistent")
    print("RISK: /system first_stage_mount is unverified with BOARD_BUILD_SYSTEM_ROOT_IMAGE := false")
    print("EXCEPTION: global broken-prebuilt ELF flags remain enabled")
    print("EXCEPTION: fingerprint uses scoped VNDK-v28 fp_compat libraries")
    print("DEVICE-GATE: boot/mount/linker/SELinux/encryption/recovery/VINTF/Binder remain unverified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
