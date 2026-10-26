# SAT Interface Specification

## Argument

SAT is a local security instrument: codes remain quiet and hidden until the operator deliberately asks for one.

## System

The interface uses semantic `--sat-*` tokens for spacing, control sizing, surfaces, borders, focus, motion, and z-index. Ten appearance modes share the same accessible components and data flow while selecting a controlled navigation adapter: executive, top navigation, focused, briefing, office, ledger, console, security, layered, or editorial. A theme may alter visual density, typography treatment, surfaces, and navigation position; it must not squeeze or reorder the primary workspace unexpectedly.

Three type roles are fixed: Georgia/system serif for display, the operating-system sans stack for reading, and the system monospace stack for labels, identifiers, countdowns, and codes. Changing numbers use tabular figures. The selected appearance is stored only as `sat.theme`; vault tokens and OTP data never persist in browser storage.

All authoritative visual values live in `web/static/styles.css`. Silent Obsidian and Arctic Frost supply the baseline dark/light contrast references below; every other theme uses the same semantic component contracts:

| Pair | Dark | Light |
| --- | ---: | ---: |
| Primary text / ground | 16.52:1 | 14.03:1 |
| Muted text / ground | 7.65:1 | 5.44:1 |
| Control text / control | 8.24:1 | 5.94:1 |
| Report value / ground | 10.25:1 | 6.47:1 |
| Rule / surface | 3.36:1 | 3.52:1 |

The mobile layout replaces the multi-column grid with one card per row and turns section navigation into a two-by-two grid on the narrowest screens. Every control is at least 44px high. Focus is explicit, status never relies on color alone, and reduced-motion and forced-colors preferences receive dedicated rules. The appearance gallery uses a native dialog: it traps focus, restores it to its invoker, supports arrow-key movement through its radio choices, and gives every appearance a structural preview, category, description, and explicit active state.

## Layout and Component States

The shell uses shared container and spacing tokens. The masthead is a compact application bar rather than a promotional hero. A single workspace frame now groups session context, access, operations, editor, and vault content with one outer boundary and deliberate internal separators. The context header reports local encrypted storage and the actual locked/connected session state. Search/action controls and the four metrics live inside one named operations panel; they share a row when enough width exists and return to normal-flow stacking before either side becomes cramped. Search and Add OTP share a baseline on tablet and desktop. Only wide workstations receive a left or right navigation rail through an AppShell grid, so the rail reserves space instead of covering content. Focused and layered modes separate the frame into individual work surfaces; briefing and security modes use tested wide-screen summary/workspace splits; editorial mode turns context into a permanent typographic margin. Toolbars wrap, grids use `minmax(0, …)`, and dialogs scroll internally within the safe viewport.

The vault region defines locked, loading, empty, ready, unauthorized, offline, and error states at one footprint. The first unauthenticated request reports a neutral locked state; only a submitted bad token reports an authorization error. Search, reload, and entry creation remain unavailable until the vault connection succeeds. OTP cards define hidden and visible values; hidden is the default, each card carries a generated issuer monogram and explicit protected/active label, timers expose an accessible expiry value, and card actions name the affected entry. One or two entries use balanced grid compositions while larger vaults return to the responsive auto-fill grid. Add/edit forms distinguish create and update, and destructive actions use a modal confirmation that returns focus through the native dialog contract.

## Honest Note

The interface has not been user-tested with assistive-technology users. Browser-level keyboard and viewport checks can prove mechanics, not comprehension. Very long issuer/account combinations wrap safely but may make cards uneven. The deliberate lack of a persistent token means a page reload requires re-authentication when network protection is enabled.
