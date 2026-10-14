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

List<Comment> _commentRows(dynamic data) {
  final rows = data as List;
  return rows.map((item) => Comment.fromJson(item as Map<String, dynamic>)).toList();
}

int? _commentJsonInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

class _CommentPage {
  final List<Comment> items;
  final int page;
  final int perPage;
  final int totalPages;
  final bool legacy;

  const _CommentPage({
    required this.items,
    required this.page,
    required this.perPage,
    required this.totalPages,
    required this.legacy,
  });

  factory _CommentPage.legacy(List<Comment> items) {
    return _CommentPage(
      items: items,
      page: 1,
      perPage: items.length,
      totalPages: 1,
      legacy: true,
    );
  }
}

/// API client for comment operations.
class CommentsApi {
  final FeedbackKitHttpClient _http;

  CommentsApi(this._http);

  /// Lists comments for a feedback item.
  ///
  /// When [page] is omitted, every page is requested and concatenated. A JSON
  /// array is the previous server and is already complete.
  Future<List<Comment>> list(
    String feedbackId, {
    int? page,
    int? perPage,
  }) async {
    final first = await _page(feedbackId, page: page, perPage: perPage);
    if (first.legacy || page != null) {
      return first.items;
    }
    if (first.perPage < 1 || first.items.isEmpty || first.page >= first.totalPages) {
      return first.items;
    }
    final items = [...first.items];
    var next = first.page + 1;
    var size = first.perPage;
    var totalPages = first.totalPages;
    while (next <= totalPages && next <= 100) {
      final more = await _page(feedbackId, page: next, perPage: size);
      if (more.legacy || more.items.isEmpty || more.perPage < 1) {
        break;
      }
      items.addAll(more.items);
      if (more.page >= more.totalPages) {
        break;
      }
      next = more.page + 1;
      size = more.perPage;
      totalPages = more.totalPages;
    }
    return items;
  }

  Future<_CommentPage> _page(
    String feedbackId, {
    int? page,
    int? perPage,
  }) {
    final params = <String, String?>{'paged': '1'};
    if (page != null) {
      params['page'] = page.toString();
    }
    if (perPage != null) {
      params['per_page'] = perPage.toString();
    }
    return _http.get<_CommentPage>(
      '/feedbacks/$feedbackId/comments',
      params: params,
      decoder: (data) {
        if (data is List) {
          return _CommentPage.legacy(_commentRows(data));
        }
        if (data is Map) {
          final rows = data['items'];
          final items = rows is List ? _commentRows(rows) : <Comment>[];
          final meta = data['meta'];
          final metaMap = meta is Map ? meta : const <String, dynamic>{};
          return _CommentPage(
            items: items,
            page: _commentJsonInt(metaMap['page']) ?? 1,
            perPage: _commentJsonInt(metaMap['per_page']) ?? items.length,
            totalPages: _commentJsonInt(metaMap['total_pages']) ?? 1,
            legacy: false,
          );
        }
        return _CommentPage.legacy(const <Comment>[]);
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
