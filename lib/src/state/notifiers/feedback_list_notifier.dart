import 'package:flutter/foundation.dart';

import '../../api/feedback_api.dart';
import '../../client/feedbackkit_client.dart';
import '../../errors/feedbackkit_error.dart';
import '../../models/feedback.dart' show FeedbackItem;
import '../../models/feedback_category.dart';
import '../../models/feedback_status.dart';

/// State for feedback list.
enum FeedbackListState {
  initial,
  loading,
  loaded,
  error,
}

/// Notifier for managing feedback list state.
class FeedbackListNotifier extends ChangeNotifier {
  final FeedbackKit _client;

  FeedbackListState _state = FeedbackListState.initial;
  List<FeedbackItem> _feedbackItems = [];
  FeedbackKitError? _error;
  FeedbackStatus? _statusFilter;
  FeedbackCategory? _categoryFilter;

  FeedbackListNotifier(this._client);

  /// Current state of the feedback list.
  FeedbackListState get state => _state;

  /// List of feedback items.
  List<FeedbackItem> get feedbackItems => List.unmodifiable(_feedbackItems);

  /// Error if the last operation failed.
  FeedbackKitError? get error => _error;

  /// Current status filter.
  FeedbackStatus? get statusFilter => _statusFilter;

  /// Current category filter.
  FeedbackCategory? get categoryFilter => _categoryFilter;

  /// Whether the list is currently loading.
  bool get isLoading => _state == FeedbackListState.loading;

  /// Sets the status filter and reloads the list.
  Future<void> setStatusFilter(FeedbackStatus? status) async {
    if (_statusFilter == status) return;
    _statusFilter = status;
    await loadFeedback();
  }

  /// Sets the category filter and reloads the list.
  Future<void> setCategoryFilter(FeedbackCategory? category) async {
    if (_categoryFilter == category) return;
    _categoryFilter = category;
    await loadFeedback();
  }

  /// Clears all filters and reloads the list.
  Future<void> clearFilters() async {
    _statusFilter = null;
    _categoryFilter = null;
    await loadFeedback();
  }

  /// Loads the feedback list.
  Future<void> loadFeedback() async {
    _state = FeedbackListState.loading;
    _error = null;
    notifyListeners();

    try {
      _feedbackItems = await _client.feedback.list(
        ListFeedbackOptions(
          status: _statusFilter,
          category: _categoryFilter,
        ),
      );
      _state = FeedbackListState.loaded;
    } on FeedbackKitError catch (e) {
      _error = e;
      _state = FeedbackListState.error;
    } catch (e) {
      _error = NetworkError(message: e.toString());
      _state = FeedbackListState.error;
    }

    notifyListeners();
  }

  /// Refreshes the feedback list.
  Future<void> refresh() => loadFeedback();

  /// Updates a feedback item in the list.
  void updateFeedback(FeedbackItem updatedFeedback) {
    final index = _feedbackItems.indexWhere((f) => f.id == updatedFeedback.id);
    if (index >= 0) {
      _feedbackItems = List.from(_feedbackItems);
      _feedbackItems[index] = updatedFeedback;
      notifyListeners();
    }
  }

  /// Gets a feedback item by ID.
  FeedbackItem? getFeedback(String id) {
    try {
      return _feedbackItems.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }
}
