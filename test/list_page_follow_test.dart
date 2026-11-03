import 'dart:convert';

import 'package:feedbackkit_flutter/src/api/comments_api.dart';
import 'package:feedbackkit_flutter/src/api/feedback_api.dart';
import 'package:feedbackkit_flutter/src/client/feedbackkit_config.dart';
import 'package:feedbackkit_flutter/src/http/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// RESILIENCE01 §9.1. A paged list stops following when the server's page number
/// cannot be trusted, and always stops within 100 follow-up requests. The stub
/// throws after 300 requests, so a client that keeps following fails instead of
/// hanging.
const _apiKey = 'sf_test_stub_key_not_a_credential';
const _userId = 'user-under-test';
const _feedbackId = '11111111-1111-4111-8111-111111111111';

class _ListKind {
  final String name;
  final String path;
  final Map<String, dynamic> Function(int index) row;
  final Future<int> Function(FeedbackKitHttpClient http, {int? page}) list;

  const _ListKind(this.name, this.path, this.row, this.list);
}

String _id(int index) =>
    'AAAAAAAA-AAAA-4AAA-8AAA-${index.toString().padLeft(12, '0')}';

final _kinds = <_ListKind>[
  _ListKind(
    'feedback',
    '/feedbacks',
    (index) => {
      'id': _id(index),
      'title': 'row content $index',
      'description': 'row content $index',
      'status': 'pending',
      'category': 'feature_request',
      'user_id': _userId,
      'vote_count': 1,
      'has_voted': false,
      'comment_count': 0,
      'created_at': '2023-11-14T22:13:20Z',
      'updated_at': '2023-11-14T22:13:20Z',
    },
    (http, {page}) async =>
        (await FeedbackApi(http).list(ListFeedbackOptions(page: page))).length,
  ),
  _ListKind(
    'comments',
    '/feedbacks/$_feedbackId/comments',
    (index) => {
      'id': _id(index),
      'content': 'row content $index',
      'user_id': _userId,
      'is_admin': false,
      'created_at': '2023-11-14T22:13:20Z',
    },
    (http, {page}) async =>
        (await CommentsApi(http).list(_feedbackId, page: page)).length,
  ),
];

void main() {
  late List<String> lines;
  final savedDebugPrint = debugPrint;

  setUp(() {
    lines = [];
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && message.contains('stopped following')) {
        lines.add(message);
      }
    };
  });

  tearDown(() {
    debugPrint = savedDebugPrint;
  });

  for (final kind in _kinds) {
    group('following ${kind.name} pages', () {
      late int calls;

      FeedbackKitHttpClient server(Map<String, int> Function(int requested) meta) {
        calls = 0;
        return FeedbackKitHttpClient(
          config: const FeedbackKitConfig(apiKey: _apiKey, userId: _userId),
          client: MockClient((request) async {
            calls += 1;
            if (calls > 300) {
              throw StateError('still following after 300 requests');
            }
            final requested =
                int.parse(request.url.queryParameters['page'] ?? '1');
            return http.Response(
              jsonEncode({
                'items': [kind.row(requested)],
                'meta': meta(requested),
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
      }

      void expectClean(String line) {
        expect(line, isNot(contains(_apiKey)));
        expect(line, isNot(contains(_userId)));
        expect(line, isNot(contains('row content')));
      }

      test('a stale echo stops after two requests and keeps page one', () async {
        final client =
            server((_) => {'page': 1, 'per_page': 1, 'total_pages': 3});
        final rows = await kind.list(client);
        expect(calls, 2);
        expect(rows, 1);
        expect(lines, hasLength(1));
        expect(lines.single, contains(kind.path));
        expect(lines.single, contains('requested page 2'));
        expect(lines.single, contains('received page 1'));
        expectClean(lines.single);
      });

      test('a follow-up without meta.page stops after two requests', () async {
        final client = server((requested) => requested == 1
            ? {'page': 1, 'per_page': 1, 'total_pages': 3}
            : {'per_page': 1, 'total_pages': 3},);
        final rows = await kind.list(client);
        expect(calls, 2);
        expect(rows, 1);
        expect(lines, hasLength(1));
        expect(lines.single, contains('requested page 2'));
        expect(lines.single, contains('received page missing'));
        expectClean(lines.single);
      });

      test('a growing total stops after 100 follow-ups', () async {
        final client = server((requested) =>
            {'page': requested, 'per_page': 1, 'total_pages': requested + 1},);
        final rows = await kind.list(client);
        expect(calls, 101);
        expect(rows, 101);
        expect(lines, hasLength(1));
        expect(lines.single, contains('requested page 102'));
        expect(lines.single, contains('received page 101'));
      });

      test('a correct server is read to the end with no log line', () async {
        final client = server(
            (requested) => {'page': requested, 'per_page': 1, 'total_pages': 3},);
        final rows = await kind.list(client);
        expect(calls, 3);
        expect(rows, 3);
        expect(lines, isEmpty);
      });

      test('exactly 101 pages finish with no log line', () async {
        final client = server((requested) =>
            {'page': requested, 'per_page': 1, 'total_pages': 101},);
        final rows = await kind.list(client);
        expect(calls, 101);
        expect(rows, 101);
        expect(lines, isEmpty);
      });

      test('an explicit page is one request', () async {
        final client = server(
            (requested) => {'page': requested, 'per_page': 1, 'total_pages': 3},);
        final rows = await kind.list(client, page: 2);
        expect(calls, 1);
        expect(rows, 1);
        expect(lines, isEmpty);
      });

      test('a first response without meta.page is read as page one', () async {
        final client = server((requested) => requested == 1
            ? {'per_page': 1, 'total_pages': 2}
            : {'page': requested, 'per_page': 1, 'total_pages': 2},);
        final rows = await kind.list(client);
        expect(calls, 2);
        expect(rows, 2);
        expect(lines, isEmpty);
      });
    });
  }
}
