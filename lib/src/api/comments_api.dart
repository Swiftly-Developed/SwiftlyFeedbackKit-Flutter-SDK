import '../http/http_client.dart';
import '../models/comment.dart';

/// Request object for creating a comment.
class CreateCommentRequest {
  /// Content of the comment.
  final String content;

  const CreateCommentRequest({
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
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
    return _http.post<Comment>(
      '/feedbacks/$feedbackId/comments',
      body: request.toJson(),
      decoder: (data) => Comment.fromJson(data as Map<String, dynamic>),
    );
  }
}
