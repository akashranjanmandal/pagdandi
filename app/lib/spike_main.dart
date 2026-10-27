import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/palette.dart';
import 'package:pagdandi_app/spike/map_spike.dart';

/// Entrypoint of the M0 map spike: `flutter run -t lib/spike_main.dart`.
void main() {
  runApp(
    WidgetsApp(
      color: Palette.normal.bg,
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: const MapSpikePage(),
    ),
  );
}
