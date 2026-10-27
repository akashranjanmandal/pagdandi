import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/motion.dart';
import 'package:pagdandi_app/widgets/key_style.dart';

/// The physical key shape: a dark lower edge band with the face on top.
/// Pressing drops the face onto the edge (120 ms), like a real key.
class KeyBody extends StatelessWidget {
  /// Creates a key body.
  const KeyBody({
    required this.style,
    required this.radius,
    required this.pressed,
    required this.child,
    this.height,
    this.minHeight,
    this.edge = 4,
    this.dashed = false,
    super.key,
  });

  /// Colours.
  final KeyStyle style;

  /// Corner radius.
  final double radius;

  /// Whether the key is being pressed.
  final bool pressed;

  /// Content drawn on the face.
  final Widget child;

  /// Fixed height, or null to fill the parent (or grow, see [minHeight]).
  final double? height;

  /// When set (and [height] is null) the key is at least this tall and grows
  /// with its content, so larger text never overflows or gets clipped.
  final double? minHeight;

  /// Thickness of the lower edge when resting.
  final double edge;

  /// Dashed look for disabled keys (no edge).
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final face = DecoratedBox(
      key: const Key('key-face'),
      decoration: BoxDecoration(
        color: dashed ? const Color(0x00000000) : style.face,
        borderRadius: r,
        border: Border.all(color: style.rim),
      ),
      child: child,
    );
    final edgeLayer = dashed
        ? const SizedBox.shrink()
        : DecoratedBox(
            decoration: BoxDecoration(color: style.edge, borderRadius: r),
          );

    if (minHeight != null && height == null) {
      // Grows with content: the face sizes the key, the edge fills behind it.
      final lift = dashed ? 0.0 : edge;
      return Stack(
        children: [
          if (!dashed) Positioned.fill(child: edgeLayer),
          AnimatedContainer(
            duration: Motion.fast,
            curve: Motion.enter,
            constraints: BoxConstraints(minHeight: minHeight! - lift),
            margin: EdgeInsets.only(
              top: dashed ? 0 : (pressed ? edge - 1 : 0),
              bottom: dashed ? 0 : (pressed ? 1 : lift),
            ),
            child: face,
          ),
        ],
      );
    }

    final lift = dashed ? 0.0 : (pressed ? 1.0 : edge);
    final body = Stack(
      children: [
        if (!dashed) Positioned.fill(child: edgeLayer),
        AnimatedPositioned(
          duration: Motion.fast,
          curve: Motion.enter,
          left: 0,
          right: 0,
          top: dashed ? 0 : (pressed ? edge - 1 : 0),
          bottom: lift,
          child: face,
        ),
      ],
    );
    return height == null ? body : SizedBox(height: height, child: body);
  }
}
