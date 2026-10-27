# S9 Lost mode (for the separated person)

Prototype: [lost-mode.html](lost-mode.html). Source: `src/lost-mode.src.html`.

**Purpose:** the user is separated and possibly scared. The screen says one thing (stay), shows where the group is likely to be, and shows what the app is doing. Calmer and simpler than normal screens: no map, one big sentence, three status rows.

## Elements and reasons
| Element | Reason |
|---|---|
| Tag "Lost mode" (signal colour, stay icon) | tells me the app knows I am separated; not red because this is not SOS yet |
| BigInstruction "Stay where you are" (display) | staying put is the safest default; one short sentence |
| Sub-line in primary text (AAA) "Your group is coming to your last position" | calms and explains; true by design |
| Big DirectionDial + "320 m", "group's last position, seen 4 min ago, downhill" | which way the group probably is; age shown because it is a last-known position, not live |
| Checklist: Beacon broadcasting (live pulse) | proof the app is calling for help over radio |
| Checklist: SOS SMS armed, sends at first signal | proof the SMS will go as soon as any signal exists |
| Checklist: Group will be alerted, "when in range" | honest: separated phones cannot have been reached yet; switches to "3 received" when true (toggle in the side panel) |
| Torch strobe, Siren (LargeToggles) | visibility and audibility for rescuers; reversible single tap |
| "I need to move" | sometimes staying is wrong; opens the reason prompt |
| "I'm found" HoldButton 3 s | ends Lost mode; a hold so a pocket cannot cancel it |

## States
1. **Lost** (default).
2. **Reason prompt** (bottom sheet, scrim): Cold, Danger here, Getting dark, and "Stay here". Reason is sent to the group.
3. **Backtrack**: "Walk back slowly" / "Follow your breadcrumb · stop if the ground looks unsafe"; dial toward where the group last saw you (260 m); shows the reason sent; "Stay here instead" and "I'm found".
4. **Found**: "Marked as found"; beacon off, SOS SMS disarmed, group told (sends when in range if offline); "Back to trek".

## Copy
English only.

## Motion
No decorative motion. Only the beacon pulse (live). Sheet slides in 220 ms ease-out; reduce-motion: crossfade.

## Haptics
Entering Lost mode: no repeating buzz on this phone (SOS is only armed); on others' phones, friend lost = 2 long. Hold: tick each second, strong pulse on completion. Toggles: 1 short.

## Accessibility
All buttons labelled; "I'm found" `role=button` with 3 s hold and keyboard alternative; sheet is a dialog with a visible Stay here exit; no Back button (emergency screens: their actions are the exits).

## Self-review (D2)
- [x] every element has a reason; checklist never claims the group was reached before it was
- [x] thumb zone holds all controls; targets 72 dp+
- [x] no red (not SOS); signal colour used
- [x] calm: one display line, three rows, no map
