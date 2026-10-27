# S12 SOS active

Prototype: [sos-active.html](sos-active.html). Source: `src/sos-active.src.html`.

**Purpose:** my SOS is running. The screen gives me what I can read aloud on any call (position, altitude), tells me honestly what has happened so far, and gives me the few controls I might need. No decorative motion.

## Elements and reasons
| Element | Reason |
|---|---|
| Tag "SOS" (red) | unmistakable state; red is allowed here |
| Headline (hero size, truth rule) | never claims more than is true: "SOS active" / "SOS delivered to 2 of 3" / "SOS delivered" |
| Sub-line in primary text | what happens next, in plain words ("SMS will send at first signal · beacon on") |
| Coordinates in display size (2 lines) | read aloud to a rescuer, or to a phone operator |
| Altitude (hero size) | rescuers need it; |
| "position ±8 m · GPS time 14:32" | honest accuracy and age |
| Checklist: SMS to 3 contacts (queued / delivered n of 3), Beacon (broadcasting), Group alerted (sending / received) | shows the safety work the app has done, in words |
| Battery "41% · about 9 h in SOS mode (estimate)" | how long help can still reach me; labelled an estimate |
| Siren, Torch strobe (LargeToggles) | attract help; reversible, state shown by fill + word + icon |
| Call 112 | enabled only with any signal; disabled state explains why |
| Cancel SOS (HoldButton 5 s) | a false alarm must be cancellable, but never by a pocket |

## Decisions (confirmed in D2)
- The headline uses **hero** size, not display, so the coordinates can use the single display slot.
- Siren and Torch are shown by the toggles only, not repeated as checklist rows (same information twice).
- The own-phone SOS buzz repeats every 30 s until the first delivery, then stops.

## States
Delivery: nothing delivered, 2 of 3, all delivered. Signal on/off (Call 112). Siren/torch on/off. Cancelled: "SOS cancelled / Cancel message will send at first signal · beacon off" with Back to trek.

## Copy
Truth-first: queued, sending, delivered, broadcasting. English only.

## Motion
Only the beacon pulse. Reduce-motion: static dot.

## Haptics
SOS ... --- ... on start, then every 30 s until the first delivery, then stops. Hold: tick each second, strong pulse on completion. Toggles: 1 short.

## Accessibility
Coordinates have a spoken label ("Latitude 27.0410 north ..."); disabled Call 112 `aria-disabled` with reason; hold and toggles `role=button`; no Back (emergency screen).

## Self-review (D2)
- [x] emergencies calmer: one headline, coordinates, three rows, four controls
- [x] truth rule enforced in all three delivery states
- [x] dangerous action (Cancel SOS) hold-to-confirm
- [x] red only on SOS elements
