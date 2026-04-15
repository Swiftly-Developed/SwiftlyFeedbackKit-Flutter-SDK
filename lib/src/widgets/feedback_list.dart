import 'package:flutter/widgets.dart';

import '../i18n/feedbackkit_localizations.dart';
import '../models/feedback.dart' show FeedbackItem;
import '../models/vote_response.dart';
import '../state/feedbackkit_provider.dart';
import '../state/notifiers/feedback_list_notifier.dart';
import '../theme/feedbackkit_theme.dart';
import 'feedback_card.dart';

/// A scrollable list of feedback items.
class FeedbackList extends StatefulWidget {
  /// Callback when a feedback item is tapped.
  final void Function(FeedbackItem)? onFeedbackTap;

  /// Callback when a vote changes.
  final void Function(FeedbackItem, VoteResponse)? onVoteChange;

  /// Whether to load feedback automatically on mount.
  final bool autoLoad;

  /// Optional custom theme (uses provider theme by default).
  final FeedbackKitTheme? theme;

  /// Builder for empty state.
  final Widget Function(BuildContext)? emptyBuilder;

  /// Builder for error state.
  final Widget Function(BuildContext, Object)? errorBuilder;

  /// Builder for loading state.
  final Widget Function(BuildContext)? loadingBuilder;

  const FeedbackList({
    super.key,
    this.onFeedbackTap,
    this.onVoteChange,
    this.autoLoad = true,
    this.theme,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  State<FeedbackList> createState() => _FeedbackListState();
}

class _FeedbackListState extends State<FeedbackList> {
  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFeedback();
      });
    }
  }

  void _loadFeedback() {
    final context = FeedbackKitProvider.of(this.context);
    context.feedbackList.loadFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final providerContext = FeedbackKitProvider.of(context);
    final theme = widget.theme ?? providerContext.theme;

    return ListenableBuilder(
      listenable: providerContext.feedbackList,
      builder: (context, _) {
        final notifier = providerContext.feedbackList;

        switch (notifier.state) {
          case FeedbackListState.initial:
          case FeedbackListState.loading:
            return widget.loadingBuilder?.call(context) ??
                _buildLoading(theme);

          case FeedbackListState.error:
            return widget.errorBuilder?.call(context, notifier.error!) ??
                _buildError(theme, notifier.error!);

          case FeedbackListState.loaded:
            if (notifier.feedbackItems.isEmpty) {
              return widget.emptyBuilder?.call(context) ?? _buildEmpty(theme);
            }
            return _buildList(theme, notifier.feedbackItems);
        }
      },
    );
  }

  Widget _buildLoading(FeedbackKitTheme theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing * 4),
        child: Text(
          FeedbackKitLocalizations.t('feedback.list.loading'),
          style: TextStyle(
            color: theme.secondaryTextColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildError(FeedbackKitTheme theme, Object error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing * 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              FeedbackKitLocalizations.t('feedback.list.error'),
              style: TextStyle(
                color: theme.errorColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: theme.spacing),
            Text(
              error.toString(),
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: theme.spacing * 2),
            GestureDetector(
              onTap: _loadFeedback,
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
                  FeedbackKitLocalizations.t('feedback.list.error.retry'),
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(FeedbackKitTheme theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing * 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              FeedbackKitLocalizations.t('feedback.list.empty'),
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: theme.spacing),
            Text(
              FeedbackKitLocalizations.t('feedback.list.empty.description'),
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(FeedbackKitTheme theme, List<FeedbackItem> items) {
    return ListView.separated(
      padding: EdgeInsets.all(theme.spacing * 2),
      itemCount: items.length,
      separatorBuilder: (context, index) => SizedBox(height: theme.spacing * 2),
      itemBuilder: (context, index) {
        final feedback = items[index];
        return FeedbackCard(
          feedback: feedback,
          theme: theme,
          onTap: widget.onFeedbackTap != null
              ? () => widget.onFeedbackTap!(feedback)
              : null,
          onVoteChange: widget.onVoteChange != null
              ? (response) => widget.onVoteChange!(feedback, response)
              : null,
        );
      },
    );
  }
}
