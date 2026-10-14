import 'package:flutter/foundation.dart';

import '../i18n/feedbackkit_localizations.dart';
import '../models/feedback.dart' show FeedbackItem;
import '../models/feedback_category.dart';
import '../models/feedback_sort_option.dart';
import '../models/feedback_status.dart';

/// Search, sort and filter state for a [FeedbackList].
///
/// Everything here is applied on the device, over the items the list has
/// already loaded, so changing a filter never shows a loading state. Status,
/// category and search text combine with AND.
///
/// A list creates its own controller. Pass one in when something outside the
/// list needs the same state, such as a [FeedbackSortFilterButton] in an
/// `AppBar`:
///
/// ```dart
/// final controller = FeedbackListController();
///
/// Scaffold(
///   appBar: AppBar(
///     actions: [FeedbackSortFilterButton(controller: controller)],
///   ),
///   body: FeedbackList(controller: controller, showToolbar: false),
/// );
/// ```
///
/// Filters are not persisted: a user who comes back to a silently filtered
/// list believes requests are missing. The sort is persisted by a list that
/// owns its controller.
class FeedbackListController extends ChangeNotifier {
  FeedbackListController({
    FeedbackSortOption sort = FeedbackSortOption.votes,
    FeedbackStatus? statusFilter,
    FeedbackCategory? categoryFilter,
    String searchQuery = '',
  })  : _sort = sort,
        _statusFilter = statusFilter,
        _categoryFilter = categoryFilter,
        _searchQuery = searchQuery;

  FeedbackSortOption _sort;
  FeedbackStatus? _statusFilter;
  FeedbackCategory? _categoryFilter;
  String _searchQuery;

  /// The current sort. Votes by default.
  FeedbackSortOption get sort => _sort;
  set sort(FeedbackSortOption value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  /// The status the list is narrowed to, or null for every status.
  FeedbackStatus? get statusFilter => _statusFilter;
  set statusFilter(FeedbackStatus? value) {
    if (_statusFilter == value) return;
    _statusFilter = value;
    notifyListeners();
  }

  /// The category the list is narrowed to, or null for every category.
  FeedbackCategory? get categoryFilter => _categoryFilter;
  set categoryFilter(FeedbackCategory? value) {
    if (_categoryFilter == value) return;
    _categoryFilter = value;
    notifyListeners();
  }

  /// Search text matched against title and description, ignoring case and
  /// accents.
  String get searchQuery => _searchQuery;
  set searchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  /// Whether a status or category filter is active. Sort and search text do
  /// not count.
  bool get isFiltered => _statusFilter != null || _categoryFilter != null;

  /// How many of the two filters are active: 0, 1 or 2.
  int get activeFilterCount =>
      (_statusFilter != null ? 1 : 0) + (_categoryFilter != null ? 1 : 0);

  /// Whether non-blank search text is set.
  bool get isSearching => _searchQuery.trim().isNotEmpty;

  /// Removes the status and category filters. Keeps the sort and the search
  /// text.
  void clearFilters() {
    if (!isFiltered) return;
    _statusFilter = null;
    _categoryFilter = null;
    notifyListeners();
  }

  /// Removes the search text.
  void clearSearch() => searchQuery = '';

  /// Names of the active filters for display, category first.
  List<String> get activeFilterNames => [
        if (_categoryFilter != null) _categoryFilter!.pluralDisplayName,
        if (_statusFilter != null) _statusFilter!.displayName,
      ];

  /// "Filtered by Bug Reports, In Progress", or null when nothing is
  /// filtered. The order and separator come from the catalog.
  String? get filterSummary {
    final category = _categoryFilter?.pluralDisplayName;
    final status = _statusFilter?.displayName;
    final String names;
    if (category != null && status != null) {
      names = FeedbackKitLocalizations.t('feedback.list.filter.join')
          .replaceAll('{category}', category)
          .replaceAll('{status}', status);
    } else if (category != null || status != null) {
      names = (category ?? status)!;
    } else {
      return null;
    }
    return FeedbackKitLocalizations.t('feedback.list.filteredBy')
        .replaceAll('{filters}', names);
  }

  /// [items] narrowed by the filters and search text, then sorted.
  List<FeedbackItem> apply(Iterable<FeedbackItem> items) {
    final query = foldForSearch(_searchQuery.trim());
    final result = items.where((item) {
      if (_statusFilter != null && item.status != _statusFilter) return false;
      if (_categoryFilter != null && item.category != _categoryFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return foldForSearch(item.title).contains(query) ||
          foldForSearch(item.description).contains(query);
    }).toList();
    result.sort(_sort.compare);
    return result;
  }

  /// Lower-cases [text] and strips the accents of Latin letters, so "cafe"
  /// finds "Café". Other scripts pass through unchanged.
  @visibleForTesting
  static String foldForSearch(String text) {
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_latinFold[char] ?? char);
    }
    return buffer.toString();
  }

  static const Map<String, String> _latinFold = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a', //
    'ç': 'c', 'ć': 'c', 'č': 'c', //
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ę': 'e', 'ě': 'e', //
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', //
    'ñ': 'n', 'ń': 'n', 'ň': 'n', //
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o', //
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ů': 'u', //
    'ý': 'y', 'ÿ': 'y', 'ś': 's', 'š': 's', 'ß': 'ss', //
    'ź': 'z', 'ż': 'z', 'ž': 'z', 'ł': 'l', 'ř': 'r', 'ť': 't', 'ď': 'd',
  };
}
