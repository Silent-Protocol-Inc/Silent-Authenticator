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


def token(block: str, name: str) -> str:
	match = re.search(rf"--{re.escape(name)}:\s*(#[0-9a-fA-F]{{6}})", block)
	require(match is not None, f"semantic token --{name} must be a six-digit color")
	return match.group(1)


def main() -> None:
	root_match = re.search(r"(?m)^\s*:root\s*\{(.*?)^\s*\}", CSS, re.DOTALL)
	require(root_match is not None, "root token block")
	theme_blocks = {"silent-obsidian": root_match.group(1)}
	for theme_name, block in re.findall(r':root\[data-theme="([^"]+)"\]\{([^}]*)\}', CSS):
		theme_blocks.setdefault(theme_name, block)
	require(len(theme_blocks) == 10, "all ten theme token blocks")
	for theme_name, block in theme_blocks.items():
		pairs = (
			("primary text", token(block, "text-primary"), token(block, "background")),
			("muted text", token(block, "text-muted"), token(block, "background")),
			("primary control", token(block, "text-inverse"), token(block, "accent")),
			("hover control", token(block, "text-inverse"), token(block, "accent-hover")),
		)
		for role, foreground, background in pairs:
			require(contrast(foreground, background) >= 4.5, f"{theme_name} {role} contrast")

	require('<main id="main" tabindex="-1">' in HTML, "single focusable main landmark")
	require(HTML.count("<h1>") == 1, "exactly one h1")
	require('class="skip-link"' in HTML, "skip link")
	require('<dialog class="theme-panel"' in HTML and "showModal()" in JS, "native modal theme picker")
	require('class="workspace-overview__head"' in HTML and 'class="workspace-overview__body"' in HTML, "workspace operations must share one structured panel")
	require('class="workspace-frame"' in HTML and 'class="workspace-context"' in HTML, "vault controls must share a coherent workspace frame")
	require('id="sessionStatus" aria-live="polite"' in HTML, "workspace session state must be announced")
	require('class="otp-card__mark"' in HTML and 'class="otp-card__mode"' in HTML, "OTP cards need identity and protected-state hierarchy")
	require('class="state-panel__index"' in HTML, "empty and loading states need a stable visual anchor")
	require('class="layout-nav__index"' in HTML and 'class="layout-nav__footer"' in HTML, "navigation must expose hierarchy and local status")
	require('className = "theme-card__description"' in JS and 'className = "theme-card__selected"' in JS, "theme cards need descriptions and an explicit selected state")
	require('className = "theme-card__number"' in JS, "theme gallery must expose a scannable appearance index")
	require('[data-layout="briefing"] .workspace-frame' in CSS and '[data-layout="editorial"] .workspace-frame' in CSS, "appearance modes need structural composition variants")
	require('rejected ? "unauthorized" : "locked"' in JS, "initial access state must be locked rather than an invalid-token error")
	require('id="otpGrid"></ul>' in HTML, "OTP grid must not announce every timer update")
	require('aria-current", "location"' in JS, "navigation exposes the active section")
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
