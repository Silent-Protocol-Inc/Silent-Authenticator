#!/usr/bin/env python3
"""Focused regressions for SAT's HTTP transport helpers."""

from __future__ import annotations

import base64
import hashlib
import importlib.util
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
MODULE_PATH = ROOT / "web" / "server.py"
SPEC = importlib.util.spec_from_file_location("sat_server", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def require(condition: bool, message: str) -> None:
	if not condition:
		raise SystemExit(message)


def inline_script_hash() -> str:
	html = (ROOT / "web" / "static" / "index.html").read_text(encoding="utf-8")
	start = html.index("<script>") + len("<script>")
	end = html.index("</script>", start)
	return base64.b64encode(hashlib.sha256(html[start:end].encode("utf-8")).digest()).decode("ascii")


def main() -> None:
	require(MODULE.host_matches_allowed("sat.example.com", "sat.example.com"), "exact configured host should pass")
	require(MODULE.host_matches_allowed("sat.example.com:443", "sat.example.com"), "configured host with a numeric port should pass")
	require(not MODULE.host_matches_allowed("spm.example.com", "sat.example.com"), "unrelated host must be rejected")
	require(not MODULE.host_matches_allowed("sat.example.com:invalid", "sat.example.com"), "invalid host port must be rejected")
	require(not MODULE.host_matches_allowed("sat.example.com.evil.invalid", "sat.example.com"), "host suffixes must not match")

	limiter = MODULE.RateLimiter(limit=1, window_seconds=60, max_clients=2)
	require(limiter.allow("one"), "first request should pass")
	require(not limiter.allow("one"), "per-client limit should apply")
	require(limiter.allow("two"), "second client should fit capacity")
	require(not limiter.allow("three"), "client bucket capacity should be bounded")
	limiter.requests["one"].clear()
	limiter.requests["two"].clear()
	require(limiter.allow("three"), "expired client buckets should be reclaimed")

	parsed = MODULE.parse_totp_uri("otpauth://totp/Example:alice?secret=JBSWY3DPEHPK3PXP&issuer=Example")
	require(parsed is not None and parsed["account"] == "alice", "valid TOTP URI should parse")
	require(MODULE.parse_totp_uri("https://example.invalid/") is None, "non-TOTP URI must be rejected")

	csp_hash = inline_script_hash()
	server_source = MODULE_PATH.read_text(encoding="utf-8")
	require(csp_hash in server_source, "CSP must authorize the current inline theme bootstrap")
	print("Server transport regressions passed.")


if __name__ == "__main__":
	main()
