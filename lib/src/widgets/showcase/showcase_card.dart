import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../i18n/feedbackkit_localizations.dart';
import '../../models/feedback.dart' show FeedbackItem;
import '../../models/vote_response.dart';
import '../../state/feedbackkit_provider.dart';
import '../../theme/feedbackkit_theme.dart';
import 'semantics_hints.dart';
import 'showcase_contrast.dart';
import 'showcase_footer.dart';
import 'showcase_options.dart';
import 'showcase_status_eyebrow.dart';
import 'showcase_vote_capsule.dart';
import 'vote_presentation.dart';

/// One request on the Showcase list: status, the full title and description,
/// category and comment count, and the vote control.
///
/// Votes update the provider's list optimistically and roll back with a
/// message when the server refuses.
class ShowcaseCard extends StatefulWidget {
  /// The request shown.
  final FeedbackItem feedback;

  /// Which parts of the card are shown.
  final ShowcaseOptions options;

  /// Supplies the status colours.
  final FeedbackKitTheme kitTheme;

  /// Opens the request. Null makes the card inert.
  final VoidCallback? onTap;

  /// Called after the server confirms a vote change.
  final void Function(VoteResponse)? onVoteChange;

  const ShowcaseCard({
    super.key,
    required this.feedback,
    required this.options,
    required this.kitTheme,
    this.onTap,
    this.onVoteChange,
  });

  @override
  State<ShowcaseCard> createState() => _ShowcaseCardState();
}

class _ShowcaseCardState extends State<ShowcaseCard> {
  bool _isVoting = false;

  Future<void> _toggleVote() async {
    if (_isVoting) return;
    final kit = FeedbackKitProvider.of(context);
    if (!kit.isInitialized) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final before = widget.feedback;
    final list = kit.feedbackList;

    setState(() => _isVoting = true);
    list.updateFeedback(
      before.copyWith(
        hasVoted: !before.hasVoted,
        voteCount: before.hasVoted
            ? (before.voteCount - 1).clamp(0, before.voteCount)
            : before.voteCount + 1,
      ),
    );

    VoteResponse? response;
    try {
      response = await kit.votes.toggle(before.id, hasVoted: before.hasVoted);
    } catch (_) {
      // Any failure takes the rollback path below, which tells the reader.
      response = null;
    }

    final current = list.getFeedback(before.id);
    if (response != null) {
      if (current != null) {
        list.updateFeedback(
          current.copyWith(
            hasVoted: response.hasVoted,
            voteCount: response.voteCount,
          ),
        );
      }
      widget.onVoteChange?.call(response);
    } else {
      if (current != null) {
        list.updateFeedback(
          current.copyWith(
            hasVoted: before.hasVoted,
            voteCount: before.voteCount,
          ),
        );
      }
      messenger?.showSnackBar(
        SnackBar(content: Text(FeedbackKitLocalizations.t('feedback.vote.error'))),
      );
    }
    if (mounted) setState(() => _isVoting = false);
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.feedback;
    final options = widget.options;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final cardColor = theme.cardTheme.color ?? scheme.surfaceContainerLow;

    final statusColor = widget.kitTheme.statusColors.forStatus(feedback.status);
    final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final glyphColor =
        ShowcaseContrast.ensure(statusColor, cardColor, ShowcaseContrast.graphic);
    final eyebrowColor = highContrast
        ? scheme.onSurface
        : ShowcaseContrast.ensure(statusColor, cardColor, ShowcaseContrast.text);

    final presentation = VotePresentation.resolve(
      showVoteCount: options.showVoteCount,
      isSkeleton: false,
      canVote: feedback.status.canVote,
      hasVoted: feedback.hasVoted,
      allowUndoVote: options.allowUndoVote,
    );
    final showComments = options.showCommentCount && feedback.commentCount > 0;

    final vote = presentation == VotePresentation.hidden
        ? null
        : ShowcaseVoteCapsule(
            presentation: presentation,
            voteCount: feedback.voteCount,
            onPressed: _toggleVote,
          );
    final hasFooter = options.showCategoryBadge || showComments || vote != null;

    final hints = widget.onTap == null
        ? (hint: null, onTapHint: null)
        : resolveSemanticsHints(
            hintKey: 'accessibility.viewDetails',
            tapHintKey: 'accessibility.viewDetails.tapHint',
          );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: _semanticsLabel(presentation, showComments),
      hint: hints.hint,
      onTapHint: hints.onTapHint,
      onTap: widget.onTap,
      customSemanticsActions: presentation.isInteractive
          ? {
              CustomSemanticsAction(
                label: FeedbackKitLocalizations.t(
                  feedback.hasVoted ? 'accessibility.unvote.action' : 'button.vote',
                ),
              ): _toggleVote,
            }
          : null,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          excludeFromSemantics: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (options.showStatusBadge) ...[
                        ShowcaseStatusEyebrow(
                          status: feedback.status,
                          glyphColor: glyphColor,
                          textColor: eyebrowColor,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        feedback.title,
                        style: text.titleLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (feedback.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          feedback.description,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasFooter) ...[
                  const SizedBox(height: 8),
                  ShowcaseFooter(
                    category: options.showCategoryBadge ? feedback.category : null,
                    commentCount: showComments ? feedback.commentCount : null,
                    vote: vote,
                  ),
                ] else
                  const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Status, title, description, category, comments, then votes and their
  /// state. Hidden parts are left out.
  String _semanticsLabel(VotePresentation presentation, bool showComments) {
    final feedback = widget.feedback;
    final options = widget.options;
    final parts = <String>[
      if (options.showStatusBadge) feedback.status.displayName,
      feedback.title,
      if (feedback.description.isNotEmpty) feedback.description,
      if (options.showCategoryBadge) feedback.category.displayName,
      if (showComments)
        FeedbackKitLocalizations.plural(
          'accessibility.comment.count',
          feedback.commentCount,
        ),
      if (presentation != VotePresentation.hidden)
        FeedbackKitLocalizations.plural(
          'accessibility.vote.count',
          feedback.voteCount,
        ),
      if (presentation.semanticsValueKey != null)
        FeedbackKitLocalizations.t(presentation.semanticsValueKey!),
    ];
    return parts.join(', ');
  }
}
