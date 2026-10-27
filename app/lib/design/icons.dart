/// The icon set: one outline family on a 24 grid, 2 px stroke, round caps.
/// Drawn as vector paths so no icon font or network is needed.
enum AppIcon {
  /// Circle with a check: on route.
  ok([_ok, 'M8.5 12.5l2.5 2.5 4.5-5']),

  /// Fork: junction ahead.
  fork(['M12 21v-8M12 13L6 7M12 13l6-6M6 7v3M6 7h3M18 7v3M18 7h-3']),

  /// Triangle: warning and off route.
  warn(['M12 4l9 16H3z', 'M12 10v4M12 17v.01']),

  /// U-turn: wrong way.
  uturn(['M8 20V9a4 4 0 018 0v3', 'M13 9l3 3 3-3']),

  /// Crosshair with a slash: GPS lost.
  gps([_gpsRing, 'M12 3v3M12 18v3M3 12h3M18 12h3M4 4l16 16']),

  /// Concentric rings: regroup, beacon.
  radar([_r2, _r6, _r10]),

  /// Octagon: SOS and blocking states.
  octagon(['M8 3h8l5 5v8l-5 5H8l-5-5V8z', 'M12 8v5M12 16v.01']),

  /// Battery.
  battery([
    'M5 8h12a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2z',
    'M21 11v3M7 11v3',
  ]),

  /// Microphone.
  mic([
    'M12 3a3 3 0 013 3v5a3 3 0 01-6 0V6a3 3 0 013-3z',
    'M6 11a6 6 0 0012 0M12 17v4',
  ]),

  /// Map pin.
  pin(['M12 21s-6-5.5-6-10a6 6 0 0112 0c0 4.5-6 10-6 10z', _pinDot]),

  /// Chevron up.
  up(['M6 15l6-6 6 6']),

  /// Cross.
  x(['M6 6l12 12M18 6L6 18']),

  /// Check mark.
  check(['M5 12.5l4.5 4.5L19 7']),

  /// Clock.
  clock([_clockFace, 'M12 7v5l3 2']),

  /// Paper plane: send.
  send(['M4 12l16-8-6 16-3-7z']),

  /// Two people: group.
  people([
    _head,
    'M3 20c0-3.5 3-6 6-6s6 2.5 6 6M16 5a3 3 0 010 6M18 14c2 .8 3 3 3 6',
  ]),

  /// Filled arrow: direction, you.
  arrow(['M12 3l7 17-7-4-7 4z'], filled: true),

  /// Torch.
  torch(['M8 3h8v4l-2 3v11h-4V10L8 7z', 'M12 13v2']),

  /// Siren.
  siren(['M7 18v-6a5 5 0 0110 0v6M5 21h14M12 3v2M4 7l1.5 1M20 7l-1.5 1']),

  /// Chevron left: back.
  back(['M15 6l-6 6 6 6']),

  /// Chevron right: opens.
  chevron(['M9 6l6 6-6 6']),

  /// Phone handset: call.
  call([_callPath]),

  /// Card: emergency card.
  card([
    'M5 5h14a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2z',
    'M7 10h4M7 14h6M16 10v.01',
  ]),

  /// Snowflake line: cold.
  cold(['M12 3v18M5 7l14 10M19 7L5 17']),

  /// Moon: getting dark.
  moon(['M20 14A8 8 0 019.5 4 8 8 0 1020 14z']),

  /// Walking person: I need to move.
  walk([
    'M13 2.7a1.8 1.8 0 110 3.6 1.8 1.8 0 010-3.6z',
    'M11 21l2-6-3-3 1-4 4 2 2 3M8 12l-2 3',
  ]),

  /// Square with a dot: stay.
  stay([
    'M8 5h8a3 3 0 013 3v8a3 3 0 01-3 3H8a3 3 0 01-3-3V8a3 3 0 013-3z',
    'M12 10a2 2 0 110 4 2 2 0 010-4z',
  ]),

  /// Eye: I know, exploring.
  eye([
    'M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z',
    'M12 9a3 3 0 110 6 3 3 0 010-6z',
  ]);

  const AppIcon(this.paths, {this.filled = false});

  /// SVG path data on a 24x24 grid.
  final List<String> paths;

  /// Whether the shape is filled instead of stroked.
  final bool filled;
}

const _ok = 'M12 3a9 9 0 110 18 9 9 0 010-18z';
const _gpsRing = 'M12 8a4 4 0 110 8 4 4 0 010-8z';
const _r2 = 'M12 10a2 2 0 110 4 2 2 0 010-4z';
const _r6 = 'M12 6a6 6 0 110 12 6 6 0 010-12z';
const _r10 = 'M12 2a10 10 0 110 20 10 10 0 010-20z';
const _pinDot = 'M12 9a2 2 0 110 4 2 2 0 010-4z';
const _clockFace = 'M12 3a9 9 0 110 18 9 9 0 010-18z';
const _head = 'M9 5a3 3 0 110 6 3 3 0 010-6z';

const _callPath =
    'M5 4h4l2 5-2.5 1.5a11 11 0 005 5L15 13l5 2v4a2 2 0 01-2 2 '
    'A16 16 0 013 6a2 2 0 012-2z';
