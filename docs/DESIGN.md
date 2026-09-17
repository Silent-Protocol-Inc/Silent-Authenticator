# SAT Interface Specification

## Argument

SAT is a local security instrument: codes remain quiet and hidden until the operator deliberately asks for one.

## System

The interface uses semantic `--sat-*` tokens for spacing, control sizing, surfaces, borders, focus, motion, and z-index. Ten appearance modes share the same accessible components and data flow while selecting a controlled layout adapter: executive, top navigation, focused, briefing, office, ledger, console, security, layered, or editorial. A theme may alter visual density, typography treatment, surfaces, and navigation composition; it must not alter security behavior or control geometry unexpectedly.

Three type roles are fixed: Georgia/system serif for display, the operating-system sans stack for reading, and the system monospace stack for labels, identifiers, countdowns, and codes. Changing numbers use tabular figures. The selected appearance is stored only as `sat.theme`; vault tokens and OTP data never persist in browser storage.

All authoritative visual values live in `web/static/styles.css`. Silent Obsidian and Arctic Frost supply the baseline dark/light contrast references below; every other theme uses the same semantic component contracts:

| Pair | Dark | Light |
| --- | ---: | ---: |
| Primary text / ground | 16.91:1 | 14.74:1 |
| Muted text / ground | 9.19:1 | 6.12:1 |
| Control text / control | 12.03:1 | 6.41:1 |
| Report value / ground | 10.96:1 | 7.03:1 |
| Rule / surface | 4.25:1 | 4.75:1 |

The mobile layout replaces the multi-column grid with one card per row. Every control is at least 44px high. Focus is explicit, status never relies on color alone, and reduced-motion and forced-colors preferences receive dedicated rules.

## Layout and Component States

The shell uses shared container and spacing tokens. At compact widths every layout adapter returns to one normal-flow column; fixed positioning is reserved for the executive navigation, theme picker, toast, and decorative layers. Toolbars wrap, grids use `minmax(0, …)`, and dialogs scroll internally within the safe viewport.

The vault region defines loading, empty, ready, unauthorized, offline, and error states at one footprint. OTP cards define hidden and visible values; hidden is the default. Add/edit forms distinguish create and update, and destructive actions use a modal confirmation that returns focus through the native dialog contract.

## Honest Note

The interface has not been user-tested with assistive-technology users. Browser-level keyboard and viewport checks can prove mechanics, not comprehension. Very long issuer/account combinations wrap safely but may make cards uneven. The deliberate lack of a persistent token means a page reload requires re-authentication when network protection is enabled.
