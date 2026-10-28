import 'package:flutter/widgets.dart';
import 'package:pagdandi_app/design/type_scale.dart';
import 'package:pagdandi_app/widgets/ui_scope.dart';

/// A 64 dp text field for stress use: big text, high contrast, labelled.
class TextFieldBox extends StatefulWidget {
  /// Creates a field.
  const TextFieldBox({
    required this.label,
    required this.onChanged,
    this.initial = '',
    this.hint,
    this.keyboardType = TextInputType.text,
    this.onSubmitted,
    this.maxLines = 1,
    super.key,
  });

  /// Spoken and visible label.
  final String label;

  /// Called on every change.
  final ValueChanged<String> onChanged;

  /// Starting text.
  final String initial;

  /// Shown while empty.
  final String? hint;

  /// Keyboard to show.
  final TextInputType keyboardType;

  /// Called when the keyboard's action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Lines; 1 for a single-line field.
  final int maxLines;

  @override
  State<TextFieldBox> createState() => _TextFieldBoxState();
}

class _TextFieldBoxState extends State<TextFieldBox> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  )..addListener(_changed);
  final _focus = FocusNode();

  void _changed() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = UiScope.of(context);
    final p = prefs.palette;
    final style = TypeScale.title.copyWith(color: p.text);
    return Semantics(
      label: widget.label,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TypeScale.label.copyWith(color: p.text2),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: BoxConstraints(minHeight: prefs.target(64)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.contour, width: p.lineScale),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (_controller.text.isEmpty && widget.hint != null)
                  Text(
                    widget.hint!,
                    style: style.copyWith(color: p.text3),
                  ),
                EditableText(
                  controller: _controller,
                  focusNode: _focus,
                  style: style,
                  cursorColor: p.signal,
                  backgroundCursorColor: p.contour,
                  keyboardType: widget.keyboardType,
                  maxLines: widget.maxLines,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
