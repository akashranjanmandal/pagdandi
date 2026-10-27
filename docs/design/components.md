# Component sheet notes (D1, revision 2)

Prototype: [components.html](components.html). Toggles at the top: sunlight, glove, left-handed, reduce motion, text 1.5x. Every component below is interactive there. Tokens: [tokens.md](tokens.md).

Each component lists: **Reason** (trail, right now) · **States** · **Motion** · **Haptics** · **A11y**.

## StatusTag
- **Reason:** answers "am I OK?" in one glance. Icon shape + word + colour, so it works for colour-blind users and in sunlight.
- **States:** On route (ok), Junction ahead (nav), Off route (warn), Wrong way (warn), GPS lost (warn), Regrouping (signal), SOS (sos).
- **Motion:** none on the tag; changes together with HUD tint in 220 ms.
- **A11y:** announced as the word; changes are polite live-region updates, except SOS (assertive).

## DirectionDial
- **Reason:** "which way do I go?" without reading. Ticks at N/E/S/W give a real bearing scale.
- **States:** colour follows the state (nav default, ok, warn, signal, sos). 58 dp in HUD, 112 dp "big" in emergencies.
- **Motion:** shortest-angle rotation, 320 ms stiff spring, no overshoot. Reduce-motion: jumps with a crossfade.
- **A11y:** label "Go {left/right/behind} {n} degrees, {distance}". Arrow is not the only cue: distance and sub-line state it too.

## HeroInstruction
- **Reason:** one line is what to do next; sub-line is the one detail that stops a wrong turn.
- **Rules:** hero size, one line, ellipsis on overflow (never wraps into the dial). **Hero = distance to the next checkpoint or decision point.** Sub-line 16 px in primary text colour (AAA 7:1). text-2 is never used for instructions.
- **A11y:** read as one phrase; truncated text still available in full to TalkBack.

## StatTriplet
- **Reason:** three questions trekkers actually ask about today's destination: how far, how much climb, how long. Headed "to camp" so it can never be confused with the hero number.
- **Sample data:** 6.2 km distance, 320 m climb, 2:10 h time (hero is 1.4 km to the next checkpoint).
- **States:** live; paused (numbers dim to text-2, not text-3, and a "Paused · tracking resumes when you move" line appears in primary text).
- **Note:** caption units follow the language (km / कि.मी.).

## GroupBar
- **Reason:** "is my group OK?" without opening anything: count + single most important fact.
- **States:** all together, someone behind (ok), weak link (warn), out of range (warn), regroup (signal tint), solo.
- **A11y:** whole bar is one button announcing both texts; height >= 48 dp (60 dp in glove mode); it opens Radar.

## LinkStrength
- **Reason:** weak signal must never be mistaken for a live one. Bars + word + last-seen age.
- **States:** strong (3 bars ok), weak (1 to 2 bars warn, never red), out of range (grey, with "seen 3 min ago"). Avatar ring dashed when out of range.

## PttButton (rounded square, radius 28)
- **Reason:** talk without looking at the phone. Biggest control on the screen, under the phone-hand thumb.
- **States:** idle (orange), talking (live waveform), receiving (speaker's name, cyan ring), channel busy (dashed grey, words, still tappable to explain).
- **Motion:** 120 ms press scale; waveform loops only while talking/receiving.
- **Haptics:** 10 ms tick on press; roger beep start/end; low beep on busy tap.
- **A11y:** "Hold to talk" with press-and-hold custom action; TalkBack double-tap-and-hold supported; alternative toggle mode in Settings.

## HoldButton
- **Reason:** protects dangerous/irreversible actions from pockets, gloves and stumbles.
- **Variants:** rounded square (dock, 66 dp, radius 20, outline fills clockwise) and wide (full-width, 72 dp, radius 16).
- **States:** idle, holding (ring fills), released early (springs back in 260 ms), complete (fills solid).
- **Haptics:** tick every second, one strong pulse on completion.
- **A11y:** `role=button`, `tabindex=0`, `aria-label`; Space/Enter hold works too. TalkBack gets "SOS, hold 3 seconds" and a custom action that starts the same hold with a spoken countdown; never a single-tap shortcut.

## QuickMessageArc
- **Reason:** four canned messages answer most trail needs without talking; the arc sits in thumb sweep.
- **Messages:** Wait, Break, Take left fork, All OK.
- **States:** closed, open, picked (orange), sent confirmation inline.
- **Motion:** targets fan out 220 ms, 30 ms stagger; no overshoot.
- **Handedness:** arc mirrors with the dock.
- **A11y:** chevron tap alternative to the swipe; targets 72 dp (90 dp glove).

## Countdown
- **Reason:** dazed user must see time left at once. Giant number + draining ring.
- **Motion:** ring drains continuously (live loop); reduce-motion steps per second.
- **Haptics:** strong pulses, rate doubles in the last 10 s.
- **A11y:** live region every 5 s, not every second.

## BigInstruction
- **Reason:** in an emergency, one sentence to follow. Display size + one sub-line in primary text (AAA).
- **Truth rule (SOS):** big text never claims more than is true.
  - nothing delivered: "SOS active" / "SMS will send at first signal · beacon on"
  - partly: "SOS delivered to 2 of 3" / "1 contact still queued · beacon on"
  - all: "SOS delivered" / "3 of 3 contacts received it · beacon on"
- Removed: "Help is being contacted. Stay calm." (a promise the app cannot keep).
- The sheet has a switcher for all three states plus Lost mode.

## StatusChecklist
- **Reason:** shows the safety work the app has done, in words someone can read to a rescuer.
- **States per row:** queued, sending, delivered (n of m), broadcasting (live pulse), armed, off.
- **Motion:** only the beacon row pulses.

## LargeToggle (Torch strobe, Siren)
- **Reason:** switch with a gloved thumb and see at once whether it is on.
- **Spec:** 88 dp tall (>= 72), half-width each, rounded square radius 16. Off: outline + word "Off". On: solid signal fill + black text + word "On" (fill + word + icon, not colour alone).
- **Haptic:** 1 short on each change. Single tap allowed (reversible, helps the user, sends nothing to others).
- **A11y:** `role=button`, `tabindex=0`, `aria-label`, `aria-pressed`; Space/Enter toggles.

## SnoozeButton ("I know, exploring", 10 min)
- **Reason:** stops the off-route buzz after a deliberate detour so alerts stay trusted. In the thumb zone, shown only in Off route.
- **States:** ready; snoozed with live m:ss countdown and "Tap to resume alerts". Only off-route alerts are silenced, never SOS, friend or danger alerts.
- **Spec:** 72 dp (>= 72), radius 16. Haptic: tick on snooze, 1 short on resume.

## ThumbBack
- **Reason:** system back gesture is unreliable with gloves/stick/wet screen. Back at the bottom edge on the thumb side.
- **Spec:** 56 dp tall, icon + word, radius 16, mirrors with handedness (try the Left-handed toggle). Present on all trek-time screens except Active Trek; absent on emergency full-screens (their actions are the exits).

## Toast (received quick message)
- **Reason:** see a friend's message without opening anything.
- **Spec:** one line, sender (cyan) + message (primary text), at the bottom of the glance zone so it adds height instead of covering the dial, hero or numbers. Auto-hide 6 s, 220 ms fade; replaced by a newer message. Voice: chime, then "Rahul says: Wait". Polite live region. Not tappable.

## PinTypeGrid
- **Reason:** one-tap marking while walking. 2x3 tiles, >= 88 dp, words first.
- **Haptics:** 1 short on save. Confirmation inline with altitude and GPS time.

## ReadinessRow
- **Reason:** pre-trek "am I ready?" with honest age and a one-tap fix.
- **States:** ok (check), needs attention (triangle), blocking (octagon).

## HealthBanner
- **Reason:** slow risks (altitude, storm) noticed without interrupting the trail.
- **Rules:** one line + one detail line, warn colour, 2 px top rule, 56 dp dismiss, never covers the dock.

## ElevationProfile
- **Reason:** real route effort summary; with "you" marker becomes progress.
- **States:** planning (full route, climb total), trekking (passed section bright, km left, current altitude).

## Map layers
- **Reason:** context only: contours almost invisible, route/you/friends dominate.
- **States:** on route, junction highlighted, branch taken (breadcrumb warn), GPS lost (hollow position + uncertainty circle).

## Button system (D2 rework)
See the Buttons section in [tokens.md](tokens.md): all buttons are physical keys (raised face, light rim, dark lower edge that squashes when pressed), with icons, status lamps on toggles, and colour only on icons or fills.

## Shape
All buttons are rounded squares (radius about a quarter of the side). Circles remain only for the DirectionDial, avatars, the countdown ring and the beacon pulse (instrument/non-button elements).

## Known simplifications in the prototype
- Fonts: fallbacks, real fonts bundled in M0.
- Haptics: `navigator.vibrate` on supporting browsers; otherwise logged in text under the component.
- Contours and profile are sample data; real data comes from tile/GPX in M0+.
- Text 1.5x toggle scales key text inside stages to check overflow; full scale test arrives with golden tests.

## Self-review checklist (D1 revision 2)
- [x] every element has a written reason
- [x] touch targets: 56 dp minimum, toggles/snooze 72 dp+, hold >= 66 dp, PTT 104 dp
- [x] 2-second glance test: HUD status, direction, hero and to-camp numbers readable; no repeated number with different meaning
- [x] no colour-only meaning (shapes + words everywhere; toggles use fill + word + icon)
- [x] nothing from the banned list
- [x] red audit: sos colour only on SOS tag, SOS dial state, SOS and Cancel SOS holds, and the fall countdown ring (open question below); none on link strength or readiness
- [x] dangerous actions are hold-to-confirm (SOS, cancel SOS, found); torch/siren/snooze are reversible single taps
- [x] emergencies calmer and simpler: big text states only what is true
- [x] instruction sub-lines AAA (primary text); text-2 only for labels and metadata
- [x] works mirrored, sunlight, glove, reduce motion
- [x] loops only for live things (beacon pulse, waveform, countdown ring)
- [x] every HoldButton, LargeToggle, SnoozeButton, ThumbBack has role, tabindex, aria-label
- [x] prototype bugs: elevation stroke-width, icon path numbers
- [ ] Open question: fall countdown ring is red; the rule lists SOS, Friend SOS, danger pins and danger zone only. Keep it red (it is the last seconds before an SOS is sent) or switch to warn until SOS is active?
