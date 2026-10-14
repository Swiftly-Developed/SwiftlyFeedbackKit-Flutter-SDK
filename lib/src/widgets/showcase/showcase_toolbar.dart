import 'package:flutter/material.dart';

import '../../i18n/feedbackkit_localizations.dart';
import '../../state/feedback_list_controller.dart';
import '../../theme/feedbackkit_theme.dart';
import 'feedback_sort_filter_button.dart';
import 'showcase_options.dart';

/// The search bar above the Showcase cards, with Clear Search and the Sort &
/// Filter button at its trailing end.
class ShowcaseToolbar extends StatelessWidget {
  /// The list state the search text writes into.
  final FeedbackListController controller;

  /// The search field's text.
  final TextEditingController searchController;

  /// Which filters the sheet offers.
  final ShowcaseOptions options;

  /// Supplies the brand tint to the sheet.
  final FeedbackKitTheme kitTheme;

  const ShowcaseToolbar({
    super.key,
    required this.controller,
    required this.searchController,
    required this.options,
    required this.kitTheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide.none,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ListenableBuilder(
        listenable: searchController,
        // A TextField rather than SearchBar: SearchBar's field is dense with
        // no padding, so its accessibility node is 24dp tall inside a 56dp
        // bar and fails the 48dp target. This one spans the whole bar.
        builder: (context, _) => TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => controller.searchQuery = value,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          style: text.bodyLarge?.copyWith(color: scheme.onSurface),
          decoration: InputDecoration(
            hintText:
                FeedbackKitLocalizations.t('feedback.list.search.placeholder'),
            hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            filled: true,
            fillColor: scheme.surfaceContainerHigh,
            border: pill,
            enabledBorder: pill,
            focusedBorder: pill.copyWith(
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
            constraints: const BoxConstraints(minHeight: 56),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 12),
              child: ExcludeSemantics(
                child: Icon(Icons.search, color: scheme.onSurface),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minHeight: 48),
            suffixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (searchController.text.isNotEmpty)
                    IconButton(
                      tooltip:
                          FeedbackKitLocalizations.t('feedback.list.search.clear'),
                      icon: const Icon(Icons.close),
                      color: scheme.onSurfaceVariant,
                      onPressed: controller.clearSearch,
                    ),
                  FeedbackSortFilterButton(
                    controller: controller,
                    showStatusFilter: options.showStatusFilter,
                    showCategoryFilter: options.showCategoryFilter,
                    theme: kitTheme,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
