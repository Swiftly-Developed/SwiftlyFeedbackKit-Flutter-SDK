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
    return _overrides[key] ??
        _translations[_locale]?[key] ??
        _en[key] ??
        key;
  }

  /// Set the current locale.
  static void setLocale(String locale) {
    _locale = locale;
  }

  /// Get the current locale.
  static String get locale => _locale;

  /// Register custom translations for a locale.
  static void registerTranslations(
      String locale, Map<String, String> strings) {
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
  };
}
