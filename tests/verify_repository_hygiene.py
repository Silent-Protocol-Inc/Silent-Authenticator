#!/usr/bin/env python3
"""Reject tracked runtime, backup, and legacy-material paths."""

from __future__ import annotations

from pathlib import Path, PurePosixPath
import subprocess


ROOT = Path(__file__).resolve().parent.parent
FORBIDDEN_NAMES = {"cloudflare.ini", "credentials.json", "secrets.json"}
FORBIDDEN_SUFFIXES = (".vault", ".gpg", ".pem", ".key", ".p12", ".pfx", ".pid", ".log", ".zip", ".tar", ".tar.gz")


def forbidden_reason(path: str) -> str | None:
	parts = PurePosixPath(path).parts
	name = parts[-1]
	if parts and parts[0] == "wantod":
		return "legacy rollback material"
	if ".sat" in parts:
		return "runtime state"
	if name in FORBIDDEN_NAMES:
		return "credential material"
	if name.endswith(FORBIDDEN_SUFFIXES):
		return "runtime, credential, or backup artifact"
	return None


def main() -> None:
	result = subprocess.run(
		["git", "-C", str(ROOT), "ls-files", "-z"],
		check=True,
		capture_output=True,
		text=True,
	)
	violations = [(path, reason) for path in result.stdout.split("\0") if path and (reason := forbidden_reason(path))]
	if violations:
		formatted = ", ".join(f"{path} ({reason})" for path, reason in violations)
		raise SystemExit(f"Repository hygiene failed: tracked forbidden paths: {formatted}")
	print("Repository hygiene checks passed.")


if __name__ == "__main__":
	main()
