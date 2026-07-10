#!/usr/bin/env python3
"""Repair the NX549J sensor init-config timed wait in the stock camera blob.

The 32-bit blob adds one billion to ``timespec.tv_nsec`` before calling
``pthread_cond_timedwait``.  That produces an invalid absolute deadline and
turns the intended wait for ``init_config_done`` into an immediate EINVAL.
This patch preserves the original predicate and changes the deadline to
``tv_sec += 1``.
"""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import tempfile


EXPECTED_SIZE = 1_060_456
SOURCE_SHA256 = "174c5e1a9aaf7ab22002fd8c1d2e498b494deefa86540e0c6e8e98b80ae52de9"
PATCHED_SHA256 = "ad29a1ac3f87eebbfba0a5a35b47156d09703a15b4854d95ec70e9416ccfce5e"

PATCHES = (
    (0x22ECE, bytes.fromhex("db f8 04 20"), bytes.fromhex("db f8 00 20")),
    (0x22EE4, bytes.fromhex("cb f8 04 30"), bytes.fromhex("cb f8 00 30")),
    (0x23198, bytes.fromhex("00 ca 9a 3b"), bytes.fromhex("01 00 00 00")),
)


def digest(data: bytes | bytearray) -> str:
    return hashlib.sha256(data).hexdigest()


def patch_blob(source: Path, destination: Path) -> None:
    source_data = source.read_bytes()
    source_digest = digest(source_data)

    if len(source_data) != EXPECTED_SIZE:
        raise SystemExit(
            f"refusing {source}: size {len(source_data)} != {EXPECTED_SIZE}"
        )
    if source_digest != SOURCE_SHA256:
        raise SystemExit(
            f"refusing {source}: SHA-256 {source_digest} != {SOURCE_SHA256}"
        )

    patched = bytearray(source_data)
    for offset, expected, replacement in PATCHES:
        actual = bytes(patched[offset : offset + len(expected)])
        if actual != expected:
            raise SystemExit(
                f"refusing {source}: bytes at 0x{offset:x} are "
                f"{actual.hex()}, expected {expected.hex()}"
            )
        patched[offset : offset + len(expected)] = replacement

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
