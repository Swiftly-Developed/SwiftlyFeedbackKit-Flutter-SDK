import '../errors/feedbackkit_error.dart';
import '../http/http_client.dart';
import '../models/vote_response.dart';

/// API client for vote operations.
class VotesApi {
  final FeedbackKitHttpClient _http;

  VotesApi(this._http);

  /// Votes for a feedback item.
  ///
  /// [feedbackId] - The ID of the feedback to vote for.
  /// [notifyStatusChange] - Opt in to email when the feedback's status changes.
  ///   The server stores this only together with [email]. Sent as
  ///   `notify_status_change`, the key `CreateVoteDTO.notifyStatusChange` decodes.
  /// [notifyOnStatusChange] - Deprecated alias for [notifyStatusChange]. 1.0.1
  ///   call sites keep compiling; the value is sent under the corrected key.
  /// [email] - Address that receives the status-change email. Optional.
  /// [subscribeToMailingList] - Whether the user opts in to the mailing list.
  /// [mailingListEmailTypes] - Email preference types (e.g. ["operational", "marketing"]). Defaults to both when null.
  Future<VoteResponse> vote(
    String feedbackId, {
    bool? notifyStatusChange,
    @Deprecated(
      'Use notifyStatusChange. The server reads notify_status_change, not notify_on_status_change.',
    )
    bool? notifyOnStatusChange,
    String? email,
    bool? subscribeToMailingList,
    List<String>? mailingListEmailTypes,
  }) async {
    final userId = _http.userId?.trim();
    if (userId == null || userId.isEmpty) {
      throw const ValidationError(
        message: 'A user ID is required before voting. Call setUserId first.',
      );
    }
    final notify = notifyStatusChange ?? notifyOnStatusChange;
    final body = <String, dynamic>{
      'user_id': userId,
      if (email != null) 'email': email,
      if (notify != null) 'notify_status_change': notify,
      if (subscribeToMailingList != null)
        'subscribe_to_mailing_list': subscribeToMailingList,
      if (mailingListEmailTypes != null)
        'mailing_list_email_types': mailingListEmailTypes,
    };

    return _http.post<VoteResponse>(
      '/feedbacks/$feedbackId/votes',
      body: body,
      decoder: (data) => VoteResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Removes a vote from a feedback item.
  ///
  /// The server decodes the vote request from the body, the same shape as a
  /// vote. A query parameter is ignored, so the user id has to be JSON.
  ///
  /// Throws a [ValidationError] when no user id is configured.
  Future<VoteResponse> unvote(String feedbackId) async {
    final userId = _http.userId?.trim();
    if (userId == null || userId.isEmpty) {
      throw const ValidationError(
        message:
            'A user ID is required before removing a vote. Call setUserId first.',
      );
    }
    return _http.delete<VoteResponse>(
      '/feedbacks/$feedbackId/votes',
      body: {'user_id': userId},
      decoder: (data) => VoteResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}
