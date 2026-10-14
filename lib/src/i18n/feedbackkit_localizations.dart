import 'dart:ui' as ui;

import 'translations/ar.dart';
import 'translations/de.dart';
import 'translations/es.dart';
import 'translations/fr.dart';
import 'translations/it.dart';
import 'translations/ja.dart';
import 'translations/ko.dart';
import 'translations/pt_br.dart';
import 'translations/ru.dart';
import 'translations/zh_hans.dart';

/// FeedbackKit localization system.
///
/// Provides translated strings with automatic locale detection
/// and support for consumer overrides.
///
/// ```dart
/// // Get a translated string
/// FeedbackKitLocalizations.t('feedback.list.empty')
///
/// // Set locale manually
/// FeedbackKitLocalizations.setLocale('es');
///
/// // Register custom translations
/// FeedbackKitLocalizations.registerTranslations('es', {'feedback.list.empty': 'Custom'});
/// ```
class FeedbackKitLocalizations {
  FeedbackKitLocalizations._();

  static String _locale = _detectLocale();
  static Map<String, String> _overrides = {};

  static final Map<String, Map<String, String>> _translations = {
    'en': _en,
    'es': esTranslations,
    'fr': frTranslations,
    'de': deTranslations,
    'ja': jaTranslations,
    'zh-Hans': zhHansTranslations,
    'pt-BR': ptBRTranslations,
    'ko': koTranslations,
    'it': itTranslations,
    'ar': arTranslations,
    'ru': ruTranslations,
  };

  /// Get a translated string by key.
  ///
  /// Lookup order:
  /// 1. Consumer overrides
  /// 2. Built-in translation for current locale
  /// 3. English fallback
  static String t(String key) {
    return _overrides[key] ?? _translations[_locale]?[key] ?? _en[key] ?? key;
  }

  /// Set the current locale.
  static void setLocale(String locale) {
    _locale = locale;
  }

  /// Get the current locale.
  static String get locale => _locale;

  /// Layout direction for the active locale.
  ///
  /// Arabic is right to left. Every other catalog shipped with the SDK is
  /// left to right. A language tag such as `ar-SA` follows its language.
  static ui.TextDirection get textDirection {
    final language = _locale.split(RegExp('[-_]')).first.toLowerCase();
    return language == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr;
  }

  /// Relative age of [date], using the active catalog.
  ///
  /// [now] is the clock. Tests pass a fixed value.
  static String relativeTime(DateTime date, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(date);
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}${t('time.yearsAgo')}';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}${t('time.monthsAgo')}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}${t('time.daysAgo')}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}${t('time.hoursAgo')}';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}${t('time.minutesAgo')}';
    }
    return t('time.justNow');
  }

  /// Localized comment count for a feedback card.
  static String commentCountLabel(int count) {
    if (count == 1) return t('feedback.card.comment.one');
    return t('feedback.card.comment.other').replaceAll('{count}', '$count');
  }

  /// Plural form of [key] for [count], with `{count}` replaced by the
  /// formatted number.
  ///
  /// Looks up `<key>.<category>`, where the category follows the CLDR plural
  /// rules of the active locale (`zero`, `one`, `two`, `few`, `many`), and
  /// falls back to `<key>.other`.
  static String plural(String key, int count) {
    final category = pluralCategory(count);
    final template = _lookup('$key.$category') ?? t('$key.other');
    return template.replaceAll('{count}', formatCount(count));
  }

  /// CLDR plural category of [count] in the active locale.
  ///
  /// Covers the integer rules of the eleven shipped locales. Japanese,
  /// Korean and Chinese have one form. Arabic has six. Russian has four.
  static String pluralCategory(int count) {
    final n = count.abs();
    switch (_language) {
      case 'ja':
      case 'ko':
      case 'zh':
        return 'other';
      case 'ar':
        if (n == 0) return 'zero';
        if (n == 1) return 'one';
        if (n == 2) return 'two';
        if (n % 100 >= 3 && n % 100 <= 10) return 'few';
        if (n % 100 >= 11 && n % 100 <= 99) return 'many';
        return 'other';
      case 'ru':
        if (n % 10 == 1 && n % 100 != 11) return 'one';
        if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 12 || n % 100 > 14)) {
          return 'few';
        }
        return 'many';
      case 'fr':
      case 'pt':
        return n == 0 || n == 1 ? 'one' : 'other';
      default:
        return n == 1 ? 'one' : 'other';
    }
  }

  /// [count] with the active locale's digit grouping, such as `1,234` in
  /// English and `1.234` in German. Digits stay Latin in every locale.
  static String formatCount(int count) {
    final digits = count.abs().toString();
    final separator = _groupSeparators[_language] ?? ',';
    // Spanish leaves four-digit numbers ungrouped.
    final minimumGrouping = _language == 'es' ? 5 : 4;
    if (digits.length < minimumGrouping) {
      return count < 0 ? '-$digits' : digits;
    }
    final buffer = StringBuffer(count < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(separator);
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static const Map<String, String> _groupSeparators = {
    'de': '.',
    'es': '.',
    'it': '.',
    'pt': '.',
    'fr': '\u202F',
    'ru': '\u00A0',
  };

  static String get _language => _locale.split(RegExp('[-_]')).first.toLowerCase();

  static String? _lookup(String key) =>
      _overrides[key] ?? _translations[_locale]?[key] ?? _en[key];

  /// Register custom translations for a locale.
  static void registerTranslations(String locale, Map<String, String> strings) {
    _translations[locale] = {
      ...?_translations[locale],
      ...strings,
    };
  }

  /// Set override strings (highest priority).
  static void setOverrideStrings(Map<String, String> strings) {
    _overrides = {..._overrides, ...strings};
  }

  static String _detectLocale() {
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      final tag = locale.toLanguageTag(); // e.g. "zh-Hans-CN", "pt-BR"

      if (_translations.containsKey(tag)) return tag;

      // Try language-script (e.g. "zh-Hans")
      if (locale.scriptCode != null) {
        final langScript = '${locale.languageCode}-${locale.scriptCode}';
        if (_translations.containsKey(langScript)) return langScript;
      }

      // Try language-country (e.g. "pt-BR")
      if (locale.countryCode != null) {
        final langCountry = '${locale.languageCode}-${locale.countryCode}';
        if (_translations.containsKey(langCountry)) return langCountry;
      }

      // Try base language
      if (_translations.containsKey(locale.languageCode)) {
        return locale.languageCode;
      }

      return 'en';
    } catch (_) {
      return 'en';
    }
  }

  /// Default English strings.
  static const Map<String, String> _en = {
    // Feedback List
    'feedback.list.title': 'Feedback',
    'feedback.list.empty': 'No feedback yet',
    'feedback.list.empty.description': 'Be the first to submit feedback!',
    'feedback.list.loading': 'Loading...',
    'feedback.list.error': 'Failed to load feedback',
    'feedback.list.error.retry': 'Retry',

    // Submit Feedback
    'feedback.submit.title': 'Submit Feedback',
    'feedback.submit.button': 'Submit',
    'feedback.submit.submitting': 'Submitting...',

    // Feedback Detail
    'feedback.detail.title': 'Details',
    'feedback.detail.comments': 'Comments',
    'feedback.detail.comments.empty':
        'No comments yet. Be the first to comment!',
    'feedback.detail.comments.add': 'Add Comment',
    'feedback.detail.comments.sending': 'Sending...',
    'feedback.detail.comments.loading': 'Loading comments...',
    'feedback.detail.comments.error': 'Failed to load comments',
    'feedback.detail.submitted': 'Submitted',
    'feedback.detail.anonymous': 'Anonymous',

    // Form Fields
    'feedback.form.title': 'Title',
    'feedback.form.title.placeholder': 'Brief summary of your feedback',
    'feedback.form.title.error': 'Please enter a title',
    'feedback.form.description': 'Description',
    'feedback.form.description.placeholder':
        'Provide more details about your feedback',
    'feedback.form.description.error': 'Please enter a description',
    'feedback.form.category': 'Category',
    'feedback.form.email': 'Email (optional)',
    'feedback.form.email.description': 'Get notified when there are updates',
    'feedback.form.email.placeholder': 'your@email.com',
    'feedback.form.mailingList':
        'Subscribe to our mailing list for product updates',
    'feedback.form.mailingList.operational':
        'Operational emails (status updates, account)',
    'feedback.form.mailingList.marketing':
        'Marketing emails (newsletters, promotions)',

    // Buttons
    'button.cancel': 'Cancel',
    'button.submit': 'Submit',
    'button.send': 'Send',
    'button.vote': 'Vote',
    'button.voted': 'Voted',

    // Comment
    'comment.author.team': 'Team',
    'comment.author.user': 'User',

    // Status
    'status.pending': 'Pending',
    'status.approved': 'Approved',
    'status.inProgress': 'In Progress',
    'status.testflight': 'TestFlight',
    'status.completed': 'Completed',
    'status.rejected': 'Rejected',

    // Categories
    'category.featureRequest': 'Feature Request',
    'category.bugReport': 'Bug Report',
    'category.improvement': 'Improvement',
    'category.other': 'Other',

    // Errors
    'error.title': 'Error',
    'error.ok': 'OK',
    'error.generic': 'An error occurred',

    // Time
    'time.yearsAgo': 'y ago',
    'time.monthsAgo': 'mo ago',
    'time.daysAgo': 'd ago',
    'time.hoursAgo': 'h ago',
    'time.minutesAgo': 'm ago',
    'time.justNow': 'Just now',

    'feedback.card.comment.one': '1 comment',
    'feedback.card.comment.other': '{count} comments',

    // Feedback list: search, sort and filter
    'feedback.list.search.placeholder': 'Search Feedback',
    'feedback.list.search.clear': 'Clear Search',
    'feedback.list.search.empty.title': 'No Results',
    'feedback.list.search.empty.description': 'No feedback matches your search.',
    'feedback.list.sortAndFilter': 'Sort & Filter',
    'feedback.list.sortBy': 'Sort By',
    'feedback.list.filter.status': 'Status',
    'feedback.list.filter.category': 'Category',
    'feedback.list.filter.allStatuses': 'All Statuses',
    'feedback.list.filter.allCategories': 'All Categories',
    'feedback.list.filter.clear': 'Clear Filters',
    'feedback.list.filter.join': '{category}, {status}',
    'feedback.list.filter.remove': 'Remove {filter}',
    'feedback.list.filteredBy': 'Filtered by {filters}',
    'feedback.list.filteredBy.prefix': 'Filtered by',
    'feedback.list.filteredBy.clear': 'Clear',
    'feedback.list.filteredEmpty.title': 'No Matching Requests',
    'feedback.list.filteredEmpty.description':
        'No request matches these filters.',
    'feedback.vote.error': "Your vote couldn't be saved. Try again.",

    // Sort
    'sort.votes': 'Votes',
    'sort.newest': 'Newest',
    'sort.oldest': 'Oldest',
    'sort.comments': 'Comments',

    // Category names for a set of items
    'category.plural.featureRequest': 'Feature Requests',
    'category.plural.bugReport': 'Bug Reports',
    'category.plural.improvement': 'Improvements',
    'category.plural.other': 'Other',

    // Accessibility
    'accessibility.vote.count.one': '{count} vote',
    'accessibility.vote.count.other': '{count} votes',
    'accessibility.comment.count.one': '{count} comment',
    'accessibility.comment.count.other': '{count} comments',
    'accessibility.voted': 'Voted',
    'accessibility.notVoted': 'Not voted',
    'accessibility.voting.closed': 'Voting is closed',
    'accessibility.vote.hint': 'Double tap to vote',
    'accessibility.unvote.hint': 'Double tap to remove your vote',
    'accessibility.viewDetails': 'Double tap to view details',
    'accessibility.voted.locked': "You've voted. Votes can't be removed.",
    'accessibility.vote.tapHint': 'vote',
    'accessibility.unvote.tapHint': 'remove your vote',
    'accessibility.viewDetails.tapHint': 'view details',
    'accessibility.unvote.action': 'Remove vote',
    'accessibility.filter.clear': 'Clear filters',
  };
}
