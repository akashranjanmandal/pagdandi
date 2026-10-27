# Pagdandi design tokens

Source: [DESIGN.md](../DESIGN.md) section 3, plus the decisions log at the bottom (D1 review). The CSS variables in `components.html` mirror this file; M0 turns it into Dart constants.

## Colour (dark only)
| Token | Hex | Job |
|---|---|---|
| bg | #000000 | Screen background (OLED black) |
| surface | #0E1114 | Glance zone, panels |
| raised | #171B1F | Pressed / selected / toast |
| hairline | #262C32 | Dividers |
| muted-line | #1A2026 | Map contours |
| text | #ECEFF1 | Primary text, **all instruction sub-lines** |
| text-2 | #8A949E | Labels and metadata only |
| text-3 | #6E7A85 | Non-essential, non-text-critical only (disabled rings, out-of-range outlines, axis ticks) |
| signal | #FF6B1A | You, PTT, primary action, toggles on |
| nav | #5CC8E0 | Route, direction, info |
| ok | #4CD18A | On route, in range, delivered |
| warn | #FFB020 | Off route, weak link, health, blocking readiness |
| sos | #FF3B30 | SOS and real danger only (rule below) |

HUD tints: nav #0B1A1F, warn #1F1608, signal #1F0F05, sos #1F0706.

**Sunlight mode:** text #FFFFFF, text-2 #D0D6DB, text-3 removed (uses text-2), lines 2x, tints off, contours stronger.

### Rule: where red may appear
> **sos colour appears only in SOS, Friend SOS, danger pins and danger zone states, plus the fall-countdown ring (the final seconds before an SOS is sent; decided in D2).**

Not allowed: link strength, readiness or "blocking" states, errors, delete, generic warnings (all use warn). Shape or words carry "blocking" (e.g. octagon icon in warn colour).

M0 test: a lint/golden-time check that scans UI code and prototypes for `sos` colour usage and fails if it appears outside the allow-list of widgets: SosTag, SosDial, SosHoldButton, CancelSosHold, FriendSosScreen, DangerPin, DangerZoneState, SosActiveScreen, FallCountdownRing.

### Contrast table (WCAG ratios, computed)
Required: AA 4.5:1 for text, AAA 7:1 for numbers and instructions.

| Foreground | on bg | surface | raised | tint-nav | tint-warn | tint-signal | tint-sos |
|---|---|---|---|---|---|---|---|
| text | 18.2 | 16.4 | 15.0 | 15.4 | 15.5 | 16.1 | 16.7 |
| text-2 | 6.8 | 6.1 | 5.6 | 5.8 | 5.8 | 6.0 | 6.2 |
| text-3 | 4.8 | 4.3 | 3.9 | 4.0 | 4.1 | 4.2 | 4.4 |
| signal | 7.4 | 6.6 | 6.1 | 6.2 | 6.3 | 6.5 | 6.8 |
| nav | 10.8 | 9.7 | 8.9 | 9.1 | 9.2 | 9.6 | 9.9 |
| ok | 10.8 | 9.7 | 8.9 | 9.1 | 9.2 | 9.6 | 9.9 |
| warn | 11.5 | 10.4 | 9.5 | 9.7 | 9.8 | 10.2 | 10.5 |
| sos | 5.9 | 5.3 | 4.9 | 5.0 | 5.0 | 5.2 | 5.4 |

Black text on signal 7.4, on ok 10.8, on sos 5.9.

Consequences:
- text-2 is AA everywhere but **not AAA**, so it is never used for instructions, sub-lines, or numbers.
- text-3 is below AA on surfaces: it is only for non-text-critical items. Paused StatTriplet numbers use text-2.
- sos is AA; used for words only at 13 px and larger weight 500.

**M0 task:** automated contrast test for every text/background pair in the Dart token set (normal and sunlight), failing the build below AA (AAA for the instruction and number styles).

## Type
Barlow (text) and Barlow Condensed (numbers); both bundled, OFL. Weights 400/500; 600 only for the single dominant number. Tabular figures.

| Style | Size | Family |
|---|---|---|
| display | 44 | condensed (one per screen, emergencies) |
| hero | 30 | condensed |
| title | 20 | text |
| body | 16 | text |
| label | 13 | text |
| caption | 12 | text (minimum) |

Sentence case. Prototype uses fallback fonts until M0.

## Spacing, shape, lines
- 4 pt grid: 4, 8, 12, 16, 20, 24, 32. Side padding 18.
- **Shape (revised):** buttons are rounded squares, not circles. Radius is about a quarter of the shorter side: PTT 28, hold buttons 20, quick-message targets 20, pin/toggle/snooze/back/wide hold 16, small chips 8, panels 12.
- Circles remain only for instrument or non-button elements: DirectionDial, avatars, countdown ring, beacon pulse.
- Lines: hairline 1 px (2 px in sunlight), route 4 px, breadcrumb 3 px dotted.
- Elevation: none.

## Buttons (D2 rework: physical keys)
One family, so nothing looks like a loose outlined box:
- **Key anatomy:** raised face (`raised`), 1 px lighter top rim, a 4 px flat darker lower edge (6 px on PTT, 8 px on the big OK key). Pressed: the key drops 3 px and the edge flattens (120 ms). No shadows, no glow: the edge is a flat band.
- **Hierarchy:** primary = signal-orange key (one per screen); secondary = neutral key with a leading icon; hold keys = neutral key whose progress fills in the action colour; toggles = neutral key with a status lamp, orange fill when on; disabled = dashed outline, no edge.
- **Colour** sits on the icon or the fill, never on competing outlines (e.g. snooze is a neutral key with an amber icon).
- Controls sit on a `surface` panel so keys read as raised.
- Source: the "Button system v2" block in `components.html`.

## Touch targets
Min 56 dp; primary 72 dp; LargeToggle and SnoozeButton >= 72 dp; PTT 104 dp. Glove mode: targets x1.25, spacing x1.15.

## Motion
fast 120 ms, base 220 ms, slow 320 ms. Springs stiff, no overshoot (`cubic-bezier(.2,.9,.25,1)`). Ease-out entering, ease-in leaving. Loops only for live things (beacon pulse, PTT waveform, regroup sweep, countdown ring); stop when hidden. Reduce-motion: crossfades only. Toast auto-hide 6 s, 220 ms fade.

## Haptics
| Meaning | Pattern |
|---|---|
| tap | 10 ms light tick |
| checkpoint / OK / toggle change / toast | 1 short |
| junction ahead | 2 short |
| off route | 3 long, repeating until resolved or snoozed |
| wrong way | 3 short (decided in D2) |
| GPS lost | 1 long (decided in D2) |
| danger zone | long-short-long |
| friend lost | 2 long |
| SOS | ... --- ... repeating; on the own phone every 30 s until the first delivery, then stops (decided in D2) |
| hold progress | tick each second |
| hold complete | one strong pulse |

## Sound
Two-note chime before voice alerts; roger beep at PTT start/end; low channel-busy beep; siren on alarm stream. No UI tap sounds.

## Icons
Outline, 24 grid, 2 px stroke, round caps (Tabler-style, hand-inlined for offline). Status shapes are distinct: circle-check, fork, triangle, u-turn, crosshair-slash, rings, octagon.

## HUD data rule
Never the same number twice with different meanings. **Hero** = distance to the next checkpoint or decision point (sample 1.4 km). **StatTriplet** is headed "to camp": distance (6.2 km), climb (320 m), time (2:10 h).

## Accessibility mapping
Every HoldButton, LargeToggle, SnoozeButton, ThumbBack has `role="button"`, `tabindex="0"`, `aria-label` in the prototype; these map one-to-one to Flutter `Semantics(button: true, label: ...)`. Keyboard Space/Enter works on all of them (holds start on press, cancel on release).

## Decisions log
- **D1 review:** sos colour restricted (rule above); text-3 changed to #6E7A85; instruction sub-lines use primary text; HUD number rule; buttons are rounded squares instead of circles; quick message "Go left" renamed "Take left fork"; LargeToggle, SnoozeButton, ThumbBack, Toast added.
- These decisions override DESIGN.md where they differ (notably "full circle for primary round actions" in the Radius token).
- **D2 decisions (2026-10-27):** fall-countdown ring stays red (added to the red allow-list); wrong way = 3 short; GPS lost = 1 long; SOS active headline is hero size (coordinates take the single display slot) and the own-phone SOS buzz repeats every 30 s until first delivery; English only (Hindi dropped).
