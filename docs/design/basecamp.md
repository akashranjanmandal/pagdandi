# S2 Basecamp

Prototype: [basecamp.html](basecamp.html).

**Purpose:** before a trek there are two questions: am I ready, and start. No dashboard.

## Elements
| Element | Reason |
|---|---|
| Readiness rows (contacts, location, SMS, notifications, background, card) | the exact things that decide whether an SOS works; each with state in words and one-tap fix |
| "Start trek" primary key | the one action; disabled and explaining ("Fix 2 things first") when an SOS could not work |
| Emergency card key | reachable before the trek |
| Last trek | where the library will live (M4); "None yet" until then |

## States
Ready; blocked (critical items missing: no contacts, no SMS permission, no location); trek running (shows "Open trek" instead of Start).
Critical = contacts, location, SMS. Warnings (background not confirmed, empty card) do not block.

## Haptics
Start trek: 1 short; the foreground service starts and its notification appears.

## Accessibility
Rows are one semantic node each; the disabled Start key announces why it is disabled.

## Build note (2026-10-28)
Missing critical items use the amber warning colour with the octagon shape, the words "none added / not allowed" and the top position in the list. Red is kept for SOS only (colour rule, enforced by `sos_colour_rule_test`). The prototype's red rows are superseded by this.
