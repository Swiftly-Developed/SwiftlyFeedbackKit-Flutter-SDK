import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:feedbackkit_flutter/src/widgets/showcase/showcase_card.dart';
import 'package:feedbackkit_flutter/src/widgets/showcase/showcase_skeleton_card.dart';
import 'package:feedbackkit_flutter/src/widgets/showcase/showcase_vote_capsule.dart';
import 'package:feedbackkit_flutter/src/widgets/showcase/sort_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/showcase_harness.dart';

Finder cardTitled(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(ShowcaseCard));

Finder capsuleOf(String title) => find.descendant(
      of: cardTitled(title),
      matching: find.byType(ShowcaseVoteCapsule),
    );

List<String> visibleTitles(WidgetTester tester) => tester
    .widgetList<ShowcaseCard>(find.byType(ShowcaseCard))
    .map((card) => card.feedback.title)
    .toList();

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Sort & Filter'));
  await tester.pumpAndSettle();
  expect(find.byType(SortFilterSheet), findsOneWidget);
}

Future<void> tapInSheet(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> closeSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(200, 20));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FeedbackKitLocalizations.setLocale('en');
  });

  group('list style', () {
    testWidgets('Showcase is the default', (tester) async {
      usePhoneSurface(tester);
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(list: const FeedbackList()),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ShowcaseCard), findsWidgets);
      expect(find.byType(FeedbackCard), findsNothing);
      expect(visibleTitles(tester).first, 'Dark mode for the public board');
    });

    testWidgets('the provider can choose Classic', (tester) async {
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(
          list: const FeedbackList(),
          listStyle: FeedbackListStyle.classic,
        ),
      );
      expect(find.byType(FeedbackCard), findsWidgets);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(ShowcaseCard), findsNothing);
    });

    testWidgets('the widget overrides the provider', (tester) async {
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(
          list: const FeedbackList(listStyle: FeedbackListStyle.classic),
        ),
      );
      expect(find.byType(FeedbackCard), findsWidgets);
      expect(find.byType(ShowcaseCard), findsNothing);
    });
  });

  group('states', () {
    testWidgets('loading shows skeleton cards announced as loading',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        materialHost(list: const FeedbackList(autoLoad: false)),
      );
      await tester.pump();
      expect(find.byType(ShowcaseSkeletonCard), findsWidgets);
      expect(find.bySemanticsLabel('Loading...'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an empty project shows the empty message', (tester) async {
      final server = FakeFeedbackServer(const []);
      await pumpWithServer(
        tester,
        server,
        materialHost(list: const FeedbackList()),
      );
      expect(find.text('No feedback yet'), findsOneWidget);
      expect(find.text('Be the first to submit feedback!'), findsOneWidget);
    });

    testWidgets('an error offers Retry, which reloads', (tester) async {
      final server = FakeFeedbackServer(showcaseFixture(), failList: true);
      await pumpWithServer(
        tester,
        server,
        materialHost(list: const FeedbackList()),
      );
      expect(find.text('Failed to load feedback'), findsOneWidget);

      server.failList = false;
      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Failed to load feedback'), findsNothing);
      expect(find.byType(ShowcaseCard), findsWidgets);
    });
  });

  group('search, sort and filter', () {
    testWidgets('search narrows the list and offers Clear Search',
        (tester) async {
      usePhoneSurface(tester);
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(list: const FeedbackList()),
      );

      await tester.enterText(find.byType(TextField), 'public board');
      await tester.pumpAndSettle();
      expect(visibleTitles(tester), [
        'Dark mode for the public board',
        'Custom domain for the public board',
      ]);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No Results'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Clear Search'));
      await tester.pumpAndSettle();
      expect(find.byType(ShowcaseCard), findsWidgets);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    });

    testWidgets('the sheet filters, and the row clears', (tester) async {
      usePhoneSurface(tester);
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(list: const FeedbackList()),
      );

      await openSheet(tester);
      await tapInSheet(tester, find.widgetWithText(FilterChip, 'In Progress'));
      await tapInSheet(tester, find.widgetWithText(FilterChip, 'Improvements'));
      expect(find.text('Clear Filters'), findsOneWidget);
      await closeSheet(tester);

      expect(visibleTitles(tester), ['Keyboard shortcut to vote on Mac']);
      expect(find.text('Filtered by'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Improvements'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'In Progress'), findsOneWidget);

      // Removing one chip keeps the other filter.
      await tester.tap(find.byTooltip('Remove Improvements'));
      await tester.pumpAndSettle();
      expect(visibleTitles(tester), [
        'Dark mode for the public board',
        'Keyboard shortcut to vote on Mac',
      ]);

      await tester.tap(find.widgetWithText(TextButton, 'Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Filtered by'), findsNothing);
      expect(find.byType(ShowcaseCard), findsWidgets);
    });

    testWidgets('a filter with no matches offers Clear Filters',
        (tester) async {
      final controller = FeedbackListController(
        statusFilter: FeedbackStatus.rejected,
        categoryFilter: FeedbackCategory.bugReport,
        searchQuery: '',
      );
      addTearDown(controller.dispose);
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(list: FeedbackList(controller: controller)),
      );

      expect(find.text('No Matching Requests'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Clear Filters'));
      await tester.pumpAndSettle();
      expect(controller.isFiltered, isFalse);
      expect(find.byType(ShowcaseCard), findsWidgets);
    });

    testWidgets('the sort persists when the list owns its controller',
        (tester) async {
      usePhoneSurface(tester);
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(list: const FeedbackList()),
      );

      await openSheet(tester);
      await tapInSheet(tester, find.widgetWithText(ChoiceChip, 'Newest'));
      await closeSheet(tester);
      expect(visibleTitles(tester).first, 'Suggest duplicates while typing');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('feedbackkit_list_sort'), 'newest');

      await tester.pumpWidget(const SizedBox());
      await pumpWithServer(
        tester,
        server,
        materialHost(list: const FeedbackList()),
      );
      expect(visibleTitles(tester).first, 'Suggest duplicates while typing');
    });

    testWidgets('a host controller is not persisted', (tester) async {
      final controller = FeedbackListController();
      addTearDown(controller.dispose);
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(list: FeedbackList(controller: controller)),
      );
      controller.sort = FeedbackSortOption.oldest;
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('feedbackkit_list_sort'), isNull);
      expect(
        visibleTitles(tester).first,
        'Email me when a request I voted for ships',
      );
    });

    testWidgets('unreadable storage leaves the default sort', (tester) async {
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(
          list: const FeedbackList(),
          storage: _BrokenSortStorage(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(visibleTitles(tester).first, 'Dark mode for the public board');
    });

    testWidgets('an AppBar button drives a list without its toolbar',
        (tester) async {
      final controller = FeedbackListController();
      addTearDown(controller.dispose);
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(
          list: FeedbackList(controller: controller, showToolbar: false),
          actions: [FeedbackSortFilterButton(controller: controller)],
        ),
      );
      expect(find.byType(TextField), findsNothing);
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);

      await openSheet(tester);
      await tapInSheet(tester, find.widgetWithText(FilterChip, 'Bug Reports'));
      await closeSheet(tester);

      expect(controller.categoryFilter, FeedbackCategory.bugReport);
      expect(find.text('1'), findsOneWidget, reason: 'badge count');
      expect(visibleTitles(tester), [
        'Selected request disappears in iPad split view after rotating',
        'Draft is lost when the network drops',
      ]);
    });
  });

  group('voting', () {
    testWidgets('a vote updates at once and the card does not move',
        (tester) async {
      usePhoneSurface(tester);
      final server = FakeFeedbackServer([
        fixtureItem(id: 'a', title: 'First', voteCount: 10, daysAgo: 1),
        fixtureItem(id: 'b', title: 'Second', voteCount: 10, daysAgo: 2),
      ]);
      final votes = <VoteResponse>[];
      await pumpWithServer(
        tester,
        server,
        materialHost(
          list:
              FeedbackList(onVoteChange: (_, response) => votes.add(response)),
        ),
      );
      expect(visibleTitles(tester), ['First', 'Second']);

      await tester.tap(
        find.descendant(
          of: capsuleOf('Second'),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pump();
      expect(
        find.descendant(of: capsuleOf('Second'), matching: find.text('11')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(votes.single.voteCount, 11);
      expect(
        visibleTitles(tester),
        ['First', 'Second'],
        reason: 'a vote never reorders the list under the reader',
      );

      final kit =
          FeedbackKitProvider.of(tester.element(find.byType(FeedbackList)));
      await kit.feedbackList.refresh();
      await tester.pumpAndSettle();
      expect(
        visibleTitles(tester),
        ['Second', 'First'],
        reason: 'a reload applies the sort again',
      );
    });

    testWidgets('a failed vote rolls back and says so', (tester) async {
      usePhoneSurface(tester);
      final server = FakeFeedbackServer(showcaseFixture())
        ..failVotes = true
        ..voteLatency = const Duration(milliseconds: 300);
      await pumpWithServer(
        tester,
        server,
        materialHost(list: const FeedbackList()),
      );

      final capsule = capsuleOf('Export requests to CSV');
      await tester.tap(
        find.descendant(of: capsule, matching: find.byType(FilledButton)),
      );
      await tester.pump();
      expect(
        find.descendant(of: capsule, matching: find.text('143')),
        findsOneWidget,
        reason: 'the count moves before the server answers',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: capsule, matching: find.text('142')),
        findsOneWidget,
      );
      expect(
        find.text("Your vote couldn't be saved. Try again."),
        findsOneWidget,
      );
    });

    testWidgets('a closed request shows its count but no button',
        (tester) async {
      final handle = tester.ensureSemantics();
      usePhoneSurface(tester, size: const Size(412, 3000));
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(list: const FeedbackList()),
      );

      final closed = capsuleOf('Email me when a request I voted for ships');
      expect(
        find.descendant(of: closed, matching: find.byType(ButtonStyleButton)),
        findsNothing,
      );
      expect(
        tester.getSemantics(closed),
        isSemantics(
          label: '51 votes',
          value: 'Voting is closed',
          isButton: false,
          hasTapAction: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('vote buttons carry label, state and action', (tester) async {
      final handle = tester.ensureSemantics();
      usePhoneSurface(tester);
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(list: const FeedbackList()),
      );

      expect(
        tester.getSemantics(capsuleOf('Export requests to CSV')),
        isSemantics(
          label: '142 votes',
          value: 'Not voted',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
          onTapHint: 'vote',
        ),
      );
      expect(
        tester.getSemantics(capsuleOf('Dark mode for the public board')),
        isSemantics(
          label: '186 votes',
          value: 'Voted',
          isButton: true,
          onTapHint: 'remove your vote',
        ),
      );
      handle.dispose();
    });

    testWidgets('allowUndoVote false locks a given vote', (tester) async {
      final handle = tester.ensureSemantics();
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(list: const FeedbackList(allowUndoVote: false)),
      );

      final voted = capsuleOf('Dark mode for the public board');
      expect(
        tester.getSemantics(voted),
        isSemantics(value: 'Voted', isButton: true, hasTapAction: false),
      );
      await tester.tap(voted, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(server.requests.where((r) => r.method == 'DELETE'), isEmpty);
      handle.dispose();
    });

    testWidgets('the card reads as one element with a vote action',
        (tester) async {
      final handle = tester.ensureSemantics();
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(list: FeedbackList(onFeedbackTap: (_) {})),
      );

      final node = tester.getSemantics(cardTitled('Export requests to CSV'));
      expect(
        node.label,
        'Approved, Export requests to CSV, A spreadsheet of title, status, '
        'votes and comments before each planning session., Improvement, '
        '11 comments, 142 votes, Not voted',
      );
      final data = node.getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      final custom = data.customSemanticsActionIds!
          .map(CustomSemanticsAction.getAction)
          .whereType<CustomSemanticsAction>()
          .toList();
      expect(
        custom.where((a) => a.action == SemanticsAction.tap).single.hint,
        'view details',
      );
      expect(custom.map((a) => a.label), contains('Vote'));
      handle.dispose();
    });
  });

  group('options', () {
    testWidgets('hidden parts are left out of the card', (tester) async {
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(
          list: const FeedbackList(
            showVoteCount: false,
            showStatusBadge: false,
            showCategoryBadge: false,
            showCommentCount: false,
          ),
        ),
      );
      expect(find.byType(ShowcaseVoteCapsule), findsNothing);
      expect(find.textContaining('In Progress'), findsNothing);
      expect(find.text('Dark mode for the public board'), findsOneWidget);
      expect(find.text('Feature Request'), findsNothing);
      expect(find.text('24'), findsNothing);
    });

    testWidgets('the sheet hides filters the host turned off', (tester) async {
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(
          list: const FeedbackList(
            showStatusFilter: false,
            showCategoryFilter: false,
          ),
        ),
      );
      await openSheet(tester);
      expect(find.byType(ChoiceChip), findsNWidgets(4));
      expect(find.byType(FilterChip), findsNothing);
    });
  });

  group('hosts', () {
    testWidgets('a Cupertino host renders and opens the sheet', (tester) async {
      usePhoneSurface(tester);
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        cupertinoHost(list: const FeedbackList()),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ShowcaseCard), findsWidgets);

      await openSheet(tester);
      await tapInSheet(tester, find.widgetWithText(FilterChip, 'Approved'));
      expect(tester.takeException(), isNull);
      await closeSheet(tester);
      expect(visibleTitles(tester), [
        'Export requests to CSV',
        'Draft is lost when the network drops',
      ]);

      // A vote failure needs no ScaffoldMessenger to roll back.
      server.failVotes = true;
      await tester.tap(capsuleOf('Export requests to CSV'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: capsuleOf('Export requests to CSV'),
          matching: find.text('142'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a bare widget tree renders without a sort button',
        (tester) async {
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        const FeedbackKitProvider(
          apiKey: 'test-key',
          userId: 'reader-1',
          baseUrl: 'https://feedbackkit.test/api/v1',
          child: FeedbackList(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ShowcaseCard), findsWidgets);
      expect(find.byTooltip('Sort & Filter'), findsNothing);
      await tester.enterText(find.byType(TextField), 'csv');
      await tester.pumpAndSettle();
      expect(visibleTitles(tester), ['Export requests to CSV']);
    });

    testWidgets('a Material 2 host still gets Material 3 cards',
        (tester) async {
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(
          list: const FeedbackList(),
          // ignore: deprecated_member_use
          theme: ThemeData(useMaterial3: false, primarySwatch: Colors.teal),
        ),
      );
      final context = tester.element(find.byType(ShowcaseCard).first);
      expect(Theme.of(context).useMaterial3, isTrue);
    });

    testWidgets('Arabic lays the cards out right to left', (tester) async {
      usePhoneSurface(tester);
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(list: const FeedbackList(), appLocale: 'ar'),
      );

      final card = cardTitled('Export requests to CSV');
      expect(Directionality.of(tester.element(card)), TextDirection.rtl);
      final cardRect = tester.getRect(card);
      final capsule = tester.getRect(capsuleOf('Export requests to CSV'));
      expect(
        capsule.center.dx,
        lessThan(cardRect.center.dx),
        reason: 'the vote button sits at the trailing (left) end',
      );
      expect(find.textContaining('موافق عليه'), findsWidgets);
    });

    testWidgets('a brand primary tints the vote button', (tester) async {
      final server = FakeFeedbackServer(showcaseFixture());
      await pumpWithServer(
        tester,
        server,
        materialHost(
          list: const FeedbackList(),
          kitTheme: const FeedbackKitTheme(primaryColor: Color(0xFFE11D48)),
        ),
      );
      final scheme =
          Theme.of(tester.element(find.byType(ShowcaseCard).first)).colorScheme;
      final hostScheme =
          Theme.of(tester.element(find.byType(AppBar))).colorScheme;
      expect(scheme.primary, isNot(hostScheme.primary));
      expect(scheme.surface, hostScheme.surface);
    });
  });

  group('accessibility guidelines', () {
    for (final brightness in Brightness.values) {
      testWidgets(
          'meets tap target, label and contrast guidance '
          '(${brightness.name})', (tester) async {
        final handle = tester.ensureSemantics();
        usePhoneSurface(tester);
        final server = FakeFeedbackServer(showcaseFixture());
        await pumpWithServer(
          tester,
          server,
          materialHost(
            list: FeedbackList(onFeedbackTap: (_) {}),
            brightness: brightness,
          ),
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    for (final scale in [1.3, 2.0]) {
      testWidgets('lays out without overflow at ${scale}x text',
          (tester) async {
        usePhoneSurface(tester, size: const Size(360, 3000));
        final server = FakeFeedbackServer(showcaseFixture());
        await pumpWithServer(
          tester,
          server,
          materialHost(list: const FeedbackList(), textScale: scale),
        );
        expect(tester.takeException(), isNull);
        await openSheet(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

class _BrokenSortStorage extends FeedbackKitStorage {
  @override
  Future<String?> getListSort() async => throw StateError('unreadable');

  @override
  Future<void> setListSort(String sort) async => throw StateError('unwritable');
}
