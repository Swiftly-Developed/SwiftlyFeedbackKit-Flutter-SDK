import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../i18n/feedbackkit_localizations.dart';
import '../../state/feedback_list_controller.dart';

/// "Filtered by [Bug Reports] [In Progress] … Clear", shown above the cards
/// while a status or category filter is active.
///
/// Each filter is an input chip whose delete icon removes just that filter.
/// Clear removes both and keeps the sort and the search text. Screen readers
/// hear one "Filtered by Bug Reports, In Progress" element with a "Clear
/// filters" action; the chips and Clear stay reachable on their own.
class ShowcaseFilterSummaryRow extends StatelessWidget {
  /// The list's search, sort and filter state.
  final FeedbackListController controller;

  const ShowcaseFilterSummaryRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final category = controller.categoryFilter;
    final status = controller.statusFilter;

    String removeLabel(String name) =>
        FeedbackKitLocalizations.t('feedback.list.filter.remove')
            .replaceAll('{filter}', name);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: controller.filterSummary,
      customSemanticsActions: {
        CustomSemanticsAction(
          label: FeedbackKitLocalizations.t('accessibility.filter.clear'),
        ): controller.clearFilters,
      },
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 8, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_alt,
                            size: 20,
                            applyTextScaling: true,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              FeedbackKitLocalizations.t(
                                'feedback.list.filteredBy.prefix',
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (category != null)
                      InputChip(
                        label: Text(category.pluralDisplayName),
                        onDeleted: () => controller.categoryFilter = null,
                        deleteButtonTooltipMessage:
                            removeLabel(category.pluralDisplayName),
                      ),
                    if (status != null)
                      InputChip(
                        label: Text(status.displayName),
                        onDeleted: () => controller.statusFilter = null,
                        deleteButtonTooltipMessage:
                            removeLabel(status.displayName),
                      ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: controller.clearFilters,
              style: TextButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.padded,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(
                FeedbackKitLocalizations.t('feedback.list.filteredBy.clear'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
