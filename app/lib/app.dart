import 'package:core_common/core_common.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagdandi_app/preview/gallery.dart';
import 'package:pagdandi_app/preview/preview_settings.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Root widget. The preview build opens a gallery of the approved screens;
/// product navigation replaces it as milestones land.
class PagdandiApp extends ConsumerWidget {
  /// Creates the app.
  const PagdandiApp({super.key});

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
      home: const Gallery(),
    );
  }
}
