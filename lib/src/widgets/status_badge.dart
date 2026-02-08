import 'package:flutter/widgets.dart';

import '../models/feedback_status.dart';
import '../state/feedbackkit_provider.dart';
import '../theme/feedbackkit_theme.dart';

/// A badge displaying a feedback status.
class StatusBadge extends StatelessWidget {
  /// The status to display.
  final FeedbackStatus status;

  /// Optional custom theme (uses provider theme by default).
  final FeedbackKitTheme? theme;

  const StatusBadge({
    super.key,
    required this.status,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTheme =
        theme ?? FeedbackKitProvider.maybeOf(context)?.theme ?? const FeedbackKitTheme();
    final color = effectiveTheme.statusColors.forStatus(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: effectiveTheme.spacing,
        vertical: effectiveTheme.spacing / 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(effectiveTheme.borderRadius / 2),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
