# S11 Fall countdown

Prototype: [fall-countdown.html](fall-countdown.html). Source: `src/fall-countdown.src.html`.

**Purpose:** after a detected fall the user may be dazed. The safe action (cancel) must be the easiest; the dangerous action (send now) must be hard to do by accident. Shown over the lock screen with the screen woken.

## Elements and reasons
| Element | Reason |
|---|---|
| Tag "Fall detected" + GPS time | says why this appeared and when |
| "Did you fall?" (display) | the one question |
| Countdown ring + number (60 to 0) | how long until SOS goes out; ring is a live loop so it may move |
| "seconds until SOS is sent" (primary text) | the unit and meaning, so the number is never a mystery |
| "Detected: hard impact, then no movement for 30 s" | honest: why the app thinks you fell (helps a false alarm to be dismissed fast) |
| **I'm OK** (giant, most of the lower screen, single tap) | the safe action must be the easiest; a dazed or gloved user can hit it anywhere on the block |
| Send SOS now (small HoldButton 3 s, bottom, opposite side from the thumb) | skip the wait if clearly hurt; hold prevents accidents |

## States
Counting (60 to 0); last 10 s (haptic and sound rate doubles); SOS sent (continues to [SOS active](sos-active.html)); cancelled ("No SOS was sent · tracking continues", Back to trek).
Timer: Start 60 s / Jump to 8 s in the side panel.

## Decision
Ring colour: **red** (decided in D2). It is the final warning before an SOS is sent; the red allow-list in [tokens.md](tokens.md) includes it.

## Copy
"Did you fall?", "I'm OK", "Send SOS now · hold 3 s", "seconds until SOS is sent". No exclamation marks.

## Motion
Ring drains continuously; reduce-motion steps once per second. Nothing else moves.

## Haptics and sound
Strong repeated pulse every 1 s with an alarm tone; in the last 10 s every 0.5 s and a faster tone. Cancel: 1 short, alarm stops. SOS sent: SOS pattern.

## Accessibility
Timer role; aria-label updates every 5 s (not every second) so TalkBack does not chatter; I'm OK has label "I'm OK. Cancel the SOS"; hold has keyboard alternative; full-screen over the lock screen needs the full-screen-intent permission (M2 engineering).

## Self-review (D2)
- [x] safe action easiest, dangerous action hold-to-confirm
- [x] one display line plus the ring number: ring number is the single large number
- [x] loops only for the ring; reduce-motion defined
- [x] ring colour decided: red
