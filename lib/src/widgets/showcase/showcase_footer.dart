import 'package:flutter/material.dart';

import '../../i18n/feedbackkit_localizations.dart';
import '../../models/feedback_category.dart';
import 'category_icon.dart';

/// The bottom row of a Showcase card: facts on the leading side, the vote
/// control on the trailing side.
///
/// When the two do not fit on one line the vote control moves below the
/// facts, leading-aligned, so a long category name or a large text size
/// never squeezes or truncates the count.
class ShowcaseFooter extends StatelessWidget {
  /// The category fact, or null to hide it.
  final FeedbackCategory? category;

  /// The comment-count fact, or null to hide it.
  final int? commentCount;

  /// The vote control, or null to hide it.
  final Widget? vote;

  const ShowcaseFooter({
    super.key,
    this.category,
    this.commentCount,
    this.vote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.bodyMedium?.copyWith(color: color);

    final facts = <Widget>[
      if (category != null)
        _Fact(
          icon: showcaseCategoryIcon(category!),
          text: category!.displayName,
          style: style,
          color: color,
        ),
      if (commentCount != null)
        _Fact(
          icon: Icons.chat_bubble_outline,
          text: FeedbackKitLocalizations.formatCount(commentCount!),
          style: style,
          color: color,
        ),
    ];

    if (facts.isEmpty) {
      return Align(alignment: AlignmentDirectional.centerEnd, child: vote);
    }

    final factRow = ExcludeSemantics(
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: facts,
      ),
    );
    if (vote == null) return factRow;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [factRow, vote!],
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle? style;
  final Color color;

  const _Fact({
    required this.icon,
    required this.text,
    required this.style,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color, applyTextScaling: true),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
