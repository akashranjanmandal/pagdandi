# S5 Active Trek

Prototype: [active-trek.html](active-trek.html). Source: `src/active-trek.src.html`. Tokens and components: [tokens.md](tokens.md), [components.md](components.md).

**Purpose:** the screen the trekker looks at while walking. It answers, in under 2 seconds: what do I do next, is my group OK, and what is the app doing for me.

## Layout (three zones)
| Zone | Contents | Why here |
|---|---|---|
| Glance (top, surface) | caption row, dial + hero, triplet "to camp", toast slot | display only; readable at arm's length |
| Context | offline map | situational awareness, never required for the next step |
| Thumb (bottom ~40%) | snooze (off route only), group row, key deck | everything touchable within thumb reach |

## Elements and reasons
| Element | Reason (on the trail, right now) |
|---|---|
| GPS accuracy "±6 m" (top-left) | honest uncertainty: tells me how much to trust the position and the instruction |
| StatusTag (top-centre) | one-glance "am I OK?" with shape + word + colour |
| Battery % (top-right) | trek is only safe while the phone lives; one number, quiet |
| DirectionDial 58 dp | which way, without reading; colour follows state |
| Hero (1.4 km) | the one thing to do next: distance to the next checkpoint or decision point |
| Sub-line (primary text, AAA) | the one detail that prevents a wrong turn |
| StatTriplet "to camp": 6.2 km, 320 m, 2:10 h | the three questions tired trekkers ask about today's destination; headed so it is never confused with the hero |
| Map: contours (muted) | terrain context, nearly invisible so the route reads first |
| Map: route (nav, 4 px) | where I should be |
| Map: breadcrumb (dotted, faint) | where I have been; the way back |
| Map: unchosen branch (grey; warn once taken) | shows the choice I did not make at a junction |
| Map: junction node (cyan ring when ahead) | the decision point |
| Map: friends (initials in rings; dashed hollow when out of range) | who is where, honestly |
| Map: you (orange dot, heading cone; hollow with growing circle when GPS lost) | my position and facing; hollow when I cannot be sure |
| Altitude caption (bottom-right) | altitude matters for health and navigation; small, quiet |
| SnoozeButton (Off route only) | stops the repeating buzz after a deliberate detour so alerts stay trusted |
| Group row (tappable, chevron) | "is my group OK?" without opening anything; tap opens the radar |
| SOS key (80 dp, 3 s hold, label inside) | emergency start that survives pockets and gloves; opposite side from PTT |
| Pin key (80 dp, label inside) | mark water, danger, signal in one tap while walking |
| PTT key (wide, 104 dp tall, "quick msgs" hint inside) | talk without looking; the swipe-up opens quick messages with a tap alternative |

## Bottom layout (reworked)
The group row is a full-width tappable row; below it a single aligned key deck on a surface panel: SOS and Pin as 80 dp labelled keys, PTT as the wide key on the thumb side. All labels are inside the keys (no floating captions); left-handed mirrors the order. Keys grow with large text instead of clipping.

## States (HUD tint, tag, instruction, dial and map change together in 220 ms)
| State | Tag | Hero / sub-line | Dial | Map | Group bar | Haptic | Voice (see [voice-scripts.md](voice-scripts.md)) |
|---|---|---|---|---|---|---|---|
| On route | ok | "1.4 km" / "to Kalipokhri · stay on ridge" | ahead, ok colour | you on route, friends in range | "4 of 4 in range" · "Rahul 60 m behind" | none (1 short when returning from off route/wrong way, tag settles) | none |
| Junction | fork, nav tint | "Fork in 80 m" / "keep left · path going uphill" | points left, nav | junction highlighted, branch grey | same | 2 short | yes |
| Off route | triangle, warn tint | "42 m off trail" / "turn back · trail is to your left" | arrow toward the trail, warn | taken branch turns warn (dotted) | same | 3 long, repeating until resolved or snoozed | yes |
| Wrong way | u-turn, warn tint | "Heading back to start" / "turn around to continue" | U-turn glyph (no arrow: a direction would mislead) | cone faces back along route | same | 3 short | yes |
| GPS lost | crosshair-slash, warn tint | "GPS signal weak" / "last fix 2 min ago · keep to the trail" | crosshair-slash glyph | hollow position, uncertainty circle grows over time | "distances paused · GPS lost" (warn) | 1 long | yes |
| Regroup | rings, signal tint | "Rahul · 210 m" / "last seen 3 min ago · downhill" | toward Rahul, signal | my marker pulses (beacon live); Rahul hollow dashed | signal colour: "Regrouping" · "Rahul · 210 m" | 2 long (friend lost) | yes |
| Stationary (overlay) | unchanged | triplet numbers dim to text-2; "Paused · tracking resumes when you move" (primary text) | unchanged | unchanged | unchanged | none | none |

## Free trek (no route loaded) - added with the first working core
Until a route is loaded (planner, M3) the core has no navigation state. The screen shows what is real: tag "Tracking" (nav colour, pin icon), hero = distance walked ("2.4 km", sub "walked · no route loaded"), the triplet headed "so far" (distance, climb so far, time), the breadcrumb only (no route, junction or branch), group row "Solo". No instruction is ever invented.

## Map behaviour
- One-finger pan. Auto-recenters after about 8 s of no touch (320 ms ease-out; reduce-motion: instant).
- Camera moves to the new position with a 320 ms transition on state change.
- Contours here are generated sample data; real tiles in M0.

## Copy
Short, imperative, numbers with units, no exclamation marks. English only.

## Motion
220 ms state change; 320 ms dial rotation (shortest angle) and map camera; loops only for the regroup beacon pulse and the PTT waveform; stop when hidden; reduce-motion: crossfades, no loops, uncertainty circle jumps to final size.

## Haptics
Per the vocabulary in [tokens.md](tokens.md). Wrong way (3 short) and GPS lost (1 long) were decided in D2 and added to the vocabulary.

## Accessibility
- Every control has a label; HoldButton and Snooze are `role=button` with `aria-label`; Space/Enter work.
- StatusTag, hero and sub-line form one live region (polite; SOS assertive) so TalkBack reads the state change once.
- Map has a text alternative (the hero/sub-line carry everything the map says).
- Text 1.5x: glance zone truncates with ellipsis; thumb controls never shrink or wrap off-screen.
- Left-handed mirrors the dock; glove mode scales targets x1.25.

## Self-review (D2)
- [x] every element has a reason
- [x] interactive elements in the bottom ~40% (map pan is the only touch above, and it is optional)
- [x] 2-second glance: tag, hero, dial, group bar readable
- [x] no colour-only meaning
- [x] no banned items
- [x] SOS is hold-to-confirm; snooze is reversible
- [x] loops only for live things
