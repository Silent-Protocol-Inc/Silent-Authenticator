#!/usr/bin/env python3
"""Small RFC 6238 helper. Secrets are read from stdin or a mode-0600 vault file."""

from __future__ import annotations

import argparse
import base64
import hashlib
import hmac
import json
import struct
import sys
import time
from pathlib import Path


HASHES = {"SHA1": hashlib.sha1, "SHA256": hashlib.sha256, "SHA512": hashlib.sha512}


def totp(secret: str, digits: int, period: int, algorithm: str, now: int) -> str:
	key = base64.b32decode(secret.upper() + "=" * ((8 - len(secret) % 8) % 8), casefold=True)
	counter = now // period
	digest = hmac.new(key, struct.pack(">Q", counter), HASHES[algorithm]).digest()
	offset = digest[-1] & 0x0F
	value = struct.unpack(">I", digest[offset : offset + 4])[0] & 0x7FFFFFFF
	return str(value % (10**digits)).zfill(digits)


def code_mode(args: argparse.Namespace) -> None:
	secret = sys.stdin.read().strip()
	now = int(time.time())
	code = totp(secret, args.digits, args.period, args.algorithm, now)
	remaining = args.period - (now % args.period)
	print(json.dumps({"code": code, "expires_in": remaining, "period": args.period, "digits": args.digits}))


def codes_mode(args: argparse.Namespace) -> None:
	now = int(time.time())
	vault = json.loads(Path(args.vault).read_text(encoding="utf-8"))
	entries = []
	for label, item in vault.items():
		secret = str(item.get("secret") or "").strip()
		if not secret:
			continue
		digits = int(item.get("digits") or 6)
		period = int(item.get("period") or 30)
		algorithm = str(item.get("algo") or "SHA1").upper()
		if algorithm not in HASHES:
			continue
		try:
			value = totp(secret, digits, period, algorithm, now)
		except (ValueError, TypeError):
			continue
		entries.append(
			{
				"label": label,
				"issuer": item.get("issuer") or "",
				"account": item.get("account") or "",
				"digits": digits,
				"period": period,
				"algo": algorithm,
				"code": value,
				"expires_in": period - (now % period),
			}
		)
	print(json.dumps({"entries": entries}, separators=(",", ":")))


def main() -> None:
	parser = argparse.ArgumentParser()
	sub = parser.add_subparsers(dest="command", required=True)
	code = sub.add_parser("code")
	code.add_argument("--digits", type=int, required=True)
	code.add_argument("--period", type=int, required=True)
	code.add_argument("--algorithm", choices=sorted(HASHES), required=True)
	code.set_defaults(handler=code_mode)
	codes = sub.add_parser("codes")
	codes.add_argument("--vault", required=True)
	codes.set_defaults(handler=codes_mode)
	args = parser.parse_args()
	args.handler(args)


if __name__ == "__main__":
	main()
