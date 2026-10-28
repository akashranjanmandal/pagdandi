import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/key_button.dart';
import 'package:pagdandi_app/widgets/screen_parts.dart';
import 'package:pagdandi_app/widgets/text_field_box.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// Add and remove the people an SOS goes to.
class ContactsScreen extends StatefulWidget {
  /// Creates the screen.
  const ContactsScreen({
    required this.contacts,
    required this.onAdd,
    required this.onRemove,
    this.onDone,
    super.key,
  });

  /// Saved contacts.
  final List<String> contacts;

  /// Add a number; false when it is not valid.
  final Future<bool> Function(String number) onAdd;

  /// Remove a number.
  final ValueChanged<String> onRemove;

  /// Done pressed.
  final VoidCallback? onDone;

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  var _number = '';
  var _bad = false;

  Future<void> _add() async {
    final ok = await widget.onAdd(_number);
    if (mounted) setState(() => _bad = !ok);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    void noop() {}
    return ScreenFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Text(
              'Emergency contacts',
              style: TypeScale.display.copyWith(color: p.text),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.contacts.isEmpty)
                    Text(
                      'An SOS has nobody to message yet.',
                      style: TypeScale.body.copyWith(color: p.warn),
                    ),
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
                            onTap: () => widget.onRemove(c),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.onRemove(c),
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
                  const SizedBox(height: 12),
                  TextFieldBox(
                    label: 'Phone number',
                    hint: '+91 98765 43210',
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => _number = v,
                  ),
                  if (_bad) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Enter a phone number with country code, like +91…',
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
              ),
            ),
          ),
          ThumbPanel(
            children: [
              KeyButton(
                label: 'Done',
                variant: KeyVariant.primary,
                onPressed: widget.onDone ?? noop,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
