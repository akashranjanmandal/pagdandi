import 'package:flutter/painting.dart';
import 'package:pagdandi_app/design/palette.dart';

/// The only way UI code may obtain the SOS colour. Call it only from SOS,
/// Friend SOS, danger pin and danger zone widgets.
Color sosColour(Palette p) => p.sos;

/// The only way UI code may obtain the SOS HUD tint.
Color sosTint(Palette p) => p.tintSos;
