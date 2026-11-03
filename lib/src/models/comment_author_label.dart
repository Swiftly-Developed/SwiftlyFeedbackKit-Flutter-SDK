import 'comment.dart';

/// The name on a comment row.
///
/// The server sends `user_id` and no name, so the id is what most rows show.
String commentAuthorLabel(Comment comment, String anonymous) {
  final userId = comment.userId;
  return comment.authorName ??
      (userId == null || userId.isEmpty ? anonymous : userId);
}
