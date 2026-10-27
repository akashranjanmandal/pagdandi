import 'package:flutter/painting.dart';
import 'package:pagdandi_app/design/palette.dart';
import 'package:pagdandi_app/models/nav_state.dart';

/// State colour and HUD tint for a [NavState] (docs/design/tokens.md).
extension NavStyle on NavState {
  /// Colour of the tag, dial and arrow.
  Color color(Palette p) => switch (this) {
    NavState.onRoute => p.ok,
    NavState.junction => p.nav,
    NavState.offRoute || NavState.wrongWay || NavState.gpsLost => p.warn,
    NavState.regroup => p.signal,
  };

  /// Very subtle HUD background for the state.
  Color tint(Palette p) => switch (this) {
    NavState.onRoute => p.surface,
    NavState.junction => p.tintNav,
    NavState.offRoute || NavState.wrongWay || NavState.gpsLost => p.tintWarn,
    NavState.regroup => p.tintSignal,
  };
}
