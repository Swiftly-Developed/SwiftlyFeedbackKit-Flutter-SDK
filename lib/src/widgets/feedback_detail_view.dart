import 'package:flutter/widgets.dart';

import '../api/comments_api.dart';
import '../i18n/feedbackkit_localizations.dart';
import '../models/comment.dart';
import '../models/feedback.dart' show FeedbackItem;
import '../models/vote_response.dart';
import '../state/feedbackkit_provider.dart';
import '../theme/feedbackkit_theme.dart';
import 'category_badge.dart';
import 'feedbackkit_direction.dart';
import 'feedbackkit_pressable.dart';
import 'status_badge.dart';
import 'vote_button.dart';

/// A detailed view of a feedback item with comments.
class FeedbackDetailView extends StatefulWidget {
  /// The feedback item to display.
  final FeedbackItem feedback;

  /// Callback when the vote state changes.
  final void Function(VoteResponse)? onVoteChange;

  /// Optional custom theme (uses provider theme by default).
  final FeedbackKitTheme? theme;

  const FeedbackDetailView({
    super.key,
    required this.feedback,
    this.onVoteChange,
    this.theme,
  });

  @override
  State<FeedbackDetailView> createState() => _FeedbackDetailViewState();
}

class _FeedbackDetailViewState extends State<FeedbackDetailView> {
  List<Comment>? _comments;
  bool _isLoadingComments = true;
  Object? _commentsError;
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
      _commentsError = null;
    });

    try {
      final context = FeedbackKitProvider.of(this.context);
      final comments = await context.client.comments.list(widget.feedback.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentsError = e;
          _isLoadingComments = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmittingComment) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final context = FeedbackKitProvider.of(this.context);
      final comment = await context.client.comments.create(
        widget.feedback.id,
        CreateCommentRequest(content: content),
      );
      if (mounted) {
        setState(() {
          _comments = [...?_comments, comment];
          _commentController.clear();
          _isSubmittingComment = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ??
        FeedbackKitProvider.maybeOf(context)?.theme ??
        const FeedbackKitTheme();

    return FeedbackKitDirection(
      child: Container(
        color: theme.backgroundColor,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(theme.spacing * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with badges
              Row(
                children: [
                  StatusBadge(status: widget.feedback.status, theme: theme),
                  SizedBox(width: theme.spacing),
                  CategoryBadge(
                    category: widget.feedback.category,
                    theme: theme,
                  ),
                  const Spacer(),
                  VoteButton(
                    feedback: widget.feedback,
                    onVoteChange: widget.onVoteChange,
                    theme: theme,
                  ),
                ],
              ),
              SizedBox(height: theme.spacing * 2),

              // Title
              Text(
                widget.feedback.title,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: theme.spacing * 2),

              // Description
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(theme.spacing * 2),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(theme.borderRadius),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Text(
                  widget.feedback.description,
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: theme.spacing * 2),

              // Meta info
              Text(
                '${FeedbackKitLocalizations.t('feedback.detail.submitted')} ${FeedbackKitLocalizations.relativeTime(widget.feedback.createdAt)}',
                style: TextStyle(
                  color: theme.secondaryTextColor,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: theme.spacing * 3),

              // Comments section
              Text(
                '${FeedbackKitLocalizations.t('feedback.detail.comments')} (${_comments?.length ?? widget.feedback.commentCount})',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: theme.spacing * 2),

              // Comment input
              _buildCommentInput(theme),
              SizedBox(height: theme.spacing * 2),

              // Comments list
              _buildComments(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentInput(FeedbackKitTheme theme) {
    return Container(
      padding: EdgeInsets.all(theme.spacing * 2),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditableText(
            controller: _commentController,
            focusNode: _commentFocusNode,
            style: TextStyle(
              color: theme.textColor,
              fontSize: 14,
            ),
            cursorColor: theme.primaryColor,
            backgroundCursorColor: theme.borderColor,
            maxLines: 3,
          ),
          SizedBox(height: theme.spacing),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FeedbackKitPressable(
              onTap: _isSubmittingComment ? null : _submitComment,
              label: FeedbackKitLocalizations.t(
                _isSubmittingComment
                    ? 'feedback.detail.comments.sending'
                    : 'feedback.detail.comments.add',
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isSubmittingComment ? 0.5 : 1.0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing * 2,
                    vertical: theme.spacing,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(theme.borderRadius / 2),
                  ),
                  child: Text(
                    FeedbackKitLocalizations.t(
                      _isSubmittingComment
                          ? 'feedback.detail.comments.sending'
                          : 'feedback.detail.comments.add',
                    ),
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComments(FeedbackKitTheme theme) {
    if (_isLoadingComments) {
      return Padding(
        padding: EdgeInsets.all(theme.spacing * 2),
        child: Text(
          FeedbackKitLocalizations.t('feedback.detail.comments.loading'),
          style: TextStyle(
            color: theme.secondaryTextColor,
            fontSize: 14,
          ),
        ),
      );
    }

    if (_commentsError != null) {
      return Padding(
        padding: EdgeInsets.all(theme.spacing * 2),
        child: Column(
          children: [
            Text(
              FeedbackKitLocalizations.t('feedback.detail.comments.error'),
              style: TextStyle(
                color: theme.errorColor,
                fontSize: 14,
              ),
            ),
            SizedBox(height: theme.spacing),
            FeedbackKitPressable(
              onTap: _loadComments,
              label: FeedbackKitLocalizations.t('feedback.list.error.retry'),
              child: Text(
                FeedbackKitLocalizations.t('feedback.list.error.retry'),
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_comments == null || _comments!.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(theme.spacing * 2),
        child: Text(
          FeedbackKitLocalizations.t('feedback.detail.comments.empty'),
          style: TextStyle(
            color: theme.secondaryTextColor,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      children:
          _comments!.map((comment) => _buildComment(theme, comment)).toList(),
    );
  }

  Widget _buildComment(FeedbackKitTheme theme, Comment comment) {
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing * 2),
      child: Container(
        padding: EdgeInsets.all(theme.spacing * 2),
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(theme.borderRadius),
          border: Border.all(
            color: comment.isTeamMember
                ? theme.primaryColor.withOpacity(0.3)
                : theme.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  comment.authorName ??
                      FeedbackKitLocalizations.t('feedback.detail.anonymous'),
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (comment.isTeamMember) ...[
                  SizedBox(width: theme.spacing),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: theme.spacing / 2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      FeedbackKitLocalizations.t('comment.author.team'),
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  FeedbackKitLocalizations.relativeTime(comment.createdAt),
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: theme.spacing),
            Text(
              comment.content,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
