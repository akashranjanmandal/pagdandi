import 'package:core_common/core_common.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagdandi_app/app/pagdandi_root.dart';
import 'package:pagdandi_app/app/services.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/preview/gallery.dart';
import 'package:pagdandi_app/preview/preview_settings.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Root widget. With a [bootstrap] it is the real app (Setup, Basecamp,
/// trek); without one it opens the gallery of approved screens.
class PagdandiApp extends ConsumerWidget {
  /// Creates the app.
  const PagdandiApp({this.bootstrap, super.key});

  /// Builds the services; null opens the preview gallery.
  final Future<AppServices> Function()? bootstrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(previewSettingsProvider);
    return WidgetsApp(
      color: settings.prefs.palette.bg,
      title: kAppName,
      pageRouteBuilder: <T>(route, builder) => PageRouteBuilder<T>(
        settings: route,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(settings.textScale),
        ),
        child: UiScope(prefs: settings.prefs, child: child!),
      ),
      home: bootstrap == null
          ? const Gallery()
          : _Boot(
              bootstrap: bootstrap!,
              leftHanded: settings.prefs.leftHanded,
              onHand: (left) {
                final n = ref.read(previewSettingsProvider.notifier);
                if (left != settings.prefs.leftHanded) n.toggleLeftHanded();
              },
            ),
    );
  }
}

/// Starts the services, showing the name meanwhile and a plain message if
/// starting fails.
class _Boot extends StatefulWidget {
  const _Boot({
    required this.bootstrap,
    required this.leftHanded,
    required this.onHand,
  });

  final Future<AppServices> Function() bootstrap;
  final bool leftHanded;
  final ValueChanged<bool> onHand;

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  late final Future<AppServices> _future = widget.bootstrap().then((s) {
    // Apply the saved display choices once, as soon as they are known.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onHand(s.app.leftHanded),
    );
    return s;
  });

  @override
  Widget build(BuildContext context) {
    final p = UiScope.of(context).palette;
    return FutureBuilder<AppServices>(
      future: _future,
      builder: (context, snap) {
        final s = snap.data;
        if (s != null) {
          return PagdandiRoot(
            app: s.app,
            client: s.client,
            leftHanded: widget.leftHanded,
            onHand: widget.onHand,
          );
        }
        return ColoredBox(
          color: p.bg,
          child: Center(
            child: Text(
              snap.hasError
                  ? '$kAppName could not start. Restart the app.'
                  : kAppName,
              textAlign: TextAlign.center,
              style: TypeScale.display.copyWith(color: p.text),
            ),
          ),
        );
      },
    );
  }
}
