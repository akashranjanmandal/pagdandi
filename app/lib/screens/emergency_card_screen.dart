import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/app/app_controller.dart';
import 'package:pagdandi_app/design/icons.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/app_icon.dart';
import 'package:pagdandi_app/widgets/key_button.dart';
import 'package:pagdandi_app/widgets/screen_parts.dart';
import 'package:pagdandi_app/widgets/text_field_box.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// What a helper needs: blood group first, then allergies, medicines and who
/// to call. Large and unadorned. Editing is only offered when [readOnly] is
/// false (the lock-screen view cannot edit).
class EmergencyCardScreen extends StatefulWidget {
  /// Creates the screen.
  const EmergencyCardScreen({
    required this.card,
    required this.contacts,
    this.readOnly = false,
    this.onSave,
    this.onCall,
    this.onBack,
    super.key,
  });

  /// The card to show.
  final EmergencyCard card;

  /// Emergency contacts.
  final List<String> contacts;

  /// Lock-screen view: no editing.
  final bool readOnly;

  /// Saved from the edit view.
  final ValueChanged<EmergencyCard>? onSave;

  /// Call a contact. Without it no Call keys are shown.
  final ValueChanged<String>? onCall;

  /// Back pressed.
  final VoidCallback? onBack;

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  var _editing = false;
  late EmergencyCard _draft = widget.card;

  static String _blood(String v) => v.isEmpty ? 'not set' : v;

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    void noop() {}

    Widget block(String label, String value, String empty) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TypeScale.label.copyWith(color: p.text2)),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? empty : value,
            style: TypeScale.title.copyWith(
              color: value.isEmpty ? p.text3 : p.text,
            ),
          ),
        ],
      ),
    );

    final body = _editing
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFieldBox(
                label: 'Blood group',
                initial: _draft.bloodGroup,
                onChanged: (v) => _draft = EmergencyCard(
                  bloodGroup: v,
                  allergies: _draft.allergies,
                  medicines: _draft.medicines,
                ),
              ),
              const SizedBox(height: 14),
              TextFieldBox(
                label: 'Allergies',
                initial: _draft.allergies,
                onChanged: (v) => _draft = EmergencyCard(
                  bloodGroup: _draft.bloodGroup,
                  allergies: v,
                  medicines: _draft.medicines,
                ),
              ),
              const SizedBox(height: 14),
              TextFieldBox(
                label: 'Medicines',
                initial: _draft.medicines,
                onChanged: (v) => _draft = EmergencyCard(
                  bloodGroup: _draft.bloodGroup,
                  allergies: _draft.allergies,
                  medicines: v,
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                container: true,
                label: 'Blood group: ${_blood(widget.card.bloodGroup)}',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blood group',
                      style: TypeScale.label.copyWith(color: p.text2),
                    ),
                    Text(
                      widget.card.bloodGroup.isEmpty
                          ? 'Not set'
                          : widget.card.bloodGroup,
                      style: TypeScale.hero.copyWith(
                        color: widget.card.bloodGroup.isEmpty
                            ? p.text3
                            : p.text,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              block('Allergies', widget.card.allergies, 'None entered'),
              block('Medicines', widget.card.medicines, 'None entered'),
              Text(
                'Contacts',
                style: TypeScale.label.copyWith(color: p.text2),
              ),
              const SizedBox(height: 6),
              if (widget.contacts.isEmpty)
                Text(
                  'No contacts yet',
                  style: TypeScale.title.copyWith(color: p.text3),
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
                      if (widget.onCall != null)
                        Semantics(
                          button: true,
                          label: 'Call $c',
                          excludeSemantics: true,
                          onTap: () => widget.onCall!(c),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onCall!(c),
                            child: Container(
                              width: prefs.target(56),
                              height: prefs.target(56),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: p.contour,
                                  width: p.lineScale,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AppIconView(AppIcon.call, color: p.ok),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );

    return ScreenFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Text(
              'Emergency card',
              style: TypeScale.display.copyWith(color: p.text),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: body,
            ),
          ),
          ThumbPanel(
            children: [
              if (_editing) ...[
                KeyButton(
                  label: 'Save',
                  variant: KeyVariant.primary,
                  onPressed: () {
                    widget.onSave?.call(_draft);
                    setState(() => _editing = false);
                  },
                ),
                KeyButton(
                  label: 'Cancel',
                  compact: true,
                  onPressed: () => setState(() {
                    _draft = widget.card;
                    _editing = false;
                  }),
                ),
              ] else ...[
                if (widget.readOnly)
                  Text(
                    'Unlock to edit',
                    textAlign: TextAlign.center,
                    style: TypeScale.label.copyWith(color: p.text2),
                  )
                else
                  KeyButton(
                    label: 'Edit',
                    variant: KeyVariant.primary,
                    onPressed: () => setState(() {
                      _draft = widget.card;
                      _editing = true;
                    }),
                  ),
                KeyButton(
                  label: 'Back',
                  icon: AppIcon.back,
                  compact: true,
                  onPressed: widget.onBack ?? noop,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
