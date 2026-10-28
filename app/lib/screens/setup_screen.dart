import 'package:core_common/core_common.dart';
import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/models/readiness.dart';
import 'package:pagdandi_app/permissions/permission_service.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/key_button.dart';
import 'package:pagdandi_app/widgets/screen_parts.dart';
import 'package:pagdandi_app/widgets/text_field_box.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// The first-run steps, in order. One decision per screen.
enum SetupStep {
  /// Which hand holds the phone.
  hand,

  /// What the group calls this person.
  name,

  /// Who gets the SOS.
  contacts,

  /// Location permission.
  location,

  /// Location with the screen off.
  background,

  /// SMS permission.
  sms,

  /// Notification permission.
  notifications,

  /// Keep the app running in the background.
  keepRunning,

  /// Summary.
  ready;

  /// The permission this step asks for, if it is a permission step.
  AppPermission? get permission => switch (this) {
    location => AppPermission.location,
    background => AppPermission.backgroundLocation,
    sms => AppPermission.sms,
    notifications => AppPermission.notifications,
    _ => null,
  };

  /// Screen title.
  String get title => switch (this) {
    hand => 'Which hand holds your phone?',
    name => 'What should your group call you?',
    contacts => 'Emergency contacts',
    location => 'Allow location',
    background => 'Allow location all the time',
    sms => 'Allow sending SMS',
    notifications => 'Allow notifications',
    keepRunning => 'Keep $kAppName running',
    ready => 'You are ready',
  };

  /// The one-line reason this step exists.
  String get reason => switch (this) {
    hand => 'The main key sits under your thumb.',
    name => 'Shown on the map, in alerts and in the SOS text.',
    contacts => 'An SOS goes by SMS to these people. Add at least one.',
    location =>
      'Your position reaches your group and your SOS without network.',
    background => 'Tracking and SOS must keep working when the screen is off.',
    sms => 'An SOS cannot be sent without it.',
    notifications => 'Shows the trek is running and warns if it stops.',
    keepRunning =>
      'Some phones stop apps to save battery. Allow $kAppName to keep running.',
    ready => 'Anything not confirmed stays marked, so you know.',
  };

  /// What stops working when a permission is refused.
  String get consequence => switch (this) {
    location => 'Without it there is no position for your SOS.',
    background => 'Without it tracking can stop when the screen turns off.',
    sms => 'Without it an SOS cannot be sent.',
    notifications => 'Without it you will not see that the trek is running.',
    _ => '',
  };
}

/// First-run setup: contacts for an SOS, the permissions that make tracking
/// and SMS work, and the battery setting that keeps the app alive.
class SetupScreen extends StatefulWidget {
  /// Creates the screen.
  const SetupScreen({
    required this.contacts,
    required this.name,
    required this.leftHanded,
    required this.readiness,
    required this.onHand,
    required this.onName,
    required this.onAddContact,
    required this.onRemoveContact,
    required this.onRequest,
    required this.onOpenSettings,
    required this.onFinish,
    this.initialStep = 0,
    this.onStep,
    this.batteryGuide = const [],
    super.key,
  });

  /// Saved contacts.
  final List<String> contacts;

  /// Saved name.
  final String name;

  /// Current handedness.
  final bool leftHanded;

  /// Current readiness, for the permission state and the summary.
  final Readiness readiness;

  /// Handedness chosen (true = left).
  final ValueChanged<bool> onHand;

  /// Name edited.
  final ValueChanged<String> onName;

  /// Add a contact; false when the number is not valid.
  final Future<bool> Function(String number) onAddContact;

  /// Remove a contact.
  final ValueChanged<String> onRemoveContact;

  /// Ask for a permission; true when granted.
  final Future<bool> Function(AppPermission permission) onRequest;

  /// Open the system settings page.
  final VoidCallback onOpenSettings;

  /// Setup finished.
  final VoidCallback onFinish;

  /// The step to start at (a saved one), kept inside the range.
  final int initialStep;

  /// The step changed; save it so Setup resumes there.
  final ValueChanged<int>? onStep;

  /// What to do so the phone does not stop the trek (brand specific).
  final List<String> batteryGuide;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late int _index = widget.initialStep.clamp(0, SetupStep.values.length - 1);
  late String _name = widget.name;
  var _number = '';
  String? _numberError;
  final _refused = <SetupStep>{};
  late bool _left = widget.leftHanded;

  SetupStep get _step => SetupStep.values[_index];

  void _go(int delta) {
    setState(() {
      _index = (_index + delta).clamp(0, SetupStep.values.length - 1);
    });
    widget.onStep?.call(_index);
  }

  bool _granted(SetupStep step) {
    final r = widget.readiness;
    return switch (step) {
      SetupStep.location => r.location,
      SetupStep.background => r.backgroundLocation,
      SetupStep.sms => r.sms,
      SetupStep.notifications => r.notifications,
      _ => false,
    };
  }

  Future<void> _ask(SetupStep step) async {
    final ok = await widget.onRequest(step.permission!);
    if (!mounted) return;
    setState(() => ok ? _refused.remove(step) : _refused.add(step));
  }

  Future<void> _add() async {
    final ok = await widget.onAddContact(_number);
    if (!mounted) return;
    setState(
      () => _numberError = ok
          ? null
          : 'Enter a phone number with country code, like +91…',
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    final step = _step;
    final total = SetupStep.values.length;

    final controls = _controls(step);
    // System Back steps back through Setup; on the first step it leaves.
    return PopScope<void>(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(-1);
      },
      child: ScreenFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 18, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: prefs.target(56),
                    height: prefs.target(56),
                    child: _index == 0
                        ? null
                        : Semantics(
                            button: true,
                            label: 'Back',
                            excludeSemantics: true,
                            onTap: () => _go(-1),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _go(-1),
                              child: Center(
                                child: AppIconView(AppIcon.back, color: p.text),
                              ),
                            ),
                          ),
                  ),
                  const Spacer(),
                  Text(
                    '${_index + 1} of $total',
                    style: TypeScale.label.copyWith(color: p.text2),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  children: [
                    Container(height: 4, color: p.hairline),
                    FractionallySizedBox(
                      widthFactor: (_index + 1) / total,
                      child: Container(height: 4, color: p.signal),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topLeft,
                  children: [...previous, ?current],
                ),
                duration: prefs.reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(step),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TypeScale.display.copyWith(color: p.text),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.reason,
                          style: TypeScale.body.copyWith(color: p.text2),
                        ),
                        const SizedBox(height: 18),
                        _content(step),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ThumbPanel(children: controls),
          ],
        ),
      ),
    );
  }

  Widget _content(SetupStep step) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    switch (step) {
      case SetupStep.hand:
        return Row(
          children: [
            Expanded(
              child: KeyButton(
                label: 'Left',
                icon: _left ? AppIcon.check : null,
                onPressed: () {
                  setState(() => _left = true);
                  widget.onHand(true);
                },
              ),
            ),
            SizedBox(width: prefs.space(12)),
            Expanded(
              child: KeyButton(
                label: 'Right',
                icon: _left ? null : AppIcon.check,
                onPressed: () {
                  setState(() => _left = false);
                  widget.onHand(false);
                },
              ),
            ),
          ],
        );
      case SetupStep.name:
        return TextFieldBox(
          label: 'Your name',
          initial: _name,
          hint: 'e.g. Akash',
          onChanged: (v) {
            setState(() => _name = v);
            widget.onName(v);
          },
        );
      case SetupStep.contacts:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in widget.contacts)
              Container(
                constraints: BoxConstraints(minHeight: prefs.target(56)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c,
                        style: TypeScale.title.copyWith(color: p.text),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Remove $c',
                      excludeSemantics: true,
                      onTap: () => widget.onRemoveContact(c),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onRemoveContact(c),
                        child: SizedBox(
                          width: prefs.target(48),
                          height: prefs.target(48),
                          child: Center(
                            child: AppIconView(AppIcon.x, color: p.text2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            TextFieldBox(
              label: 'Phone number',
              hint: '+91 98765 43210',
              keyboardType: TextInputType.phone,
              onChanged: (v) => _number = v,
            ),
            if (_numberError != null) ...[
              const SizedBox(height: 6),
              Text(
                _numberError!,
                style: TypeScale.label.copyWith(color: p.warn),
              ),
            ],
            const SizedBox(height: 12),
            KeyButton(
              label: 'Add',
              icon: AppIcon.check,
              compact: true,
              onPressed: _add,
            ),
          ],
        );
      case SetupStep.location ||
          SetupStep.background ||
          SetupStep.sms ||
          SetupStep.notifications:
        final granted = _granted(step);
        final refused = _refused.contains(step) && !granted;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconView(
                  granted ? AppIcon.ok : AppIcon.warn,
                  color: granted ? p.ok : p.text3,
                ),
                const SizedBox(width: 10),
                Text(
                  granted ? 'Allowed' : 'Not allowed yet',
                  style: TypeScale.body.copyWith(
                    color: granted ? p.ok : p.text2,
                  ),
                ),
              ],
            ),
            if (refused) ...[
              const SizedBox(height: 12),
              Text(
                step.consequence,
                style: TypeScale.body.copyWith(color: p.warn),
              ),
            ],
          ],
        );
      case SetupStep.keepRunning:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < widget.batteryGuide.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${i + 1}. ${widget.batteryGuide[i]}',
                  style: TypeScale.body.copyWith(color: p.text),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '$kAppName cannot check this itself, so it stays marked '
              '"not confirmed".',
              style: TypeScale.label.copyWith(color: p.text2),
            ),
          ],
        );
      case SetupStep.ready:
        return Column(
          children: [
            for (final r in widget.readiness.rows)
              Semantics(
                container: true,
                label: '${r.label}: ${r.stateText}',
                excludeSemantics: true,
                child: Container(
                  constraints: BoxConstraints(minHeight: prefs.target(52)),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: p.hairline,
                        width: p.lineScale,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      AppIconView(
                        switch (r.status) {
                          ReadyStatus.ok => AppIcon.ok,
                          ReadyStatus.warn => AppIcon.warn,
                          ReadyStatus.critical => AppIcon.octagon,
                        },
                        color: r.status == ReadyStatus.ok ? p.ok : p.warn,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          r.label,
                          style: TypeScale.body.copyWith(color: p.text),
                        ),
                      ),
                      Text(
                        r.stateText,
                        style: TypeScale.label.copyWith(
                          color: r.status == ReadyStatus.ok ? p.ok : p.warn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
    }
  }

  List<Widget> _controls(SetupStep step) {
    void noop() {}
    switch (step) {
      case SetupStep.hand:
        return [
          KeyButton(
            label: 'Continue',
            variant: KeyVariant.primary,
            onPressed: () => _go(1),
          ),
        ];
      case SetupStep.name:
        final ok = _name.trim().isNotEmpty;
        return [
          KeyButton(
            label: 'Continue',
            sub: ok ? null : 'Enter a name',
            variant: KeyVariant.primary,
            enabled: ok,
            onPressed: ok ? () => _go(1) : noop,
          ),
        ];
      case SetupStep.contacts:
        final ok = widget.contacts.isNotEmpty;
        return [
          KeyButton(
            label: 'Continue',
            sub: ok ? null : 'Add at least one contact',
            variant: KeyVariant.primary,
            enabled: ok,
            onPressed: ok ? () => _go(1) : noop,
          ),
        ];
      case SetupStep.location ||
          SetupStep.background ||
          SetupStep.sms ||
          SetupStep.notifications:
        if (_granted(step)) {
          return [
            KeyButton(
              label: 'Continue',
              variant: KeyVariant.primary,
              onPressed: () => _go(1),
            ),
          ];
        }
        final refused = _refused.contains(step);
        return [
          if (refused)
            KeyButton(
              label: 'Open settings',
              variant: KeyVariant.primary,
              onPressed: widget.onOpenSettings,
            )
          else
            KeyButton(
              label: 'Allow',
              variant: KeyVariant.primary,
              onPressed: () => _ask(step),
            ),
          KeyButton(
            label: refused ? 'Continue without it' : 'Skip',
            compact: true,
            onPressed: () => _go(1),
          ),
        ];
      case SetupStep.keepRunning:
        return [
          KeyButton(
            label: 'Open settings',
            variant: KeyVariant.primary,
            onPressed: widget.onOpenSettings,
          ),
          KeyButton(label: 'Skip', compact: true, onPressed: () => _go(1)),
        ];
      case SetupStep.ready:
        return [
          KeyButton(
            label: 'Finish',
            variant: KeyVariant.primary,
            onPressed: widget.onFinish,
          ),
        ];
    }
  }
}
