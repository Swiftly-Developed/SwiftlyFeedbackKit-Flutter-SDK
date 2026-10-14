import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../i18n/feedbackkit_localizations.dart';
import '../../models/feedback_category.dart';
import '../../models/feedback_sort_option.dart';
import '../../models/feedback_status.dart';
import '../../state/feedback_list_controller.dart';
import '../../theme/feedbackkit_theme.dart';
import '../feedbackkit_direction.dart';
import 'category_icon.dart';
import 'material_host_bridge.dart';
import 'status_glyph.dart';

/// Opens the Sort & Filter sheet for [controller].
///
/// A Material host gets a modal bottom sheet with a drag handle. A host whose
/// navigator has no Material localizations, such as a `CupertinoApp`, gets
/// the same content in a Cupertino modal popup, which slides up the same way
/// and needs nothing from Material. Choices apply as they are tapped.
Future<void> showSortFilterSheet(
  BuildContext context, {
  required FeedbackListController controller,
  required FeedbackKitTheme kitTheme,
  bool showStatusFilter = true,
  bool showCategoryFilter = true,
}) {
  Widget content(BuildContext context) => FeedbackKitDirection(
        child: SizedBox(
          width: double.infinity,
          child: SortFilterSheet(
            controller: controller,
            showStatusFilter: showStatusFilter,
            showCategoryFilter: showCategoryFilter,
          ),
        ),
      );

  if (MaterialHostBridge.canShowMaterialRoute(context)) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      // Leaves scrim above the sheet to tap, at any text size. 640 is the
      // Material 3 sheet width the default constraints would have applied.
      constraints: BoxConstraints(
        maxWidth: 640,
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      builder: content,
    );
  }
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (popupContext) => MaterialHostBridge(
      kitTheme: kitTheme,
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          return Material(
            color: scheme.surfaceContainerLow,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: content(context),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// The Sort & Filter sheet's content: a sort choice, a status filter, a
/// category filter, and Clear Filters while a filter is active.
class SortFilterSheet extends StatelessWidget {
  /// The state the chips read and write.
  final FeedbackListController controller;

  /// Offer the Status filter.
  final bool showStatusFilter;

  /// Offer the Category filter.
  final bool showCategoryFilter;

  const SortFilterSheet({
    super.key,
    required this.controller,
    this.showStatusFilter = true,
    this.showCategoryFilter = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final glyphSize =
            MediaQuery.textScalerOf(context).scale(16);

        return SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  FeedbackKitLocalizations.t('feedback.list.sortAndFilter'),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              _SectionLabel(FeedbackKitLocalizations.t('feedback.list.sortBy')),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in FeedbackSortOption.values)
                    ChoiceChip(
                      label: Text(option.displayName),
                      selected: controller.sort == option,
                      onSelected: (_) => controller.sort = option,
                    ),
                ],
              ),
              if (showStatusFilter) ...[
                _SectionLabel(
                  FeedbackKitLocalizations.t('feedback.list.filter.status'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: Text(
                        FeedbackKitLocalizations.t(
                          'feedback.list.filter.allStatuses',
                        ),
                      ),
                      selected: controller.statusFilter == null,
                      onSelected: (_) => controller.statusFilter = null,
                    ),
                    for (final status in FeedbackStatus.values)
                      FilterChip(
                        // A selected chip shows the checkmark instead.
                        avatar: controller.statusFilter == status
                            ? null
                            : StatusGlyph(
                                status: status,
                                color: scheme.onSurfaceVariant,
                                size: glyphSize,
                              ),
                        label: Text(status.displayName),
                        selected: controller.statusFilter == status,
                        onSelected: (selected) =>
                            controller.statusFilter = selected ? status : null,
                      ),
                  ],
                ),
              ],
              if (showCategoryFilter) ...[
                _SectionLabel(
                  FeedbackKitLocalizations.t('feedback.list.filter.category'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: Text(
                        FeedbackKitLocalizations.t(
                          'feedback.list.filter.allCategories',
                        ),
                      ),
                      selected: controller.categoryFilter == null,
                      onSelected: (_) => controller.categoryFilter = null,
                    ),
                    for (final category in FeedbackCategory.values)
                      FilterChip(
                        avatar: controller.categoryFilter == category
                            ? null
                            : Icon(showcaseCategoryIcon(category)),
                        label: Text(category.pluralDisplayName),
                        selected: controller.categoryFilter == category,
                        onSelected: (selected) => controller.categoryFilter =
                            selected ? category : null,
                      ),
                  ],
                ),
              ],
              if (controller.isFiltered) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: controller.clearFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.error,
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: Text(
                    FeedbackKitLocalizations.t('feedback.list.filter.clear'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
