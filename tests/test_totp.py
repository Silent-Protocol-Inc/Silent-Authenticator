#!/usr/bin/env python3
"""RFC 6238 regression vectors."""

from __future__ import annotations

import importlib.util
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parent.parent / "lib/totp.py"
SPEC = importlib.util.spec_from_file_location("sat_totp", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def main() -> None:
	vectors = [
		(59, "94287082"),
		(1111111109, "07081804"),
		(1111111111, "14050471"),
		(1234567890, "89005924"),
		(2000000000, "69279037"),
		(20000000000, "65353130"),
	]
	secret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
	for timestamp, expected in vectors:
		actual = MODULE.totp(secret, 8, 30, "SHA1", timestamp)
		if actual != expected:
			raise SystemExit(f"RFC vector failed at {timestamp}: {actual} != {expected}")
	print("TOTP vectors passed.")


if __name__ == "__main__":
	main()
