import 'package:flutter/widgets.dart';

import '../i18n/feedbackkit_localizations.dart';
import '../models/feedback.dart' show FeedbackItem;
import '../models/feedback_list_style.dart';
import '../models/vote_response.dart';
import '../state/feedback_list_controller.dart';
import '../state/feedbackkit_provider.dart';
import '../state/notifiers/feedback_list_notifier.dart';
import '../theme/feedbackkit_theme.dart';
import 'feedback_card.dart';
import 'feedbackkit_direction.dart';
import 'feedbackkit_pressable.dart';
import 'showcase/feedback_sort_filter_button.dart';
import 'showcase/showcase_feedback_list.dart';
import 'showcase/showcase_options.dart';

/// A scrollable list of feedback items.
///
/// The default [FeedbackListStyle.showcase] renders Material 3 cards with a
/// search bar, a Sort & Filter sheet and a vote button on each card. Pass
/// `listStyle: FeedbackListStyle.classic` (here or on [FeedbackKitProvider])
/// to keep the 1.x layout; the Showcase-only parameters do not affect it.
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

  /// Which presentation to render. When null, falls back to
  /// [FeedbackKitProvider.listStyle], which defaults to
  /// [FeedbackListStyle.showcase].
  final FeedbackListStyle? listStyle;

  /// Search, sort and filter state for the Showcase list. Pass one to drive
  /// the list from your own UI, such as a [FeedbackSortFilterButton] in an
  /// `AppBar`. When null, the list owns its state and remembers the reader's
  /// sort between launches. The Classic list ignores it.
  final FeedbackListController? controller;

  /// Show the search bar and Sort & Filter button above the Showcase cards.
  /// Set it to false when you place the controls in your own `AppBar`.
  final bool showToolbar;

  /// Show the status line above each Showcase card's title.
  final bool showStatusBadge;

  /// Show the category in each Showcase card's footer.
  final bool showCategoryBadge;

  /// Show the comment count in each Showcase card's footer.
  final bool showCommentCount;

  /// Show the vote control on each Showcase card.
  final bool showVoteCount;

  /// Let readers remove a vote they gave from a Showcase card.
  final bool allowUndoVote;

  /// Offer the Status filter in the Showcase Sort & Filter sheet.
  final bool showStatusFilter;

  /// Offer the Category filter in the Showcase Sort & Filter sheet.
  final bool showCategoryFilter;

  const FeedbackList({
    super.key,
    this.onFeedbackTap,
    this.onVoteChange,
    this.autoLoad = true,
    this.theme,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.listStyle,
    this.controller,
    this.showToolbar = true,
    this.showStatusBadge = true,
    this.showCategoryBadge = true,
    this.showCommentCount = true,
    this.showVoteCount = true,
    this.allowUndoVote = true,
    this.showStatusFilter = true,
    this.showCategoryFilter = true,
  });

  @override
  State<FeedbackList> createState() => _FeedbackListState();
}

class _FeedbackListState extends State<FeedbackList> {
  bool _didAutoLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleAutoLoad();
  }

  void _scheduleAutoLoad() {
    if (!widget.autoLoad || _didAutoLoad) return;
    final kit = FeedbackKitProvider.of(context);
    if (!kit.isInitialized) return;
    _didAutoLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadFeedback();
    });
  }

  void _loadFeedback() {
    final context = FeedbackKitProvider.of(this.context);
    context.feedbackList.loadFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final providerContext = FeedbackKitProvider.of(context);
    final theme = widget.theme ?? providerContext.theme;
    final style = widget.listStyle ?? providerContext.listStyle;

    if (style == FeedbackListStyle.showcase) {
      return FeedbackKitDirection(
        child: ShowcaseFeedbackList(
          kitTheme: theme,
          controller: widget.controller,
          options: ShowcaseOptions(
            showToolbar: widget.showToolbar,
            showStatusBadge: widget.showStatusBadge,
            showCategoryBadge: widget.showCategoryBadge,
            showCommentCount: widget.showCommentCount,
            showVoteCount: widget.showVoteCount,
            allowUndoVote: widget.allowUndoVote,
            showStatusFilter: widget.showStatusFilter,
            showCategoryFilter: widget.showCategoryFilter,
          ),
          onFeedbackTap: widget.onFeedbackTap,
          onVoteChange: widget.onVoteChange,
          emptyBuilder: widget.emptyBuilder,
          errorBuilder: widget.errorBuilder,
          loadingBuilder: widget.loadingBuilder,
        ),
      );
    }

    return FeedbackKitDirection(
      child: ListenableBuilder(
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
      ),
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
            FeedbackKitPressable(
              onTap: _loadFeedback,
              label: FeedbackKitLocalizations.t('feedback.list.error.retry'),
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
                  style: const TextStyle(
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
