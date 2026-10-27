# PAGDANDI — Design Prompt
FIRST ACTION: save this entire prompt verbatim as docs/DESIGN.md and add a link to
it in CLAUDE.md.

You are now also acting as a senior product designer. Your job in this phase is to
design every screen of Pagdandi as clickable HTML prototypes for my approval,
BEFORE any Flutter UI code is written. Engineering milestone M0 may proceed in
parallel; Flutter UI must later match the approved prototypes exactly.

======================================================================
## 1. WHO WE DESIGN FOR
======================================================================
A trekker in Indian mountains: one hand holds a trekking stick, the other holds the
phone and uses only the thumb. Possibly wearing gloves, wet screen, harsh
sunlight, fog, cold, out of breath, tired, sometimes scared. Listening to music
with the phone locked most of the time. Travelling with 2-8 friends. Some prefer
Hindi.

Design questions every screen must answer for that person:
- What do I need to know right now? (in under 2 seconds)
- What can I do right now? (with one thumb, without precision)
- Is my group OK?
- What is the app doing for me in the background?

======================================================================
## 2. PRINCIPLES
======================================================================
1. THE REASON RULE: every element must have a stated reason from the user's
   point of view, on the trail, right now. No reason -> delete it.
2. Decoration must be data: the only "graphics" allowed are real information
   (real contour lines, the route's real elevation profile, real live pulses).
3. Glance first: one dominant piece of information per area; numbers big, labels
   small and quiet.
4. Thumb zone: everything interactive in the bottom ~40% of the screen. The top
   is display-only.
5. Calm under stress: the more serious the situation, the simpler the screen,
   the bigger the words, the less motion.
6. Honest: always show uncertainty and age ("±6 m", "seen 3 min ago",
   "forecast saved 5 h ago"). Never show stale data as if it were live.
7. Show the safety work: in emergencies, list in plain words what the app has
   already done and is doing.
8. Never colour alone: every state has an icon shape + words + colour.
9. Pocket-safe: nothing dangerous or irreversible happens from a single tap.
10. Feels like a mountaineering instrument (altimeter watch, aviation display,
    topographic map): precise, calm, quietly futuristic. Not a gadget, not a game.

BANNED (they make UIs look AI- or template-made): purple/blue gradients,
glassmorphism, heavy blur, glow and neon borders, drop shadows on black, generic
card grids, emoji as icons, stock illustrations, sparkle icons, mascots, "Welcome
back!" fluff, centered marketing hero layouts, motivational quotes, decorative
blobs, random pill shapes everywhere, Title Case labels, exclamation marks in UI
copy, loading spinners where a skeleton of real layout works.

======================================================================
## 3. DESIGN TOKENS
======================================================================
Colour (dark only; true black saves OLED battery):
  bg          #000000     surface   #0E1114   raised  #171B1F
  hairline    #262C32     muted-line #1A2026 (map contours)
  text        #ECEFF1     text-2    #8A949E   text-3  #5F6A74
  signal      #FF6B1A  rescue orange: primary action, you, PTT
  nav         #5CC8E0  glacier cyan: route, directions, info
  ok          #4CD18A  on route, in range, delivered
  warn        #FFB020  off route, weak link, health warnings
  sos         #FF3B30  RESERVED for SOS and real danger only
  State tints (HUD background, very subtle): nav #0B1A1F, warn #1F1608,
  signal #1F0F05, sos #1F0706.
Sunlight mode: text pure #FFFFFF, text-2 becomes #D0D6DB, lines 2x thicker,
  no text-3, state tints off, map contours stronger.
Contrast: WCAG AA everywhere; AAA for numbers and instructions.

Type (bundled, offline, OFL): Barlow (text), Barlow Condensed (large numbers),
Noto Sans Devanagari (Hindi). Tabular figures for all numbers. Two weights: 400
and 500 (600 allowed only for the single dominant number).
  display   44 / condensed  (one per screen max, emergencies)
  hero      30 / condensed  (main HUD number/instruction)
  title     20
  body      16
  label     13
  caption   12  (minimum on device)
Sentence case everywhere.

Spacing: 4 pt grid (4, 8, 12, 16, 20, 24, 32). Screen side padding 18.
Radius: 12 for panels, full circle for primary round actions, 8 for small chips.
Lines: hairlines 1 px; route 4 px; breadcrumb 3 px dotted.
Elevation: none. Separate with hairlines and surface steps, never shadows.

Icons: one consistent outline set, 2 px stroke (prototype with Tabler outline;
final app may use a custom-drawn set in the same style). Instrument markers:
ticks, bearing scales, distance rings.

Touch targets: minimum 56 dp; primary actions >= 72 dp; PTT >= 104 dp.
Glove mode: scale all targets x1.25 and spacing x1.15.

Motion tokens:
  fast 120 ms (press feedback), base 220 ms (state change), slow 320 ms (screen
  transition). Interactive motion uses springs (stiff, low bounce; no wobbly
  overshoot). Ease-out for entering, ease-in for leaving.
  Looping animation ONLY for something live: beacon broadcasting pulse, PTT
  waveform, regroup radar sweep, countdown ring. Stop all loops when screen off or
  hidden. Reduce-motion (system setting or Battery Saver): crossfades only.

Haptic vocabulary (shared with alerts engine; never reuse a pattern for another
meaning):
  tap feedback     10 ms light tick
  checkpoint / OK  1 short
  junction ahead   2 short
  off route        3 long, repeating until resolved or snoozed
  danger zone      long-short-long
  friend lost      2 long
  SOS (own/friend) ... --- ... repeating
  hold progress    light tick every second while holding
  hold complete    one strong pulse

Sound vocabulary: soft two-note chime before every voice alert; roger beep at
PTT start/end; channel-busy low beep; siren (alarm stream). Never play UI sounds
for ordinary taps.

======================================================================
## 4. LAYOUT SYSTEM
======================================================================
Every trek-time screen uses three zones:
  Glance zone (top ~35%): display only. Status, direction, key numbers.
  Context zone (middle): map, radar, or the main instruction.
  Thumb zone (bottom ~40%): all touchable controls.
Handedness setting mirrors the thumb zone (primary action under the thumb of
the phone hand; the most dangerous action on the opposite side from the most
used one).
No precise gestures: no double-tap, no small sliders, no short swipes required.
The only swipe is a large, forgiving swipe-up from PTT for quick messages, and it
always has a tap alternative.
Back navigation always available in the thumb zone during treks (not only the
system back gesture).

======================================================================
## 5. CORE COMPONENTS (design these first, as a component sheet)
======================================================================
- StatusTag: icon + word + colour (On route / Junction ahead / Off route /
  Wrong way / GPS lost / Regrouping / SOS).
- DirectionDial: circle with arrow; rotates via shortest angle with spring
  smoothing; colour follows state.
- HeroInstruction: one line, hero size ("Fork in 80 m"), one sub-line
  ("keep left · path going uphill").
- StatTriplet: three numbers with tiny labels (left, climb, to camp).
- GroupBar: "4 of 4 in range" + the single most important group fact
  ("Rahul 60 m behind" / "Rahul out of range").
- LinkStrength: 3 bars + word (strong / weak / out of range) + last seen.
- PttButton states: idle, pressed/talking (waveform), receiving (who), channel
  busy (disabled look with words, still tappable to show why).
- HoldButton: ring fills over N seconds with haptic ticks; release early springs
  back; used for SOS (3 s), cancel SOS (5 s), "I'm found" (3 s).
- QuickMessageArc: 4 large targets in an arc above PTT (Wait / Break / Go left /
  All OK), editable in settings.
- BigInstruction (emergencies): display-size words, one line.
- StatusChecklist (emergencies): live rows with icon + plain words + state
  (queued / sending / delivered / broadcasting).
- Countdown: large number + draining ring.
- PinTypeGrid: 2x3 large tiles.
- ReadinessRow: item + state + one-tap fix (used in Sync Pack).
- HealthBanner: warn colour, one line, tap for detail, dismissible.
- ElevationProfile: real profile of a route, with "you are here" when trekking.

======================================================================
## 6. SCREENS
======================================================================
For each screen: purpose, element list with reasons, all states, copy, motion,
haptics. (Elements below are the required minimum; propose improvements, but
justify each with a reason.)

S1 First-run setup (one decision per screen, big "Continue" in thumb zone,
   step "3 of 9"):
   language; handedness; your name + initials; emergency contacts; emergency card
   (blood group, allergies, medicines); permissions, one per screen, each with a
   one-line trail reason (e.g. Location: "So your group can find you without
   network"); battery exemption with brand-specific steps (Xiaomi, Samsung,
   Realme, Vivo, Oppo, OnePlus) and a "check again" button; offline voice test
   (plays a sample alert); ready summary.

S2 Basecamp (home, before a trek):
   next trip with its real elevation profile, distance, climb, date; Sync Pack
   readiness rows (maps downloaded, weather saved X h ago, voice ready, permits
   noted, group N of M ready) each with one-tap fix; group status; "Start trek"
   as the single large primary action in the thumb zone; recent treks library
   below the fold. Reason for no dashboard clutter: before a trek, the only real
   questions are "am I ready?" and "start".

S3 Trip planner: import GPX; route on map + elevation profile; time estimate
   (from group pace); suggested turnaround time; sunset time; add danger and
   checkpoint pins; Sync Pack checklist.

S4 Group: create (show QR big, for others to scan) / join (scan); member list with
   readiness (app set up, battery, map downloaded); roles: leader, sweep (last
   person), signal phone rotation schedule.

S5 ACTIVE TREK (most important; spend the most care here):
   Glance zone (surface #0E1114, hairline bottom):
     top row caption: GPS accuracy "±6 m" | StatusTag | battery %.
     DirectionDial (58 dp) + HeroInstruction.
     StatTriplet: distance left, climb left, time to camp.
   Context zone: offline map, custom dark topo style: real contours in
     muted-line; planned route nav cyan 4 px; your breadcrumb dotted, faint;
     unchosen branch at junctions grey (turns warn when you took it); junction
     node; friends as initials in circles with ok/text-3 rings; you as signal
     orange dot with heading cone; altitude caption bottom-right. One-finger pan;
     auto-recenter after ~8 s idle with a subtle recenter animation.
   Thumb zone:
     GroupBar full width.
     Dock (right-handed default): PTT bottom-right (104 dp, signal orange,
     "Hold to talk", caption "quick msgs" with up chevron above it); Pin button
     centre (50 dp); SOS HoldButton bottom-left (66 dp ring, sos colour, caption
     "hold 3 s"). Left-handed mirrors.
   States (HUD tint + tag + instruction + dial change together, 220 ms):
     On route:   "1.4 km" / "to Kalipokhri · stay on ridge"; ok tag.
     Junction:   "Fork in 80 m" / "keep left · path going uphill"; nav tint;
                 junction node highlighted; 2-short haptic.
     Off route:  "42 m off trail" / "turn back · trail is to your left"; warn
                 tint; taken branch turns warn; dial shows turn-back arrow;
                 "I know, exploring" snooze appears in thumb zone.
     Wrong way:  "Heading back to start" / "turn around to continue".
     GPS lost:   "GPS signal weak" / "last fix 2 min ago · keep to the trail";
                 position shown hollow with growing uncertainty circle.
     Regroup:    "Rahul · 210 m" / "last seen 3 min ago · downhill"; signal tint;
                 GroupBar in signal colour; your marker pulses (beacon live).
     Stationary: dims non-essential numbers; shows "Paused · tracking resumes when
                 you move".
   Reasons are mandatory in the notes for every element above.

S6 Group radar: polar view centred on you; rings at 50 / 100 / 200 m; friends at
   bearing and distance; out-of-range friends at last known position, hollow,
   with "seen X min ago"; list under the radar sorted by distance with
   LinkStrength; tap a friend -> "Guide me to Rahul" (DirectionDial + distance).
   Radar sweep animation only while actively scanning.

S7 PTT overlay (bottom sheet over Active Trek, never full screen):
   talking: your live waveform, "Talking to 3 friends", release to send;
   receiving: speaker's name big, waveform, "music lowered";
   busy: "Rahul is talking".

S8 Quick messages: swipe up from PTT (or tap the chevron) opens the arc; release
   on a target or tap it; sent confirmation inline; received quick messages show
   as a one-line toast in the glance zone + voice.

S9 Lost mode (for the person who is separated):
   BigInstruction "Stay where you are"; sub-line "Your group is coming to your
   last position"; DirectionDial + distance to the group's last known position
   with "seen X min ago"; StatusChecklist: Beacon broadcasting (live pulse) ·
   SOS SMS armed, sends at first signal · Group alerted; thumb zone: Torch strobe
   and Siren as two large toggles; "I need to move" (switches to guided backtrack
   along breadcrumb, with a reason prompt: cold / danger / dark); "I'm found"
   HoldButton (3 s).

S10 Friend lost / Friend SOS (for everyone else): full-screen takeover with the
   friend's name, what happened ("Rahul sent SOS" / "Rahul out of range"),
   DirectionDial + distance to last known position, time since; actions: "Guide
   me there", PTT, "Call 112" if any signal. SOS haptic repeating until
   acknowledged.

S11 Fall countdown: full-screen (shows over lock screen); "Did you fall?";
   Countdown (60 s) "Sending SOS in 47 s"; giant "I'm OK" button covering most of
   the lower screen (a single tap is allowed here, because the safe action must
   be the easiest); small "Send SOS now" HoldButton. Strong haptics + sound.

S12 SOS active: sos hairline + tag; coordinates and altitude in display size (so
   they can be read aloud on any call); StatusChecklist: SMS (queued / sending /
   delivered to 2 of 3 contacts) · Beacon broadcasting · Group alerted (3
   received) · Siren on/off · Torch on/off; battery estimate "41% · about 9 h in
   SOS mode"; thumb zone: Siren, Torch, "Call 112" (enabled only when any signal
   exists, otherwise explains why), Cancel SOS HoldButton (5 s). No decorative
   motion; only live pulses.

S13 Drop a pin: from the dock Pin button, PinTypeGrid (Water, Danger, Homestay,
   Signal here, Viewpoint, Custom); one tap saves with location and GPS time;
   optional note/photo afterwards; confirmation haptic.

S14 Timeline: alerts, check-ins, messages, pins, in time order with GPS time;
   filter chips large.

S15 Check-in timer: bottom sheet; large time options (+2 h, +4 h, until sunset,
   custom); who will be alerted; "Check in now" in the lock-screen notification.

S16 Health banners and detail: AMS ascent-rate warning (what it means, symptoms
   checklist, what to do), storm warning ("Pressure dropping fast · weather may
   turn"), offline first-aid guide (large text, step by step).

S17 Post-trek summary: route map, distance, climb, time, elevation profile,
   pins added; "Save to library"; export GPX.

S18 Settings: battery mode (Precise / Balanced / Saver, with honest battery
   impact), handedness, glove mode, sunlight mode, language, alert test (plays
   every vibration + voice pattern), music volume cap, quick message editor,
   emergency card, contacts, data and backup.

S19 Music mini player: a slim row above the GroupBar only when music plays;
   never covers the dock; play/pause/next only.

S20 Expenses: simple ledger, big number keypad, split among members, offline sync
   status.

S21 Lock-screen notification (first-class screen): line 1 next instruction;
   line 2 distance · climb · group status; actions: Talk (tap to start/stop),
   Check in, SOS (opens hold-to-confirm screen). Emergency card reachable from
   lock screen.

======================================================================
## 7. KEY FLOWS (prototype these as linked screens)
======================================================================
F1 First run -> Basecamp.
F2 Basecamp -> Start trek: the Start trek button morphs into the trek dock
   (shared-element transition, 320 ms) -> Active Trek.
F3 On route -> Junction ahead -> correct choice (1-short haptic) / wrong choice ->
   Off route -> back on route (tag returns to ok with a brief settle animation).
F4 Friend falls behind -> GroupBar warns -> out of range -> Regroup on others'
   phones + Lost mode on the separated phone -> reconnected -> normal.
F5 Fall -> countdown -> "I'm OK" or auto SOS -> SOS active -> cancelled.
F6 SOS pressed (3 s hold) -> SOS active -> friends receive Friend SOS.
F7 End trek -> summary -> library.

======================================================================
## 8. COPY AND VOICE
======================================================================
Plain, short, calm, imperative. Numbers always with units. Say what to do, not
just what happened. No jargon except "GPS". No exclamation marks.
Voice alert scripts (write all of them, English and Hindi), e.g.:
  "Fork in 80 metres. Keep left, going uphill."
  "Warning. You are 40 metres off the trail. Stop and check."
  "Rahul is 300 metres behind."
  "Sunset in one hour. Camp is 4 kilometres away, about 1 hour 40 minutes."
Emergency copy is reviewed twice for clarity under panic.

======================================================================
## 9. ACCESSIBILITY
======================================================================
TalkBack labels for every control; text scale up to 1.5 without breaking the
thumb zone (glance zone truncates gracefully, never the controls); colour-blind
safe states; Hindi layouts checked for text length.

======================================================================
## 10. DELIVERABLES AND PROCESS
======================================================================
For every screen create in docs/design/:
  <screen>.html  self-contained clickable prototype in a 360x780 phone frame,
                 true black, using the tokens above; buttons to switch every
                 state; toggles for handedness, sunlight mode, glove mode and
                 Hindi; working hold buttons and key animations.
  <screen>.md    element list with the reason for each, states, copy, motion,
                 haptics, and accessibility notes.
Also: docs/design/tokens.md, docs/design/components.html (component sheet),
docs/design/flows.html (linked flows F1-F7).

Batches (STOP after each batch for my approval and feedback):
  D1 tokens + component sheet
  D2 Active Trek (all states), Lost mode, Friend SOS, Fall countdown, SOS active
  D3 First-run setup, Basecamp, Group, Radar, PTT overlay, Quick messages,
     Lock-screen notification
  D4 Trip planner, Pins, Timeline, Check-in, Health, Summary, Settings, Music,
     Expenses, Flows

Self-review checklist before showing each batch:
  [ ] every element has a written reason
  [ ] all touch controls in the thumb zone; targets meet minimums
  [ ] 2-second glance test: status, direction, group are readable at arm's length
  [ ] no colour-only meaning
  [ ] nothing from the banned list
  [ ] dangerous actions are hold-to-confirm
  [ ] emergencies are calmer and simpler than normal screens
  [ ] works mirrored, in sunlight mode, glove mode and Hindi
  [ ] loops only for live things; reduce-motion version defined

After approval, the Flutter implementation must reproduce each prototype; golden
tests are reviewed side by side with the prototype screenshots.

Start with batch D1 now.
