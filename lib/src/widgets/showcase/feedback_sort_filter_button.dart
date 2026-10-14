import 'package:flutter/material.dart';

import '../../i18n/feedbackkit_localizations.dart';
import '../../state/feedback_list_controller.dart';
import '../../state/feedbackkit_provider.dart';
import '../../theme/feedbackkit_theme.dart';
import 'material_host_bridge.dart';
import 'sort_filter_sheet.dart';

/// The Sort & Filter button that opens the Showcase list's sheet.
///
/// A Showcase [FeedbackList] puts one in its search bar. Put this in
/// `AppBar.actions` instead, with the same [controller] and
/// `FeedbackList(showToolbar: false)`, when the app bar should own it.
///
/// While a filter is active the button turns tonal and shows a badge with the
/// number of active filters, and its accessibility value reads "Filtered by
/// …". Otherwise the value is the current sort.
///
/// The button renders nothing where no navigator can show the sheet, so it is
/// never a control that does nothing.
class FeedbackSortFilterButton extends StatelessWidget {
  /// The list state the sheet edits.
  final FeedbackListController controller;

  /// Offer the Status filter in the sheet.
  final bool showStatusFilter;

  /// Offer the Category filter in the sheet.
  final bool showCategoryFilter;

  /// Optional FeedbackKit theme. Defaults to the provider's.
  final FeedbackKitTheme? theme;

  const FeedbackSortFilterButton({
    super.key,
    required this.controller,
    this.showStatusFilter = true,
    this.showCategoryFilter = true,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (Navigator.maybeOf(context) == null) return const SizedBox.shrink();
    final kitTheme = theme ??
        FeedbackKitProvider.maybeOf(context)?.theme ??
        const FeedbackKitTheme();
    return MaterialHostBridge(
      kitTheme: kitTheme,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final count = controller.activeFilterCount;
          final icon = Badge(
            isLabelVisible: count > 0,
            label: Text(FeedbackKitLocalizations.formatCount(count)),
            child: const Icon(Icons.filter_list),
          );
          final tooltip =
              FeedbackKitLocalizations.t('feedback.list.sortAndFilter');
          void open() => showSortFilterSheet(
                context,
                controller: controller,
                kitTheme: kitTheme,
                showStatusFilter: showStatusFilter,
                showCategoryFilter: showCategoryFilter,
              );
          return MergeSemantics(
            child: Semantics(
              value: controller.filterSummary ?? controller.sort.displayName,
              child: count > 0
                  ? IconButton.filledTonal(
                      onPressed: open,
                      tooltip: tooltip,
                      icon: icon,
                    )
                  : IconButton(onPressed: open, tooltip: tooltip, icon: icon),
            ),
          );
        },
      ),
    );
  }
}
