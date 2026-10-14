import 'dart:convert';

import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The day the fixture's relative dates count back from.
final DateTime fixtureNow = DateTime.utc(2026, 10, 14, 9);

FeedbackItem fixtureItem({
  required String id,
  required String title,
  String description = '',
  FeedbackStatus status = FeedbackStatus.pending,
  FeedbackCategory category = FeedbackCategory.featureRequest,
  int voteCount = 0,
  bool hasVoted = false,
  int commentCount = 0,
  int daysAgo = 0,
}) {
  final created = fixtureNow.subtract(Duration(days: daysAgo));
  return FeedbackItem(
    id: id,
    title: title,
    description: description,
    status: status,
    category: category,
    voteCount: voteCount,
    hasVoted: hasVoted,
    commentCount: commentCount,
    createdAt: created,
    updatedAt: created,
  );
}

/// The nine requests the FEEDBACK01 prototype catalog renders, in vote order.
List<FeedbackItem> showcaseFixture() => [
      fixtureItem(
        id: 'f1',
        title: 'Dark mode for the public board',
        description: 'The hosted board is light-only. People who check '
            'requests at night keep turning the brightness down.',
        status: FeedbackStatus.inProgress,
        voteCount: 186,
        hasVoted: true,
        commentCount: 24,
        daysAgo: 40,
      ),
      fixtureItem(
        id: 'f2',
        title: 'Export requests to CSV',
        description: 'A spreadsheet of title, status, votes and comments '
            'before each planning session.',
        status: FeedbackStatus.approved,
        category: FeedbackCategory.improvement,
        voteCount: 142,
        commentCount: 11,
        daysAgo: 28,
      ),
      fixtureItem(
        id: 'f3',
        title: 'Keyboard shortcut to vote on Mac',
        description: 'Command-Shift-V on the selected row. The trackpad '
            'target is easy to miss in a long list.',
        status: FeedbackStatus.inProgress,
        category: FeedbackCategory.improvement,
        voteCount: 119,
        daysAgo: 21,
      ),
      fixtureItem(
        id: 'f4',
        title: 'Selected request disappears in iPad split view after rotating',
        description: 'The detail column goes blank even though the list '
            'still shows a selection.',
        category: FeedbackCategory.bugReport,
        voteCount: 97,
        commentCount: 18,
        daysAgo: 12,
      ),
      fixtureItem(
        id: 'f5',
        title: 'Vote from a Lock Screen widget',
        description: 'The top three requests with a vote button, for when an '
            'idea comes up away from the app.',
        status: FeedbackStatus.testflight,
        voteCount: 74,
        hasVoted: true,
        commentCount: 6,
        daysAgo: 6,
      ),
      fixtureItem(
        id: 'f6',
        title: 'Suggest duplicates while typing',
        description: 'Show similar requests under the title field so votes '
            'land on one item instead of three.',
        category: FeedbackCategory.improvement,
        voteCount: 63,
        commentCount: 9,
        daysAgo: 3,
      ),
      fixtureItem(
        id: 'f7',
        title: 'Email me when a request I voted for ships',
        description: 'One message when the status changes to completed, with '
            'the release note if there is one.',
        status: FeedbackStatus.completed,
        voteCount: 51,
        hasVoted: true,
        commentCount: 14,
        daysAgo: 70,
      ),
      fixtureItem(
        id: 'f8',
        title: 'Draft is lost when the network drops',
        description: 'The submit sheet clears the title and description if '
            'the request fails.',
        status: FeedbackStatus.approved,
        category: FeedbackCategory.bugReport,
        voteCount: 44,
        commentCount: 7,
        daysAgo: 9,
      ),
      fixtureItem(
        id: 'f9',
        title: 'Custom domain for the public board',
        description: 'feedback.example.com instead of the shared host.',
        status: FeedbackStatus.rejected,
        voteCount: 28,
        commentCount: 4,
        daysAgo: 55,
      ),
    ];

/// An in-memory FeedbackKit server: lists [items] and answers votes.
class FakeFeedbackServer {
  FakeFeedbackServer(List<FeedbackItem> items, {this.failList = false})
      : items = [...items];

  final List<FeedbackItem> items;

  /// Answer the list with a 500.
  bool failList;

  /// Answer votes with a 500.
  bool failVotes = false;

  /// How long a vote takes to answer.
  Duration voteLatency = Duration.zero;

  final List<http.Request> requests = [];

  int get listRequests => requests
      .where((r) => r.method == 'GET' && r.url.path.endsWith('/feedbacks'))
      .length;

  http.Client get client => MockClient(_handle);

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path;
    if (request.method == 'GET' && path.endsWith('/feedbacks')) {
      if (failList) return _json({'reason': 'Server unavailable'}, 500);
      return _json({
        'items': [for (final item in items) item.toJson()],
        'meta': {'page': 1, 'per_page': items.length, 'total_pages': 1},
      });
    }
    final vote = RegExp(r'/feedbacks/([^/]+)/votes$').firstMatch(path);
    if (vote != null) {
      if (voteLatency > Duration.zero) await Future<void>.delayed(voteLatency);
      if (failVotes) return _json({'reason': 'Server unavailable'}, 500);
      final id = vote.group(1)!;
      final index = items.indexWhere((item) => item.id == id);
      final item = items[index];
      final voting = request.method == 'POST';
      final updated = item.copyWith(
        hasVoted: voting,
        voteCount: item.voteCount + (voting ? 1 : -1),
      );
      items[index] = updated;
      return _json({
        'success': true,
        'vote_count': updated.voteCount,
        'has_voted': updated.hasVoted,
      });
    }
    return _json({'reason': 'Not found'}, 404);
  }

  http.Response _json(Object body, [int status = 200]) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );
}

/// A Material host with an app bar, the way the README places the list.
Widget materialHost({
  required Widget list,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  Locale? locale,
  FeedbackListStyle listStyle = FeedbackListStyle.showcase,
  FeedbackKitTheme? kitTheme,
  FeedbackKitStorage? storage,
  ThemeData? theme,
  String appLocale = 'en',
  List<Widget>? actions,
}) {
  return FeedbackKitProvider(
    apiKey: 'test-key',
    userId: 'reader-1',
    baseUrl: 'https://feedbackkit.test/api/v1',
    locale: appLocale,
    listStyle: listStyle,
    theme: kitTheme,
    storage: storage,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme ??
          ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B6EF5),
              brightness: brightness,
            ),
          ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Feedback'), actions: actions),
        body: list,
      ),
    ),
  );
}

/// A Cupertino host with no Material ancestor at all.
Widget cupertinoHost({
  required Widget list,
  Brightness brightness = Brightness.light,
}) {
  return FeedbackKitProvider(
    apiKey: 'test-key',
    userId: 'reader-1',
    baseUrl: 'https://feedbackkit.test/api/v1',
    child: CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(brightness: brightness),
      home: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Feedback')),
        child: SafeArea(child: list),
      ),
    ),
  );
}

/// Pumps [host] with [server] answering HTTP, then lets the load finish.
Future<void> pumpWithServer(
  WidgetTester tester,
  FakeFeedbackServer server,
  Widget host, {
  bool settle = true,
}) async {
  await http.runWithClient(
    () async {
      await tester.pumpWidget(host);
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
        await tester.pump();
      }
    },
    () => server.client,
  );
}

/// Sets the test surface to a phone in logical pixels.
void usePhoneSurface(WidgetTester tester, {Size size = const Size(412, 915)}) {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}
