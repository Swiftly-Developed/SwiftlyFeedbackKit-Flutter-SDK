import 'package:flutter/widgets.dart';

import '../i18n/feedbackkit_localizations.dart';
import '../models/feedback.dart' show FeedbackItem;
import '../models/vote_response.dart';
import '../state/feedbackkit_provider.dart';
import '../theme/feedbackkit_theme.dart';
import 'category_badge.dart';
import 'feedbackkit_direction.dart';
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
    final effectiveTheme = theme ??
        FeedbackKitProvider.maybeOf(context)?.theme ??
        const FeedbackKitTheme();

    return FeedbackKitDirection(
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        button: onTap != null,
        enabled: onTap != null,
        label: feedback.title,
        child: GestureDetector(
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
                    CategoryBadge(
                      category: feedback.category,
                      theme: effectiveTheme,
                    ),
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
                ExcludeSemantics(
                  child: Text(
                    feedback.title,
                    style: TextStyle(
                      color: effectiveTheme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                      FeedbackKitLocalizations.commentCountLabel(
                        feedback.commentCount,
                      ),
                      style: TextStyle(
                        color: effectiveTheme.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      FeedbackKitLocalizations.relativeTime(feedback.createdAt),
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
        ),
      ),
    );
  }
}
