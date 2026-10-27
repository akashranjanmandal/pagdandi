import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/shape.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/key_body.dart';
import 'package:pagdandi_app/widgets/key_style.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// State of the push-to-talk key.
enum PttState {
  /// Ready.
  idle,

  /// This phone is talking.
  talking,

  /// A friend is talking to us.
  receiving,

  /// Channel busy: someone else holds the floor.
  busy,
}

/// The big orange talk key with an inner bezel and the quick-messages hint.
/// 104 dp tall, scaled in glove mode. Hold to talk.
class PttKey extends StatefulWidget {
  /// Creates the key.
  const PttKey({
    required this.state,
    required this.onTalkStart,
    required this.onTalkEnd,
    this.speaker = 'Rahul',
    super.key,
  });

  /// Current state.
  final PttState state;

  /// Hold started.
  final VoidCallback onTalkStart;

  /// Hold ended.
  final VoidCallback onTalkEnd;

  /// Who is talking while [PttState.receiving] or [PttState.busy].
  final String speaker;

  @override
  State<PttKey> createState() => _PttKeyState();
}

class _PttKeyState extends State<PttKey> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    final s = widget.state;
    final orange = s == PttState.idle || s == PttState.talking;
    final style = orange
        ? KeyStyle.signal(p)
        : KeyStyle(
            face: p.raised,
            rim: s == PttState.receiving ? p.nav : p.text3,
            edge: const Color(0xFF07090A),
            content: s == PttState.busy ? p.text2 : p.text,
          );
    final fg = style.content;
    final label = switch (s) {
      PttState.idle => 'Hold to talk',
      PttState.talking => 'Talking',
      PttState.receiving => widget.speaker,
      PttState.busy => '${widget.speaker} is talking',
    };
    return Semantics(
      button: true,
      label: s == PttState.idle ? 'Hold to talk' : label,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          if (s == PttState.busy) return;
          setState(() => _down = true);
          widget.onTalkStart();
        },
        onPointerUp: (_) {
          if (!_down) return;
          setState(() => _down = false);
          widget.onTalkEnd();
        },
        onPointerCancel: (_) {
          if (!_down) return;
          setState(() => _down = false);
          widget.onTalkEnd();
        },
        child: KeyBody(
          height: prefs.target(104),
          style: style,
          radius: 24,
          edge: 6,
          pressed: _down || s == PttState.talking,
          dashed: s == PttState.busy,
          child: Stack(
            children: [
              if (orange || s == PttState.receiving)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Radii.hold - 1),
                        border: Border.all(
                          color: orange
                              ? const Color(0x38000000)
                              : p.nav.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (s == PttState.idle)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppIconView(
                            AppIcon.up,
                            color: Color(0xC7000000),
                            size: 14,
                          ),
                          Text(
                            'quick msgs',
                            style: TypeScale.caption.copyWith(
                              color: const Color(0xC7000000),
                            ),
                          ),
                        ],
                      ),
                    if (s == PttState.talking || s == PttState.receiving)
                      _Wave(
                        color: s == PttState.receiving ? p.nav : fg,
                        live: !prefs.reduceMotion,
                      )
                    else
                      AppIconView(
                        AppIcon.mic,
                        color: fg,
                        size: s == PttState.busy ? 24 : 30,
                      ),
                    Text(
                      label,
                      style: TypeScale.body.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w500,
                        fontSize: s == PttState.busy ? 13 : 16,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live waveform: only animates while something is actually being said.
class _Wave extends StatefulWidget {
  const _Wave({required this.color, required this.live});

  final Color color;
  final bool live;

  @override
  State<_Wave> createState() => _WaveState();
}

class _WaveState extends State<_Wave> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.live) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 28,
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: 4,
              height:
                  6 + 20 * ((_c.value + i * 0.17) % 1.0 * (i.isEven ? 1 : 0.7)),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
