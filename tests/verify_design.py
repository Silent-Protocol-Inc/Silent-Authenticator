#!/usr/bin/env python3
"""Objective checks for SAT's standalone design and browser security contract."""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CSS = (ROOT / "web/static/styles.css").read_text(encoding="utf-8")
HTML = (ROOT / "web/static/index.html").read_text(encoding="utf-8")
JS = (ROOT / "web/static/app.js").read_text(encoding="utf-8")


def luminance(color: str) -> float:
	channels = [int(color[index : index + 2], 16) / 255 for index in (1, 3, 5)]
	linear = [channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4 for channel in channels]
	return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(first: str, second: str) -> float:
	high, low = sorted((luminance(first), luminance(second)), reverse=True)
	return (high + 0.05) / (low + 0.05)


def require(condition: bool, message: str) -> None:
	if not condition:
		raise SystemExit(f"Design verification failed: {message}")


def main() -> None:
	pairs = {
		"dark primary": ("#f2f5f3", "#101413", 4.5),
		"dark muted": ("#aeb9b4", "#101413", 4.5),
		"dark control": ("#72dfd0", "#07110f", 4.5),
		"dark report": ("#f0bf73", "#101413", 4.5),
		"dark rule": ("#74817b", "#161c1a", 3.0),
		"light primary": ("#17201d", "#f3f1ea", 4.5),
		"light muted": ("#4f5d57", "#f3f1ea", 4.5),
		"light control": ("#ffffff", "#006b61", 4.5),
		"light report": ("#744700", "#f3f1ea", 4.5),
		"light rule": ("#69756f", "#fffef9", 3.0),
	}
	for name, (foreground, background, floor) in pairs.items():
		require(foreground in CSS and background in CSS, f"{name} tokens must exist in CSS")
		require(contrast(foreground, background) >= floor, f"{name} contrast")

	require('<main id="main" tabindex="-1">' in HTML, "single focusable main landmark")
	require(HTML.count("<h1>") == 1, "exactly one h1")
	require('class="skip-link"' in HTML, "skip link")
	require("prefers-reduced-motion: reduce" in CSS, "reduced-motion path")
	require("forced-colors: active" in CSS, "forced-colors path")
	require("min-height: var(--sat-control-size)" in CSS and "--sat-control-size: 2.75rem" in CSS, "44px control target")
	require(".layout-nav a{min-height:var(--sat-control-size)}" in CSS, "mobile navigation must meet the 44px touch target")
	require("innerHTML" not in JS and "insertAdjacentHTML" not in JS, "untrusted text must use DOM APIs")
	require(not re.search(r"token.*localStorage|localStorage.*token", JS, re.IGNORECASE), "token cannot use localStorage")
	require("transition: all" not in CSS, "no transition-all")
	require("100vh" not in CSS, "no fixed viewport-height layout")
	require("outline: none" not in CSS, "focus outline cannot be removed")
	print("Design checks passed.")


if __name__ == "__main__":
	main()
