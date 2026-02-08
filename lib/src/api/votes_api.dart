import '../http/http_client.dart';
import '../models/vote_response.dart';

/// API client for vote operations.
class VotesApi {
  final FeedbackKitHttpClient _http;

  VotesApi(this._http);

  /// Votes for a feedback item.
  ///
  /// [feedbackId] - The ID of the feedback to vote for.
  /// [notifyOnStatusChange] - Whether to receive email notifications on status changes.
  Future<VoteResponse> vote(
    String feedbackId, {
    bool? notifyOnStatusChange,
  }) async {
    final body = <String, dynamic>{};
    if (notifyOnStatusChange != null) {
      body['notify_on_status_change'] = notifyOnStatusChange;
    }
    // Include userId in the request body
    if (_http.userId != null) {
      body['userId'] = _http.userId;
    }

    return _http.post<VoteResponse>(
      '/feedbacks/$feedbackId/votes',
      body: body.isEmpty ? null : body,
      decoder: (data) => VoteResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Removes a vote from a feedback item.
  Future<VoteResponse> unvote(String feedbackId) async {
    return _http.delete<VoteResponse>(
      '/feedbacks/$feedbackId/votes',
      params: _http.userId != null ? {'userId': _http.userId} : null,
      decoder: (data) => VoteResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}
