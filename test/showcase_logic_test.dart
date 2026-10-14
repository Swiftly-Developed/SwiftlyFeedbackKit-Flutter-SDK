import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:feedbackkit_flutter/src/i18n/translations/ar.dart';
import 'package:feedbackkit_flutter/src/i18n/translations/de.dart';
import 'package:feedbackkit_flutter/src/i18n/translations/es.dart';
import 'package:feedbackkit_flutter/src/i18n/translations/fr.dart';
import 'package:feedbackkit_flutter/src/i18n/translations/it.dart';
import 'package:feedbackkit_flutter/src/i18n/translations/ja.dart';
import 'package:feedbackkit_flutter/src/i18n/translations/ko.dart';
import 'package:feedbackkit_flutter/src/i18n/translations/pt_br.dart';
import 'package:feedbackkit_flutter/src/i18n/translations/ru.dart';
import 'package:feedbackkit_flutter/src/i18n/translations/zh_hans.dart';
import 'package:feedbackkit_flutter/src/widgets/showcase/category_icon.dart';
import 'package:feedbackkit_flutter/src/widgets/showcase/showcase_contrast.dart';
import 'package:feedbackkit_flutter/src/widgets/showcase/status_glyph_shape.dart';
import 'package:feedbackkit_flutter/src/widgets/showcase/vote_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/showcase_harness.dart';

void main() {
  setUp(() => FeedbackKitLocalizations.setLocale('en'));

  group('FeedbackListController', () {
    test('starts on votes with nothing filtered', () {
      final c = FeedbackListController();
      expect(c.sort, FeedbackSortOption.votes);
      expect(c.isFiltered, isFalse);
      expect(c.activeFilterCount, 0);
      expect(c.filterSummary, isNull);
      expect(c.isSearching, isFalse);
    });

    test('counts filters but not sort or search', () {
      final c = FeedbackListController(
        sort: FeedbackSortOption.newest,
        searchQuery: 'csv',
      );
      expect(c.isFiltered, isFalse);
      c.statusFilter = FeedbackStatus.inProgress;
      expect(c.activeFilterCount, 1);
      c.categoryFilter = FeedbackCategory.bugReport;
      expect(c.activeFilterCount, 2);
      expect(c.isFiltered, isTrue);
    });

    test('summary puts the category first, then the status', () {
      final c = FeedbackListController(
        statusFilter: FeedbackStatus.inProgress,
        categoryFilter: FeedbackCategory.bugReport,
      );
      expect(c.filterSummary, 'Filtered by Bug Reports, In Progress');
      expect(c.activeFilterNames, ['Bug Reports', 'In Progress']);
      c.categoryFilter = null;
      expect(c.filterSummary, 'Filtered by In Progress');
    });

    test('clearFilters keeps the sort and the search text', () {
      final c = FeedbackListController(
        sort: FeedbackSortOption.comments,
        statusFilter: FeedbackStatus.approved,
        categoryFilter: FeedbackCategory.improvement,
        searchQuery: 'export',
      );
      var notified = 0;
      c.addListener(() => notified++);
      c.clearFilters();
      expect(c.isFiltered, isFalse);
      expect(c.sort, FeedbackSortOption.comments);
      expect(c.searchQuery, 'export');
      expect(notified, 1);
      c.clearFilters();
      expect(notified, 1, reason: 'clearing nothing does not notify');
    });

    test('apply combines status, category and search with AND', () {
      final items = showcaseFixture();
      final c = FeedbackListController(statusFilter: FeedbackStatus.inProgress);
      expect(c.apply(items).map((i) => i.id), ['f1', 'f3']);
      c.categoryFilter = FeedbackCategory.improvement;
      expect(c.apply(items).map((i) => i.id), ['f3']);
      c.searchQuery = 'dark';
      expect(c.apply(items), isEmpty);
      c.clearFilters();
      expect(c.apply(items).map((i) => i.id), ['f1']);
    });

    test('search matches the description and ignores case and accents', () {
      final items = [
        fixtureItem(id: 'a', title: 'Café menu', voteCount: 1),
        fixtureItem(id: 'b', title: 'Other', description: 'Needs a CAFE mode'),
        fixtureItem(id: 'c', title: 'Unrelated'),
      ];
      final c = FeedbackListController(searchQuery: '  cafe ');
      expect(c.apply(items).map((i) => i.id), ['a', 'b']);
      expect(FeedbackListController.foldForSearch('Ünïcödé ß'), 'unicode ss');
      expect(FeedbackListController.foldForSearch('الوضع'), 'الوضع');
    });
  });

  group('FeedbackSortOption', () {
    final items = showcaseFixture();

    List<String> sorted(FeedbackSortOption option) =>
        ([...items]..sort(option.compare)).map((i) => i.id).toList();

    test('votes, newest, oldest and comments order the fixture', () {
      expect(
        sorted(FeedbackSortOption.votes),
        ['f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9'],
      );
      expect(sorted(FeedbackSortOption.newest).first, 'f6');
      expect(sorted(FeedbackSortOption.oldest).first, 'f7');
      expect(sorted(FeedbackSortOption.comments).take(3), ['f1', 'f4', 'f7']);
    });

    test('ties fall back to newest, then id', () {
      final tied = [
        fixtureItem(id: 'b', title: 'B', voteCount: 5, daysAgo: 2),
        fixtureItem(id: 'a', title: 'A', voteCount: 5, daysAgo: 2),
        fixtureItem(id: 'c', title: 'C', voteCount: 5, daysAgo: 1),
      ]..sort(FeedbackSortOption.votes.compare);
      expect(tied.map((i) => i.id), ['c', 'a', 'b']);
    });

    test('fromName reads back name and rejects anything else', () {
      for (final option in FeedbackSortOption.values) {
        expect(FeedbackSortOption.fromName(option.name), option);
      }
      expect(FeedbackSortOption.fromName('Votes'), isNull);
      expect(FeedbackSortOption.fromName(null), isNull);
    });
  });

  group('plurals and counts', () {
    test('English one and other, with grouping', () {
      expect(
        FeedbackKitLocalizations.plural('accessibility.vote.count', 1),
        '1 vote',
      );
      expect(
        FeedbackKitLocalizations.plural('accessibility.vote.count', 1234),
        '1,234 votes',
      );
      expect(
        FeedbackKitLocalizations.plural('accessibility.vote.count', 0),
        '0 votes',
      );
    });

    test('CLDR categories per language', () {
      String category(String locale, int n) {
        FeedbackKitLocalizations.setLocale(locale);
        return FeedbackKitLocalizations.pluralCategory(n);
      }

      expect(
        [0, 1, 2, 3, 11, 100].map((n) => category('ar', n)),
        ['zero', 'one', 'two', 'few', 'many', 'other'],
      );
      expect(
        [1, 2, 5, 11, 21, 22].map((n) => category('ru', n)),
        ['one', 'few', 'many', 'many', 'one', 'few'],
      );
      expect([0, 1, 2].map((n) => category('fr', n)), ['one', 'one', 'other']);
      expect(
        [0, 1, 2].map((n) => category('pt-BR', n)),
        ['one', 'one', 'other'],
      );
      expect(category('ja', 1), 'other');
      expect(category('de', 1), 'one');
    });

    test('digit grouping follows the locale', () {
      String format(String locale, int n) {
        FeedbackKitLocalizations.setLocale(locale);
        return FeedbackKitLocalizations.formatCount(n);
      }

      expect(format('de', 1234), '1.234');
      expect(format('es', 1234), '1234');
      expect(format('es', 12345), '12.345');
      expect(format('fr', 1234567), '1\u202F234\u202F567');
      expect(format('ru', 1234), '1\u00A0234');
      expect(format('en', 999), '999');
    });
  });

  group('VotePresentation', () {
    VotePresentation resolve({
      bool show = true,
      bool skeleton = false,
      bool canVote = true,
      bool voted = false,
      bool undo = true,
    }) =>
        VotePresentation.resolve(
          showVoteCount: show,
          isSkeleton: skeleton,
          canVote: canVote,
          hasVoted: voted,
          allowUndoVote: undo,
        );

    test('resolves every row of the table', () {
      expect(resolve(show: false), VotePresentation.hidden);
      expect(resolve(skeleton: true), VotePresentation.skeleton);
      expect(resolve(canVote: false), VotePresentation.closed);
      expect(resolve(canVote: false, voted: true), VotePresentation.closed);
      expect(resolve(), VotePresentation.votable);
      expect(resolve(voted: true), VotePresentation.voted);
      expect(resolve(voted: true, undo: false), VotePresentation.votedLocked);
    });

    test('a closed request is never a button', () {
      expect(VotePresentation.closed.isButton, isFalse);
      expect(VotePresentation.closed.isInteractive, isFalse);
      expect(
        VotePresentation.closed.semanticsValueKey,
        'accessibility.voting.closed',
      );
      expect(VotePresentation.votedLocked.isButton, isTrue);
      expect(VotePresentation.votedLocked.isInteractive, isFalse);
      expect(VotePresentation.votedLocked.tapHintKey, isNull);
    });
  });

  test('every status has its own glyph shape', () {
    final shapes = FeedbackStatus.values.map(StatusGlyphShape.of).toSet();
    expect(shapes, hasLength(FeedbackStatus.values.length));
    expect(
        StatusGlyphShape.of(FeedbackStatus.completed), StatusGlyphShape.check,);
    expect(
        StatusGlyphShape.of(FeedbackStatus.rejected), StatusGlyphShape.cross,);
  });

  test('category icons are distinct and Improvement is tune', () {
    final icons = FeedbackCategory.values.map(showcaseCategoryIcon).toSet();
    expect(icons, hasLength(FeedbackCategory.values.length));
    expect(showcaseCategoryIcon(FeedbackCategory.improvement), Icons.tune);
  });

  group('ShowcaseContrast', () {
    test('black on white is 21:1', () {
      expect(
        ShowcaseContrast.ratio(Colors.black, Colors.white),
        closeTo(21, 0.01),
      );
    });

    test('ensure reaches the minimum on light and dark cards', () {
      const status = FeedbackKitTheme();
      for (final background in [
        Colors.white,
        const Color(0xFFF7F9FF),
        const Color(0xFF1D2024),
        Colors.black,
      ]) {
        for (final s in FeedbackStatus.values) {
          final color = status.statusColors.forStatus(s);
          final text = ShowcaseContrast.ensure(
            color,
            background,
            ShowcaseContrast.text,
          );
          expect(
            ShowcaseContrast.ratio(text, background),
            greaterThanOrEqualTo(4.5),
            reason: '$s on $background',
          );
        }
      }
    });

    test('a colour that already passes is unchanged', () {
      const navy = Color(0xFF0B1F5C);
      expect(ShowcaseContrast.ensure(navy, Colors.white, 4.5), navy);
    });
  });

  group('catalogs', () {
    const showcaseKeys = [
      'feedback.list.search.placeholder',
      'feedback.list.search.clear',
      'feedback.list.search.empty.title',
      'feedback.list.search.empty.description',
      'feedback.list.sortAndFilter',
      'feedback.list.sortBy',
      'feedback.list.filter.status',
      'feedback.list.filter.category',
      'feedback.list.filter.allStatuses',
      'feedback.list.filter.allCategories',
      'feedback.list.filter.clear',
      'feedback.list.filter.join',
      'feedback.list.filter.remove',
      'feedback.list.filteredBy',
      'feedback.list.filteredBy.prefix',
      'feedback.list.filteredBy.clear',
      'feedback.list.filteredEmpty.title',
      'feedback.list.filteredEmpty.description',
      'feedback.vote.error',
      'sort.votes',
      'sort.newest',
      'sort.oldest',
      'sort.comments',
      'category.plural.featureRequest',
      'category.plural.bugReport',
      'category.plural.improvement',
      'category.plural.other',
      'accessibility.vote.count.other',
      'accessibility.comment.count.other',
      'accessibility.voted',
      'accessibility.notVoted',
      'accessibility.voting.closed',
      'accessibility.vote.hint',
      'accessibility.unvote.hint',
      'accessibility.viewDetails',
      'accessibility.voted.locked',
      'accessibility.vote.tapHint',
      'accessibility.unvote.tapHint',
      'accessibility.viewDetails.tapHint',
      'accessibility.unvote.action',
      'accessibility.filter.clear',
    ];
    final catalogs = {
      'ar': arTranslations,
      'de': deTranslations,
      'es': esTranslations,
      'fr': frTranslations,
      'it': itTranslations,
      'ja': jaTranslations,
      'ko': koTranslations,
      'pt-BR': ptBRTranslations,
      'ru': ruTranslations,
      'zh-Hans': zhHansTranslations,
    };

    test('every catalog translates every Showcase key', () {
      for (final entry in catalogs.entries) {
        final missing =
            showcaseKeys.where((k) => !entry.value.containsKey(k)).toList();
        expect(missing, isEmpty, reason: entry.key);
      }
    });

    test('each catalog has the plural forms its language uses', () {
      const counts = [0, 1, 2, 3, 5, 11, 21, 100, 1001];
      for (final locale in catalogs.keys) {
        FeedbackKitLocalizations.setLocale(locale);
        for (final n in counts) {
          final category = FeedbackKitLocalizations.pluralCategory(n);
          for (final key in [
            'accessibility.vote.count',
            'accessibility.comment.count',
          ]) {
            expect(
              catalogs[locale]!.containsKey('$key.$category'),
              isTrue,
              reason: '$locale $key.$category',
            );
          }
        }
      }
    });

    test('templates keep their placeholders', () {
      for (final entry in catalogs.entries) {
        final c = entry.value;
        expect(
          c['feedback.list.filteredBy'],
          contains('{filters}'),
          reason: entry.key,
        );
        expect(
          c['feedback.list.filter.remove'],
          contains('{filter}'),
          reason: entry.key,
        );
        expect(c['feedback.list.filter.join'], contains('{category}'));
        expect(c['feedback.list.filter.join'], contains('{status}'));
        expect(c['accessibility.vote.count.other'], contains('{count}'));
      }
    });

    test('TestFlight is a product name and stays untranslated', () {
      for (final entry in catalogs.entries) {
        expect(
          entry.value['status.testflight'],
          'TestFlight',
          reason: entry.key,
        );
      }
    });
  });
}
