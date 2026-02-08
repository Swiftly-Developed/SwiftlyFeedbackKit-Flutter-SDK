import 'package:flutter/widgets.dart';

import '../models/feedback.dart' show FeedbackItem;
import '../models/vote_response.dart';
import '../state/feedbackkit_provider.dart';
import '../theme/feedbackkit_theme.dart';
import 'category_badge.dart';
import 'status_badge.dart';
import 'vote_button.dart';

/// A card displaying a feedback item.
class FeedbackCard extends StatelessWidget {
  /// The feedback item to display.
  final FeedbackItem feedback;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the vote state changes.
  final void Function(VoteResponse)? onVoteChange;

  /// Optional custom theme (uses provider theme by default).
  final FeedbackKitTheme? theme;

  const FeedbackCard({
    super.key,
    required this.feedback,
    this.onTap,
    this.onVoteChange,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTheme =
        theme ?? FeedbackKitProvider.maybeOf(context)?.theme ?? const FeedbackKitTheme();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(effectiveTheme.spacing * 2),
        decoration: BoxDecoration(
          color: effectiveTheme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(effectiveTheme.borderRadius),
          border: Border.all(color: effectiveTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges row
            Row(
              children: [
                StatusBadge(status: feedback.status, theme: effectiveTheme),
                SizedBox(width: effectiveTheme.spacing),
                CategoryBadge(category: feedback.category, theme: effectiveTheme),
                const Spacer(),
                VoteButton(
                  feedback: feedback,
                  size: VoteButtonSize.small,
                  onVoteChange: onVoteChange,
                  theme: effectiveTheme,
                ),
              ],
            ),
            SizedBox(height: effectiveTheme.spacing * 1.5),

            // Title
            Text(
              feedback.title,
              style: TextStyle(
                color: effectiveTheme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: effectiveTheme.spacing),

            // Description
            Text(
              feedback.description,
              style: TextStyle(
                color: effectiveTheme.secondaryTextColor,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: effectiveTheme.spacing * 1.5),

            // Meta info
            Row(
              children: [
                Text(
                  '${feedback.commentCount} comment${feedback.commentCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: effectiveTheme.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(feedback.createdAt),
                  style: TextStyle(
                    color: effectiveTheme.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
