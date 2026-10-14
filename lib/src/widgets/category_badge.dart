import 'package:flutter/widgets.dart';

import '../models/feedback_category.dart';
import '../state/feedbackkit_provider.dart';
import '../theme/feedbackkit_theme.dart';
import 'feedbackkit_direction.dart';

/// A badge displaying a feedback category.
class CategoryBadge extends StatelessWidget {
  /// The category to display.
  final FeedbackCategory category;

  /// Optional custom theme (uses provider theme by default).
  final FeedbackKitTheme? theme;

  const CategoryBadge({
    super.key,
    required this.category,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ??
        FeedbackKitProvider.maybeOf(context)?.theme ??
        const FeedbackKitTheme();
    final color = effectiveTheme.categoryColors.forCategory(category);

    return FeedbackKitDirection(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: effectiveTheme.spacing,
          vertical: effectiveTheme.spacing / 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(effectiveTheme.borderRadius / 2),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          category.displayName,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
