import 'package:flutter/widgets.dart';

/// A tappable control with button or checkbox semantics.
///
/// A [GestureDetector] on its own is not announced as a button. [checked]
/// makes the control a checkbox instead.
class FeedbackKitPressable extends StatelessWidget {
  /// The visual contents. They are hidden from the semantics tree; [label]
  /// is the accessible name.
  final Widget child;

  /// Called when the control is activated. A null callback disables it.
  final VoidCallback? onTap;

  /// Accessible name.
  final String label;

  /// Checkbox state. Null leaves the control a button.
  final bool? checked;

  /// Whether a button is the selected item in a group, such as a category chip.
  final bool selected;

  const FeedbackKitPressable({
    super.key,
    required this.child,
    required this.onTap,
    required this.label,
    this.checked,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: checked == null,
      checked: checked,
      selected: selected,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }
}
