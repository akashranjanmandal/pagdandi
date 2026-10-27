# S10 Friend lost and Friend SOS (for everyone else)

Prototype: [friend-sos.html](friend-sos.html). Source: `src/friend-sos.src.html`.

**Purpose:** a friend needs help. Full-screen takeover, because ignoring it is the worst outcome. It shows who, what, where, and how to act.

## Elements and reasons
| Element | Reason |
|---|---|
| Tag "Friend SOS" (red) or "Friend out of range" (signal) | red only for a real SOS; out of range is serious but not an SOS |
| BigInstruction "Rahul sent SOS" / "Rahul out of range" (display) | who and what in four words |
| Sub-line (primary text) "4 min ago · last known position" | honesty: time since, and that the position is last known |
| Big DirectionDial + "340 m", "to last known position ±8 m · uphill" | where to go; uncertainty shown |
| Rahul's emergency card (secondary button) | blood group, allergies, medicines and contact are what a helper needs first |
| "Guide me there" (primary, 72 dp+) | the main action; also **acknowledges**: stops the repeating SOS buzz and tells the group you are going |
| Call 112 | enabled only with any signal; otherwise disabled with the reason written under it |
| PTT 104 dp (thumb side, mirrors) | talk to the group without leaving this screen |

## States
1. Rahul sent SOS (default). 2. Rahul out of range. 3. After "Guide me there": "Going to Rahul" / "Your group knows you are going", buzz stopped, **Back to trek map** shown (the takeover is over, the SOS is not).
Overlays: emergency card sheet; signal on/off.

## Copy
"Rahul sent SOS", "Rahul out of range", "Guide me there", "Call 112", "No signal yet", "Needs any mobile signal. Enables the moment one appears."

## Motion
None except the PTT waveform while talking. Dial turns by shortest angle (320 ms).

## Haptics
Friend SOS: ... --- ... repeating until acknowledged. Out of range: 2 long. Acknowledge: buzz stops, 1 short.

## Accessibility
Assertive live region for the first announcement ("Warning. Rahul sent an S.O.S. ..."); all controls labelled; disabled Call 112 is `aria-disabled` and its reason is read; handedness mirrors PTT.

## Self-review (D2)
- [x] each element has a reason; red used only for Friend SOS
- [x] controls in thumb zone; PTT on thumb side
- [x] no destructive single taps
- [x] calm: two lines of text, one dial, one primary action
