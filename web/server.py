#!/usr/bin/env python3
"""Local SAT web transport. Vault policy remains owned by the Bash CLI."""

from __future__ import annotations

import argparse
import base64
import binascii
import collections
import hmac
import json
import os
import shutil
import subprocess
import tempfile
import threading
import time
import urllib.parse
import uuid
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any


MAX_BODY_BYTES = 1_500_000
MAX_IMAGE_BYTES = 1_000_000
REQUESTS_PER_MINUTE = 120
STATIC_TYPES = {".css": "text/css; charset=utf-8", ".js": "text/javascript; charset=utf-8"}


def read_fd(fd: int) -> str:
	with os.fdopen(fd, "r", encoding="utf-8", closefd=True) as stream:
		return stream.readline().rstrip("\r\n")


class RateLimiter:
	def __init__(self, limit: int, window_seconds: int = 60) -> None:
		self.limit = limit
		self.window_seconds = window_seconds
		self.requests: dict[str, collections.deque[float]] = {}
		self.lock = threading.Lock()

	def allow(self, client: str) -> bool:
		now = time.monotonic()
		with self.lock:
			bucket = self.requests.setdefault(client, collections.deque())
			while bucket and now - bucket[0] >= self.window_seconds:
				bucket.popleft()
			if len(bucket) >= self.limit:
				return False
			bucket.append(now)
			return True


class SatApplication:
	def __init__(self, script: Path, sat_home: Path, static_root: Path, password: str, token: str, version: str) -> None:
		self.script = script.resolve()
		self.sat_home = sat_home.resolve()
		self.static_root = static_root.resolve()
		self.password = password
		self.token = token
		self.version = version
		self.rate_limiter = RateLimiter(REQUESTS_PER_MINUTE)

	@property
	def token_required(self) -> bool:
		return bool(self.token)

	def run_cli(self, arguments: list[str], payload: dict[str, Any] | None = None) -> tuple[int, dict[str, Any]]:
		password_read_fd, password_write_fd = os.pipe()
		try:
			os.write(password_write_fd, (self.password + "\n").encode())
		finally:
			os.close(password_write_fd)
		environment = os.environ.copy()
		environment.update(
			{
				"SAT_HOME": str(self.sat_home),
				"SAT_MASTER_PASS_FD": str(password_read_fd),
				"SAT_OUTPUT": "json",
			}
		)
		standard_input = json.dumps(payload) if payload is not None else None
		try:
			process = subprocess.run(
				[str(self.script), *arguments],
				input=standard_input,
				capture_output=True,
				text=True,
				env=environment,
				pass_fds=(password_read_fd,),
				timeout=15,
				check=False,
			)
		except subprocess.TimeoutExpired:
			return 8, {"error": "timeout", "message": "Operasi vault melewati batas waktu."}
		finally:
			os.close(password_read_fd)
		candidate = process.stdout.strip() if process.returncode == 0 else process.stderr.strip()
		try:
			data = json.loads(candidate or "{}")
		except json.JSONDecodeError:
			data = {"error": "command_failed", "message": "Operasi vault gagal tanpa respons terstruktur."}
		return process.returncode, data


def parse_totp_uri(uri: str) -> dict[str, Any] | None:
	parsed = urllib.parse.urlparse(uri.strip())
	if parsed.scheme.lower() != "otpauth" or parsed.netloc.lower() != "totp":
		return None
	query = urllib.parse.parse_qs(parsed.query, keep_blank_values=False)
	secret = (query.get("secret") or [""])[0].replace(" ", "").replace("-", "").upper()
	if not secret:
		return None
	decoded_label = urllib.parse.unquote(parsed.path.lstrip("/"))
	label_issuer, separator, account = decoded_label.partition(":")
	issuer = (query.get("issuer") or [label_issuer])[0]
	digits = (query.get("digits") or ["6"])[0]
	period = (query.get("period") or ["30"])[0]
	algorithm = (query.get("algorithm") or ["SHA1"])[0].upper()
	return {
		"label": decoded_label,
		"issuer": issuer,
		"account": account if separator else "",
		"secret": secret,
		"digits": int(digits) if digits.isdigit() else 6,
		"period": int(period) if period.isdigit() else 30,
		"algo": algorithm,
	}


def scan_qr(image: bytes) -> tuple[dict[str, Any] | None, str | None]:
	zbar = shutil.which("zbarimg")
	if not zbar:
		return None, "scanner_missing"
	if image.startswith(b"\x89PNG\r\n\x1a\n"):
		suffix = ".png"
	elif image.startswith(b"\xff\xd8\xff"):
		suffix = ".jpg"
	elif image.startswith((b"GIF87a", b"GIF89a")):
		suffix = ".gif"
	elif image.startswith(b"RIFF") and image[8:12] == b"WEBP":
		suffix = ".webp"
	else:
		return None, "invalid_image"
	path = ""
	try:
		with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as image_file:
			image_file.write(image)
			path = image_file.name
		process = subprocess.run([zbar, "--quiet", "--raw", path], capture_output=True, text=True, timeout=8, check=False)
		if process.returncode != 0:
			return None, "scan_failed"
		for line in process.stdout.splitlines():
			if line.strip().startswith("otpauth://"):
				parsed = parse_totp_uri(line)
				return (parsed, None) if parsed else (None, "invalid_otpauth")
		return None, "invalid_otpauth"
	except subprocess.TimeoutExpired:
		return None, "scan_timeout"
	finally:
		if path:
			try:
				os.unlink(path)
			except OSError:
				pass


class SatServer(ThreadingHTTPServer):
	daemon_threads = True
	allow_reuse_address = True

	def __init__(self, address: tuple[str, int], application: SatApplication) -> None:
		super().__init__(address, SatHandler)
		self.application = application


class SatHandler(BaseHTTPRequestHandler):
	server: SatServer
	protocol_version = "HTTP/1.1"

	def log_message(self, format_string: str, *args: Any) -> None:
		# Paths may contain labels. Keep operational logs metadata-only.
		print(json.dumps({"time": time.time(), "client": self.client_address[0], "method": self.command, "status": args[1]}), flush=True)

	def end_headers(self) -> None:
		self.send_header("Content-Security-Policy", "default-src 'none'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'")
		self.send_header("Referrer-Policy", "no-referrer")
		self.send_header("X-Content-Type-Options", "nosniff")
		self.send_header("X-Frame-Options", "DENY")
		self.send_header("Permissions-Policy", "camera=(), microphone=(), geolocation=(), payment=(), usb=()")
		self.send_header("Cross-Origin-Resource-Policy", "same-origin")
		self.send_header("Cache-Control", "no-store")
		super().end_headers()

	def send_json(self, status: int, data: dict[str, Any]) -> None:
		body = json.dumps(data, separators=(",", ":"), ensure_ascii=False).encode()
		self.send_response(status)
		self.send_header("Content-Type", "application/json; charset=utf-8")
		self.send_header("Content-Length", str(len(body)))
		self.end_headers()
		self.wfile.write(body)

	def send_static(self, path: Path, content_type: str, head_only: bool = False) -> None:
		try:
			body = path.read_bytes()
		except OSError:
			self.send_json(HTTPStatus.NOT_FOUND, {"error": "not_found", "message": "Resource tidak ditemukan."})
			return
		self.send_response(HTTPStatus.OK)
		self.send_header("Content-Type", content_type)
		self.send_header("Content-Length", str(len(body)))
		self.end_headers()
		if not head_only:
			self.wfile.write(body)

	def authorized(self) -> bool:
		app = self.server.application
		if not app.token_required:
			return True
		provided = self.headers.get("X-SAT-Token", "")
		if hmac.compare_digest(provided, app.token):
			return True
		self.send_json(HTTPStatus.UNAUTHORIZED, {"error": "unauthorized", "message": "Masukkan token akses SAT."})
		return False

	def within_rate_limit(self) -> bool:
		if self.server.application.rate_limiter.allow(self.client_address[0]):
			return True
		self.send_json(HTTPStatus.TOO_MANY_REQUESTS, {"error": "rate_limited", "message": "Terlalu banyak permintaan. Coba lagi sebentar."})
		return False

	def valid_origin(self) -> bool:
		origin = self.headers.get("Origin")
		if not origin:
			return True
		parsed = urllib.parse.urlsplit(origin)
		return parsed.scheme in {"http", "https"} and parsed.netloc == self.headers.get("Host", "")

	def read_payload(self) -> dict[str, Any] | None:
		content_type = self.headers.get("Content-Type", "").split(";", 1)[0].strip().lower()
		if content_type != "application/json":
			self.send_json(HTTPStatus.UNSUPPORTED_MEDIA_TYPE, {"error": "content_type", "message": "Gunakan Content-Type application/json."})
			return None
		try:
			length = int(self.headers.get("Content-Length", "0"))
		except ValueError:
			length = -1
		if length < 0 or length > MAX_BODY_BYTES:
			self.send_json(HTTPStatus.REQUEST_ENTITY_TOO_LARGE, {"error": "payload_too_large", "message": "Payload melewati batas 1,5 MB."})
			return None
		try:
			payload = json.loads(self.rfile.read(length) or b"{}")
		except (UnicodeDecodeError, json.JSONDecodeError):
			self.send_json(HTTPStatus.BAD_REQUEST, {"error": "invalid_json", "message": "Payload JSON tidak valid."})
			return None
		if not isinstance(payload, dict):
			self.send_json(HTTPStatus.BAD_REQUEST, {"error": "invalid_json", "message": "Payload harus berupa object JSON."})
			return None
		return payload

	def cli_response(self, arguments: list[str], payload: dict[str, Any] | None = None, success: int = HTTPStatus.OK) -> None:
		exit_code, data = self.server.application.run_cli(arguments, payload)
		status_by_exit = {2: HTTPStatus.BAD_REQUEST, 3: HTTPStatus.UNAUTHORIZED, 4: HTTPStatus.NOT_FOUND, 5: HTTPStatus.CONFLICT, 6: HTTPStatus.UNPROCESSABLE_ENTITY, 7: HTTPStatus.SERVICE_UNAVAILABLE, 8: HTTPStatus.SERVICE_UNAVAILABLE}
		self.send_json(success if exit_code == 0 else status_by_exit.get(exit_code, HTTPStatus.BAD_REQUEST), data)

	def do_GET(self) -> None:
		parsed = urllib.parse.urlsplit(self.path)
		if parsed.path == "/":
			self.send_static(self.server.application.static_root / "index.html", "text/html; charset=utf-8")
			return
		if parsed.path in {"/app.js", "/styles.css"}:
			path = self.server.application.static_root / parsed.path.lstrip("/")
			self.send_static(path, STATIC_TYPES[path.suffix])
			return
		if parsed.path == "/health":
			self.send_json(HTTPStatus.OK, {"status": "ok", "service": "sat-web"})
			return
		if not parsed.path.startswith("/api/"):
			self.send_json(HTTPStatus.NOT_FOUND, {"error": "not_found", "message": "Resource tidak ditemukan."})
			return
		if not self.within_rate_limit() or not self.authorized():
			return
		if parsed.path == "/api/config":
			self.send_json(HTTPStatus.OK, {"version": self.server.application.version, "token_required": self.server.application.token_required})
		elif parsed.path == "/api/list":
			self.cli_response(["list", "--json"])
		elif parsed.path == "/api/codes":
			self.cli_response(["codes", "--json"])
		elif parsed.path in {"/api/show", "/api/code"}:
			label = (urllib.parse.parse_qs(parsed.query).get("label") or [""])[0]
			if not label:
				self.send_json(HTTPStatus.BAD_REQUEST, {"error": "label_required", "message": "Label wajib diisi."})
			else:
				self.cli_response(["show" if parsed.path.endswith("show") else "code", label, "--json"])
		else:
			self.send_json(HTTPStatus.NOT_FOUND, {"error": "not_found", "message": "Endpoint tidak ditemukan."})

	def do_HEAD(self) -> None:
		parsed = urllib.parse.urlsplit(self.path)
		if parsed.path == "/":
			self.send_static(self.server.application.static_root / "index.html", "text/html; charset=utf-8", head_only=True)
			return
		if parsed.path in {"/app.js", "/styles.css"}:
			path = self.server.application.static_root / parsed.path.lstrip("/")
			self.send_static(path, STATIC_TYPES[path.suffix], head_only=True)
			return
		self.send_response(HTTPStatus.NOT_FOUND)
		self.send_header("Content-Length", "0")
		self.end_headers()

	def do_POST(self) -> None:
		parsed = urllib.parse.urlsplit(self.path)
		if not parsed.path.startswith("/api/"):
			self.send_json(HTTPStatus.NOT_FOUND, {"error": "not_found", "message": "Endpoint tidak ditemukan."})
			return
		if not self.within_rate_limit() or not self.authorized():
			return
		if not self.valid_origin():
			self.send_json(HTTPStatus.FORBIDDEN, {"error": "origin_rejected", "message": "Origin permintaan tidak diizinkan."})
			return
		payload = self.read_payload()
		if payload is None:
			return
		if parsed.path == "/api/add":
			self.cli_response(["add", "--payload-stdin", "--json"], payload, HTTPStatus.CREATED)
		elif parsed.path == "/api/update":
			self.cli_response(["update", "--payload-stdin", "--json"], payload)
		elif parsed.path == "/api/delete":
			label = str(payload.get("label") or "")
			self.cli_response(["delete", label, "--yes", "--json"])
		elif parsed.path == "/api/scan-qr":
			encoded = str(payload.get("image") or "")
			try:
				image = base64.b64decode(encoded, validate=True)
			except (binascii.Error, ValueError):
				self.send_json(HTTPStatus.BAD_REQUEST, {"error": "invalid_image", "message": "Data gambar tidak valid."})
				return
			if len(image) > MAX_IMAGE_BYTES:
				self.send_json(HTTPStatus.REQUEST_ENTITY_TOO_LARGE, {"error": "image_too_large", "message": "Gambar maksimal 1 MB."})
				return
			data, error = scan_qr(image)
			if error:
				self.send_json(HTTPStatus.UNPROCESSABLE_ENTITY, {"error": error, "message": "QR OTP tidak dapat dibaca."})
			else:
				self.send_json(HTTPStatus.OK, data or {})
		else:
			self.send_json(HTTPStatus.NOT_FOUND, {"error": "not_found", "message": "Endpoint tidak ditemukan."})

	def do_OPTIONS(self) -> None:
		self.send_json(HTTPStatus.METHOD_NOT_ALLOWED, {"error": "method_not_allowed", "message": "CORS tidak diaktifkan."})


def parse_arguments() -> argparse.Namespace:
	parser = argparse.ArgumentParser()
	parser.add_argument("--host", default="127.0.0.1")
	parser.add_argument("--port", type=int, default=8787)
	parser.add_argument("--script", type=Path, required=True)
	parser.add_argument("--sat-home", type=Path, required=True)
	parser.add_argument("--version", required=True)
	parser.add_argument("--password-fd", type=int, required=True)
	parser.add_argument("--token-fd", type=int, required=True)
	return parser.parse_args()


def main() -> None:
	args = parse_arguments()
	password = read_fd(args.password_fd)
	token = read_fd(args.token_fd)
	if not password:
		raise SystemExit("Master password is required")
	static_root = Path(__file__).resolve().parent / "static"
	application = SatApplication(args.script, args.sat_home, static_root, password, token, args.version)
	server = SatServer((args.host, args.port), application)
	print(json.dumps({"event": "ready", "host": args.host, "port": args.port, "token_required": bool(token)}), flush=True)
	try:
		server.serve_forever(poll_interval=0.25)
	except KeyboardInterrupt:
		pass
	finally:
		server.server_close()


if __name__ == "__main__":
	main()
