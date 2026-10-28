import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pagdandi_app/app.dart';
import 'package:pagdandi_app/app/services.dart';
// The headless core's library must be part of the program so its
// `@pragma('vm:entry-point')` function exists for the foreground service to
// launch; it is never called from here.
// ignore: unused_import
import 'package:pagdandi_app/core/trek_core_main.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PagdandiApp(bootstrap: bootstrapServices)));
}
