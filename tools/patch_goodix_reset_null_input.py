#!/usr/bin/env python3
"""Repair the validated NX549J Goodix reset command input check.

The stock 64-bit gxfingerprint HAL rejects a NULL input pointer before sending
QSEE command 2, even though all reset call sites use the valid zero-length
form ``inBuf=NULL, inLen=0``. The guarded four-byte patch removes only that
pointer check; the output-buffer check and command-length validation stay
intact. Fingerprint remains fail-closed until its teardown race is fixed.
"""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import shutil
import tempfile


EXPECTED_SIZE = 100_192
SOURCE_SHA256 = "23e95284e986cf5f4d58786e6c4ad3525dcbaa6016440c5fddc15039217a4881"
PATCHED_SHA256 = "a629b98317e18320ce1700daabb3ae4289f0d41a4538e48a3917add9d23551fc"
PATCH_OFFSET = 0x9254
EXPECTED_BYTES = bytes.fromhex("da 0d 00 b4")
REPLACEMENT_BYTES = bytes.fromhex("1f 20 03 d5")


def digest(data: bytes | bytearray) -> str:
    return hashlib.sha256(data).hexdigest()


def patch_blob(source: Path, destination: Path) -> None:
    source_data = source.read_bytes()
    source_digest = digest(source_data)

    if len(source_data) != EXPECTED_SIZE:
        raise SystemExit(
            f"refusing {source}: size {len(source_data)} != {EXPECTED_SIZE}"
        )
    if source_digest == PATCHED_SHA256:
        if source.resolve() != destination.resolve():
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
        print(f"already patched {source}: {PATCHED_SHA256}")
        return
    if source_digest != SOURCE_SHA256:
        raise SystemExit(
            f"refusing {source}: SHA-256 {source_digest} != {SOURCE_SHA256}"
        )

    patched = bytearray(source_data)
    actual = bytes(patched[PATCH_OFFSET : PATCH_OFFSET + len(EXPECTED_BYTES)])
    if actual != EXPECTED_BYTES:
        raise SystemExit(
            f"refusing {source}: bytes at 0x{PATCH_OFFSET:x} are "
            f"{actual.hex()}, expected {EXPECTED_BYTES.hex()}"
        )
    patched[PATCH_OFFSET : PATCH_OFFSET + len(EXPECTED_BYTES)] = REPLACEMENT_BYTES

    patched_digest = digest(patched)
    if patched_digest != PATCHED_SHA256:
        raise SystemExit(
            f"internal verification failed: SHA-256 {patched_digest} "
            f"!= {PATCHED_SHA256}"
        )

    destination.parent.mkdir(parents=True, exist_ok=True)
    mode = source.stat().st_mode & 0o7777
    temporary_name: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            prefix=f".{destination.name}.",
            dir=destination.parent,
            delete=False,
        ) as temporary:
            temporary.write(patched)
            temporary.flush()
            os.fsync(temporary.fileno())
            temporary_name = temporary.name
        os.chmod(temporary_name, mode)
        os.replace(temporary_name, destination)
        temporary_name = None
    finally:
        if temporary_name is not None:
            Path(temporary_name).unlink(missing_ok=True)

    print(
        f"patched {source} -> {destination}: "
        f"{SOURCE_SHA256} -> {patched_digest}"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    patch_blob(args.source, args.destination)


if __name__ == "__main__":
    main()
