import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Display preferences for the preview build: the same switches the real
/// Settings screen will have (sunlight, glove, handedness, text size).
@immutable
class PreviewSettings {
  /// Creates settings; everything off, normal text.
  const PreviewSettings({
    this.prefs = const UiPrefs(),
    this.largeText = false,
  });

  /// Palette, glove, handedness, motion.
  final UiPrefs prefs;

  /// Text scale 1.5 instead of 1.0.
  final bool largeText;

  /// The text scale factor in effect.
  double get textScale => largeText ? 1.5 : 1;

  /// Copy with changes.
  PreviewSettings copyWith({UiPrefs? prefs, bool? largeText}) =>
      PreviewSettings(
        prefs: prefs ?? this.prefs,
        largeText: largeText ?? this.largeText,
      );
}

/// Holds [PreviewSettings] for the whole UI.
class PreviewSettingsNotifier extends Notifier<PreviewSettings> {
  @override
  PreviewSettings build() => const PreviewSettings();

  /// Toggles sunlight mode.
  void toggleSunlight() => state = state.copyWith(
    prefs: state.prefs.copyWith(sunlight: !state.prefs.sunlight),
  );

  /// Toggles glove mode.
  void toggleGlove() => state = state.copyWith(
    prefs: state.prefs.copyWith(glove: !state.prefs.glove),
  );

  /// Toggles left-handed layout.
  void toggleLeftHanded() => state = state.copyWith(
    prefs: state.prefs.copyWith(leftHanded: !state.prefs.leftHanded),
  );

  /// Toggles reduce motion.
  void toggleReduceMotion() => state = state.copyWith(
    prefs: state.prefs.copyWith(reduceMotion: !state.prefs.reduceMotion),
  );

  /// Toggles text size 1.5x.
  void toggleLargeText() => state = state.copyWith(largeText: !state.largeText);
}

/// The settings provider.
final previewSettingsProvider =
    NotifierProvider<PreviewSettingsNotifier, PreviewSettings>(
      PreviewSettingsNotifier.new,
    );
