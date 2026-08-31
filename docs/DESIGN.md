# SAT Interface Specification

## Argument

SAT is a local security instrument: codes remain quiet and hidden until the operator deliberately asks for one.

## System

The interface uses a rule-separated instrument grid that remains identifiable in greyscale. Teal is reserved for controls, ochre for system-produced OTP values, and semantic colors for status. Static surfaces use borders without shadows. Corners use a single 2px radius.

Three type roles are fixed: Georgia/system serif for display, the operating-system sans stack for reading, and the system monospace stack for labels, identifiers, countdowns, and codes. Changing numbers use tabular figures.

All authoritative values live in the `tokens` layer of `web/static/styles.css`. The dark and light grounds are independently tuned. The following measurements mirror that layer for audit readability; do not edit them without changing and remeasuring the source tokens:

| Pair | Dark | Light |
| --- | ---: | ---: |
| Primary text / ground | 16.91:1 | 14.74:1 |
| Muted text / ground | 9.19:1 | 6.12:1 |
| Control text / control | 12.03:1 | 6.41:1 |
| Report value / ground | 10.96:1 | 7.03:1 |
| Rule / surface | 4.25:1 | 4.75:1 |

The mobile layout replaces the multi-column grid with one card per row. Every control is at least 44px high. Focus is explicit, status never relies on color alone, and reduced-motion and forced-colors preferences receive dedicated rules.

## Component States

The vault region defines loading, empty, ready, unauthorized, offline, and error states at one footprint. OTP cards define hidden and visible values; hidden is the default. Add/edit forms distinguish create and update, and destructive actions use a modal confirmation that returns focus through the native dialog contract.

## Honest Note

The interface has not been user-tested with assistive-technology users. Browser-level keyboard and viewport checks can prove mechanics, not comprehension. Very long issuer/account combinations wrap safely but may make cards uneven. The deliberate lack of a persistent token means a page reload requires re-authentication when network protection is enabled.
