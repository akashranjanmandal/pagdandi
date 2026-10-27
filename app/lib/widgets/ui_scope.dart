import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/palette.dart';
import 'package:pagdandi_app/design/shape.dart';

/// User display preferences that every widget reads (never hard-coded).
@immutable
class UiPrefs {
  /// Creates preferences; all off by default.
  const UiPrefs({
    this.sunlight = false,
    this.glove = false,
    this.leftHanded = false,
    this.reduceMotion = false,
  });

  /// High-contrast sunlight palette.
  final bool sunlight;

  /// Larger targets and spacing.
  final bool glove;

  /// Mirrors the thumb zone.
  final bool leftHanded;

  /// Crossfades only; no looping animation.
  final bool reduceMotion;

  /// The active palette.
  Palette get palette => sunlight ? Palette.sunlight : Palette.normal;

  /// [size] scaled for glove mode.
  double target(double size) => Targets.scaled(size, glove: glove);

  /// [gap] scaled for glove mode.
  double space(double gap) => Targets.spaced(gap, glove: glove);

  /// Copy with changes.
  UiPrefs copyWith({
    bool? sunlight,
    bool? glove,
    bool? leftHanded,
    bool? reduceMotion,
  }) => UiPrefs(
    sunlight: sunlight ?? this.sunlight,
    glove: glove ?? this.glove,
    leftHanded: leftHanded ?? this.leftHanded,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is UiPrefs &&
      other.sunlight == sunlight &&
      other.glove == glove &&
      other.leftHanded == leftHanded &&
      other.reduceMotion == reduceMotion;

  @override
  int get hashCode => Object.hash(sunlight, glove, leftHanded, reduceMotion);
}

/// Provides [UiPrefs] to the widget tree.
class UiScope extends InheritedWidget {
  /// Creates a scope.
  const UiScope({required this.prefs, required super.child, super.key});

  /// The preferences.
  final UiPrefs prefs;

  /// The preferences in effect (defaults when no scope is present).
  static UiPrefs of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UiScope>()?.prefs ??
      const UiPrefs();

  @override
  bool updateShouldNotify(UiScope oldWidget) => prefs != oldWidget.prefs;
}
