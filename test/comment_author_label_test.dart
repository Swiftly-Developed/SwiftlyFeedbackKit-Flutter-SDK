import 'dart:convert';
import 'dart:io';

import 'package:feedbackkit_flutter/src/models/comment.dart';
import 'package:feedbackkit_flutter/src/models/comment_author_label.dart';
import 'package:flutter_test/flutter_test.dart';

/// FULL-REVIEW-2026-10 SDK-02. The server sends `user_id` and no name, so a row that
/// only read the name labelled every comment Anonymous. The rows here are the server's
/// own payload, from the generated corpus.
void main() {
  const anonymous = 'Anonymous';
  final corpus = (jsonDecode(
    File('test/fixtures/comment-wire-corpus.json').readAsStringSync(),
  ) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  test('a server comment shows its user id, not Anonymous', () {
    final comment = Comment.fromJson(corpus[1]);
    expect(comment.authorName, isNull);
    expect(commentAuthorLabel(comment, anonymous), 'fixture-end-user');
  });

  test('a staff reply shows its user id and keeps the team flag', () {
    final comment = Comment.fromJson(corpus[0]);
    expect(commentAuthorLabel(comment, anonymous), 'fixture-admin-user');
    expect(comment.isTeamMember, isTrue);
  });

  test('a name, when a server sends one, wins over the user id', () {
    final comment = Comment.fromJson({...corpus[1], 'author_name': 'Sam'});
    expect(commentAuthorLabel(comment, anonymous), 'Sam');
  });

  test('Anonymous remains for a comment with neither', () {
    final bare = Comment.fromJson({...corpus[1]}..remove('user_id'));
    expect(commentAuthorLabel(bare, anonymous), anonymous);
    final blank = Comment.fromJson({...corpus[1], 'user_id': ''});
    expect(commentAuthorLabel(blank, anonymous), anonymous);
  });

  test('the detail view uses this label', () {
    final source =
        File('lib/src/widgets/feedback_detail_view.dart').readAsStringSync();
    expect(source, contains('commentAuthorLabel('));
    expect(source, isNot(contains('comment.authorName ??\n')));
  });
}
