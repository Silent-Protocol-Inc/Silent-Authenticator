# SAT Interface Specification

## Argument

SAT is a local security instrument. The interface is therefore a panel: actions are teal, values produced by the authenticator are sand, and state is reported through a separate labelled channel.

## Selected system

The Web UI implements Signal (SIG–01) from the Silent Protocol design catalogue. Signal was selected over Console, Dossier, Sundial, and Tension because it combines an operational instrument structure with independently tuned light and dark grounds. Console and Sundial make every surface a transcript, Dossier is light-only and centred on withheld records, and Tension is a marketing composition rather than an application shell.

The application exposes three preferences: Signal dark, Signal light, and system. The system preference resolves from `prefers-color-scheme`; explicit choices win and persist only as `sat.theme`. Vault tokens and OTP data never persist in browser storage.

## Token contract

All authoritative visual values live in `web/static/styles.css` as semantic tokens. Components do not introduce local colour values.

- `--control` and its state tokens mark buttons, links, focusable choices, and other user actions.
- `--value` and `--value-soft` mark OTP codes, counts, algorithms, timers, and other machine-produced values.
- `--success`, `--warning`, `--danger`, and `--info` report state and always appear with text or a shape.
- `--border-width` is `1px`; `--radius` is `2px`; static surfaces use hairlines instead of shadows.
- Display, reading, and utility roles use separate font stacks. Changing numbers use the utility role with tabular figures.

Measured contrast:

| Pair | Signal dark | Signal light | Requirement |
| --- | ---: | ---: | ---: |
| Primary text / ground | 15.43:1 | 15.10:1 | 4.5:1 |
| Muted text / ground | 7.41:1 | 5.33:1 | 4.5:1 |
| Control label / control | 6.43:1 | 6.03:1 | 4.5:1 |
| Value / ground | 10.30:1 | 6.23:1 | 4.5:1 |
| Value / soft ground | 9.17:1 | 5.53:1 | 4.5:1 |

The automated design verifier recomputes these pairs from the source tokens and fails below 4.5:1.

## Layout

At workstation width, the navigation becomes a reserved left rail and the application occupies the remaining grid. The masthead's promoted rule aligns with the twelve-column background grid, so the grid is structural rather than decorative. Inside the rack, context and access span both tracks, then operations occupy the compact left workbench while the vault occupies the wider right workbench. This lets an operator search, inspect the session, and read authenticators at once without turning either concern into a floating dashboard card. The editor spans both tracks only while it is open. If access is already available, CSS closes that absent row so the two workbenches rise directly below context.

Below the rail breakpoint, the semantic document order returns to normal flow: context, access when needed, operations, editor, then vault. Operations and metrics become one column before either side becomes cramped; phone layouts replace multi-column forms, metric rows, and action bars with single-column or two-up arrangements.

The workspace frame groups context, access, operations, editor, vault state, and OTP entries into one instrument rack separated by 1px rules. Dialogs are the only floating surfaces. The appearance dialog uses native focus management, restores focus to its trigger, and supports arrow-key selection.

## Component states

The vault region defines locked, loading, empty, ready, unauthorized, offline, and error states at one stable footprint. Status never relies on colour alone. OTP cards begin hidden, identify the issuer structurally, label protected and active modes in text, and expose timer state accessibly. Destructive actions require a native confirmation dialog.

Every interactive target is at least 44px high. Focus is explicit, forced colours preserve boundaries, and reduced motion collapses transitions without hiding content. The 400-entry load path remains the density ceiling used by automated tests.

## Honest note

Signal fits SAT's instrument character but deliberately removes the ten unrelated appearance personalities that previously changed navigation and density. The result is easier to scan and maintain, at the cost of visual variety. System font stacks also limit how mechanical the display voice can feel without introducing a font dependency. Browser and automated accessibility checks prove mechanics and contrast, not comprehension by assistive-technology users.
