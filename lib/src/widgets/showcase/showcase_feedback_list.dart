import 'package:flutter/material.dart';

import '../../i18n/feedbackkit_localizations.dart';
import '../../models/feedback.dart' show FeedbackItem;
import '../../models/feedback_sort_option.dart';
import '../../models/vote_response.dart';
import '../../state/feedback_list_controller.dart';
import '../../state/feedbackkit_provider.dart';
import '../../state/notifiers/feedback_list_notifier.dart';
import '../../theme/feedbackkit_theme.dart';
import 'material_host_bridge.dart';
import 'showcase_card.dart';
import 'showcase_filter_summary_row.dart';
import 'showcase_message.dart';
import 'showcase_options.dart';
import 'showcase_skeleton_card.dart';
import 'showcase_toolbar.dart';

/// The Showcase body of `FeedbackList`: search bar, filter row, cards, and
/// the loading, empty, filtered-empty, search-empty and error states.
class ShowcaseFeedbackList extends StatefulWidget {
  /// Flags from `FeedbackList`.
  final ShowcaseOptions options;

  /// Shared search, sort and filter state. The list makes its own when null,
  /// and only then persists the sort.
  final FeedbackListController? controller;

  /// Supplies status colours and an optional brand tint.
  final FeedbackKitTheme kitTheme;

  /// Opens a request.
  final void Function(FeedbackItem)? onFeedbackTap;

  /// Called after the server confirms a vote change.
  final void Function(FeedbackItem, VoteResponse)? onVoteChange;

  /// Host replacement for the project-empty state.
  final Widget Function(BuildContext)? emptyBuilder;

  /// Host replacement for the error state.
  final Widget Function(BuildContext, Object)? errorBuilder;

  /// Host replacement for the loading placeholder.
  final Widget Function(BuildContext)? loadingBuilder;

  const ShowcaseFeedbackList({
    super.key,
    required this.options,
    required this.kitTheme,
    this.controller,
    this.onFeedbackTap,
    this.onVoteChange,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  State<ShowcaseFeedbackList> createState() => _ShowcaseFeedbackListState();
}

class _ShowcaseFeedbackListState extends State<ShowcaseFeedbackList> {
  FeedbackListController? _ownedController;
  late final TextEditingController _search;
  bool _didLoadSort = false;
  bool _sortChangedBeforeLoad = false;

  FeedbackListNotifier? _notifier;
  FeedbackListState? _lastState;
  int _generation = 0;
  int? _orderKey;
  List<String> _order = const [];

  FeedbackListController get _controller =>
      widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _ownedController = FeedbackListController();
    _search = TextEditingController(text: _controller.searchQuery);
    _attach(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = FeedbackKitProvider.of(context).feedbackList;
    if (!identical(notifier, _notifier)) {
      _notifier?.removeListener(_onListChanged);
      _notifier = notifier..addListener(_onListChanged);
      _lastState = notifier.state;
    }
    _loadStoredSort();
  }

  @override
  void didUpdateWidget(ShowcaseFeedbackList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldController = oldWidget.controller ?? _ownedController!;
    if (widget.controller == oldWidget.controller) return;
    _detach(oldController);
    if (widget.controller != null) {
      _ownedController?.dispose();
      _ownedController = null;
    } else {
      _ownedController = FeedbackListController();
    }
    _attach(_controller);
    _search.text = _controller.searchQuery;
  }

  @override
  void dispose() {
    _notifier?.removeListener(_onListChanged);
    _detach(_controller);
    _ownedController?.dispose();
    _search.dispose();
    super.dispose();
  }

  FeedbackSortOption? _persistedSort;

  void _attach(FeedbackListController controller) {
    _persistedSort = controller.sort;
    controller.addListener(_onControllerChanged);
  }

  void _detach(FeedbackListController controller) {
    controller.removeListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final controller = _controller;
    if (_search.text != controller.searchQuery) {
      _search.text = controller.searchQuery;
    }
    if (_ownedController != null && controller.sort != _persistedSort) {
      _persistedSort = controller.sort;
      if (!_didLoadSort) _sortChangedBeforeLoad = true;
      _storeSort(controller.sort);
    }
  }

  Future<void> _loadStoredSort() async {
    if (_didLoadSort || _ownedController == null) return;
    _didLoadSort = true;
    final storage = FeedbackKitProvider.of(context).client.storage;
    String? stored;
    try {
      stored = await storage.getListSort();
    } catch (_) {
      // A storage the host cannot read leaves the default sort.
      return;
    }
    final option = FeedbackSortOption.fromName(stored);
    final owned = _ownedController;
    if (!mounted || option == null || owned == null || _sortChangedBeforeLoad) {
      return;
    }
    _persistedSort = option;
    owned.sort = option;
  }

  Future<void> _storeSort(FeedbackSortOption sort) async {
    final storage = FeedbackKitProvider.of(context).client.storage;
    try {
      await storage.setListSort(sort.name);
    } catch (_) {
      // The sort still applies for this session.
    }
  }

  /// Displayed items, in an order that only changes when the sort, filters,
  /// search text or set of items change, or a reload completes. A vote
  /// changes a count but never moves the card under the reader's finger.
  List<FeedbackItem> _displayed(List<FeedbackItem> items) {
    final c = _controller;
    final key = Object.hash(
      _generation,
      c.sort,
      c.statusFilter,
      c.categoryFilter,
      c.searchQuery,
      items.length,
      Object.hashAllUnordered(items.map((item) => item.id)),
    );
    if (key == _orderKey) {
      final byId = {for (final item in items) item.id: item};
      return [
        for (final id in _order)
          if (byId[id] != null) byId[id]!,
      ];
    }
    final result = c.apply(items);
    _orderKey = key;
    _order = [for (final item in result) item.id];
    return result;
  }

  /// Counts completed loads. Listening here rather than in build sees the
  /// loading state even when the response lands before the next frame.
  void _onListChanged() {
    final state = _notifier!.state;
    if (_lastState == FeedbackListState.loading &&
        state == FeedbackListState.loaded) {
      _generation++;
    }
    _lastState = state;
  }

  @override
  Widget build(BuildContext context) {
    final kit = FeedbackKitProvider.of(context);
    return MaterialHostBridge(
      kitTheme: widget.kitTheme,
      child: ListenableBuilder(
        listenable: Listenable.merge([kit.feedbackList, _controller]),
        builder: (context, _) {
          final content = _buildContent(context, kit.feedbackList);
          if (!widget.options.showToolbar) return content;
          return Column(
            children: [
              ShowcaseToolbar(
                controller: _controller,
                searchController: _search,
                options: widget.options,
                kitTheme: widget.kitTheme,
              ),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, FeedbackListNotifier notifier) {
    final items = notifier.feedbackItems;
    final state = notifier.state;

    final loading = state == FeedbackListState.initial ||
        state == FeedbackListState.loading;
    if (loading && items.isEmpty) {
      return widget.loadingBuilder?.call(context) ?? _buildSkeleton(context);
    }

    if (state == FeedbackListState.error && items.isEmpty) {
      final error = notifier.error!;
      return widget.errorBuilder?.call(context, error) ??
          _scrollable(notifier, [_fill(_errorMessage(notifier, error))]);
    }

    if (items.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          _scrollable(notifier, [
            _fill(
              ShowcaseMessage(
                icon: Icons.forum_outlined,
                title: FeedbackKitLocalizations.t('feedback.list.empty'),
                description:
                    FeedbackKitLocalizations.t('feedback.list.empty.description'),
              ),
            ),
          ]);
    }

    final controller = _controller;
    final displayed = _displayed(items);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return _scrollable(notifier, [
      SliverToBoxAdapter(
        child: AnimatedSize(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
          alignment: AlignmentDirectional.topStart,
          child: controller.isFiltered
              ? ShowcaseFilterSummaryRow(controller: controller)
              : const SizedBox(width: double.infinity),
        ),
      ),
      if (state == FeedbackListState.error && notifier.error != null)
        SliverToBoxAdapter(child: _errorMessage(notifier, notifier.error!)),
      if (displayed.isEmpty)
        _fill(_noMatchMessage(controller))
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList.separated(
            itemCount: displayed.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final feedback = displayed[index];
              return ShowcaseCard(
                key: ValueKey(feedback.id),
                feedback: feedback,
                options: widget.options,
                kitTheme: widget.kitTheme,
                onTap: widget.onFeedbackTap == null
                    ? null
                    : () => widget.onFeedbackTap!(feedback),
                onVoteChange: widget.onVoteChange == null
                    ? null
                    : (response) => widget.onVoteChange!(feedback, response),
              );
            },
          ),
        ),
    ]);
  }

  Widget _noMatchMessage(FeedbackListController controller) {
    if (controller.isFiltered) {
      return ShowcaseMessage(
        icon: Icons.filter_alt_off_outlined,
        title: FeedbackKitLocalizations.t('feedback.list.filteredEmpty.title'),
        description: FeedbackKitLocalizations.t(
          'feedback.list.filteredEmpty.description',
        ),
        actionLabel: FeedbackKitLocalizations.t('feedback.list.filter.clear'),
        onAction: controller.clearFilters,
      );
    }
    return ShowcaseMessage(
      icon: Icons.search_off,
      title: FeedbackKitLocalizations.t('feedback.list.search.empty.title'),
      description:
          FeedbackKitLocalizations.t('feedback.list.search.empty.description'),
      actionLabel: FeedbackKitLocalizations.t('feedback.list.search.clear'),
      onAction: controller.clearSearch,
    );
  }

  Widget _errorMessage(FeedbackListNotifier notifier, Object error) {
    return ShowcaseMessage(
      icon: Icons.error_outline,
      isError: true,
      title: FeedbackKitLocalizations.t('feedback.list.error'),
      description: error.toString(),
      actionLabel: FeedbackKitLocalizations.t('feedback.list.error.retry'),
      onAction: notifier.refresh,
    );
  }

  Widget _fill(Widget child) =>
      SliverFillRemaining(hasScrollBody: false, child: child);

  Widget _scrollable(FeedbackListNotifier notifier, List<Widget> slivers) {
    return RefreshIndicator.adaptive(
      onRefresh: notifier.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: slivers,
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Semantics(
      label: FeedbackKitLocalizations.t('feedback.list.loading'),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            ShowcaseSkeletonCard(options: widget.options, index: index),
      ),
    );
  }
}
