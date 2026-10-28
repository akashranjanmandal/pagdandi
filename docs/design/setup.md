# S1 First-run setup

Prototype: [setup.html](setup.html). Designed by the assistant under the "design the rest yourself" instruction; same tokens, keys and rules as D1/D2. English only.

**Purpose:** get a first-time user to a safe state: contacts for an SOS, the permissions that make tracking and SMS work, and the battery setting that stops phones killing the app. One decision per screen, big Continue in the thumb zone, progress "3 of 10".

## Steps and reasons
| # | Screen | Reason (trail, right now) |
|---|---|---|
| 1 | Which hand holds your phone? | mirrors the key deck so the main key is under the right thumb |
| 2 | What should your group call you? | name on the map, in alerts and in the SOS text; initials shown live |
| 3 | Emergency contacts | an SOS goes by SMS to these people; at least one required |
| 4 | Emergency card (skippable) | blood group, allergies, medicines readable by a helper |
| 5 | Allow location | positions for group and SOS without network |
| 6 | Allow location all the time | tracking and SOS must survive screen off and app closed |
| 7 | Allow sending SMS | an SOS cannot be sent without it |
| 8 | Allow notifications | shows the trek is running; warns if it stops |
| 9 | Keep Pagdandi running | brand steps (Xiaomi, Samsung, Realme, Vivo, Oppo, OnePlus) so the phone does not stop the trek |
| 10 | You are ready | summary with honest status; unconfirmed items stay amber |

## States
Each permission step: ask, denied. Denied keeps the user moving ("Continue without it") but says plainly what stops working and offers Open settings. Never a dead end, never a scare.

## Copy
Short, calm, no exclamation marks; every permission carries its one-line trail reason.

## Motion and haptics
Crossfade between steps (220 ms); progress bar grows. No haptics except 10 ms tick on keys.

## Accessibility
Labelled inputs, 64 dp fields, 56 dp chips, back control at the top and system back; text 1.5x wraps without clipping the Continue key.
