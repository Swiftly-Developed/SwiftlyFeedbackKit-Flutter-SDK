import '../http/http_client.dart';
import '../models/comment.dart';

/// Request object for creating a comment.
class CreateCommentRequest {
  /// Content of the comment.
  final String content;

  /// Identifier of the commenting user.
  ///
  /// When this is omitted, [CommentsApi.create] sends the user id configured on
  /// the client. The API reads `userId` from the JSON body.
  final String? userId;

  const CreateCommentRequest({
    required this.content,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (userId != null) 'userId': userId,
    };
  }
}

/// API client for comment operations.
class CommentsApi {
  final FeedbackKitHttpClient _http;

  CommentsApi(this._http);

  /// Lists all comments for a feedback item.
  Future<List<Comment>> list(String feedbackId) async {
    return _http.get<List<Comment>>(
      '/feedbacks/$feedbackId/comments',
      decoder: (data) {
        if (data is List) {
          return data
              .map((item) => Comment.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return <Comment>[];
      },
    );
  }

  /// Creates a new comment on a feedback item.
  Future<Comment> create(String feedbackId, CreateCommentRequest request) async {
    final body = request.toJson();
    // Flutter 1.2.0 sent only `content`. The API requires `userId` in the body;
    // the header alone is not enough for a client that can include it.
    if (body['userId'] == null && _http.userId != null) {
      body['userId'] = _http.userId;
    }
    return _http.post<Comment>(
      '/feedbacks/$feedbackId/comments',
      body: body,
      decoder: (data) => Comment.fromJson(data as Map<String, dynamic>),
    );
  }
}
