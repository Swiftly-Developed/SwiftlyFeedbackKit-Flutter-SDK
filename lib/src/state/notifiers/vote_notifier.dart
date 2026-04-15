import 'package:flutter/foundation.dart';

import '../../client/feedbackkit_client.dart';
import '../../errors/feedbackkit_error.dart';
import '../../models/vote_response.dart';

/// Notifier for managing vote operations with optimistic updates.
class VoteNotifier extends ChangeNotifier {
  final FeedbackKit _client;
  final Set<String> _votingInProgress = {};
  final Map<String, FeedbackKitError?> _errors = {};

  VoteNotifier(this._client);

  /// Checks if a vote operation is in progress for a feedback item.
  bool isVoting(String feedbackId) => _votingInProgress.contains(feedbackId);

  /// Gets the last error for a feedback item.
  FeedbackKitError? getError(String feedbackId) => _errors[feedbackId];

  /// Clears the error for a feedback item.
  void clearError(String feedbackId) {
    _errors.remove(feedbackId);
    notifyListeners();
  }

  /// Votes for a feedback item.
  ///
  /// Returns the vote response on success, or null if the operation is already
  /// in progress or fails.
  Future<VoteResponse?> vote(
    String feedbackId, {
    bool? notifyOnStatusChange,
  }) async {
    if (_votingInProgress.contains(feedbackId)) return null;

    _votingInProgress.add(feedbackId);
    _errors.remove(feedbackId);
    notifyListeners();

    try {
      final response = await _client.votes.vote(
        feedbackId,
        notifyOnStatusChange: notifyOnStatusChange,
      );
      return response;
    } on FeedbackKitError catch (e) {
      _errors[feedbackId] = e;
      return null;
    } finally {
      _votingInProgress.remove(feedbackId);
      notifyListeners();
    }
  }

  /// Removes a vote from a feedback item.
  ///
  /// Returns the vote response on success, or null if the operation is already
  /// in progress or fails.
  Future<VoteResponse?> unvote(String feedbackId) async {
    if (_votingInProgress.contains(feedbackId)) return null;

    _votingInProgress.add(feedbackId);
    _errors.remove(feedbackId);
    notifyListeners();

    try {
      final response = await _client.votes.unvote(feedbackId);
      return response;
    } on FeedbackKitError catch (e) {
      _errors[feedbackId] = e;
      return null;
    } finally {
      _votingInProgress.remove(feedbackId);
      notifyListeners();
    }
  }

  /// Toggles the vote state for a feedback item.
  Future<VoteResponse?> toggle(
    String feedbackId, {
    required bool hasVoted,
    bool? notifyOnStatusChange,
  }) async {
    if (hasVoted) {
      return unvote(feedbackId);
    } else {
      return vote(feedbackId, notifyOnStatusChange: notifyOnStatusChange);
    }
  }
}
