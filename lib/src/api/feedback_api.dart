import '../http/http_client.dart';
import '../models/feedback.dart' show FeedbackItem;
import '../models/feedback_category.dart';
import '../models/feedback_status.dart';
import '../models/unknown_enum_value_exception.dart';

/// Request object for creating feedback.
class CreateFeedbackRequest {
  /// Title of the feedback.
  final String title;

  /// Detailed description.
  final String description;

  /// Category of the feedback.
  final FeedbackCategory category;

  /// Optional email for notifications.
  final String? email;

  /// Whether the user opts in to the mailing list.
  final bool? subscribeToMailingList;

  /// Email preference types (e.g. ["operational", "marketing"]). Defaults to both when null.
  final List<String>? mailingListEmailTypes;

  const CreateFeedbackRequest({
    required this.title,
    required this.description,
    required this.category,
    this.email,
    this.subscribeToMailingList,
    this.mailingListEmailTypes,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category.toJson(),
      if (email != null) 'email': email,
      if (subscribeToMailingList != null)
        'subscribeToMailingList': subscribeToMailingList,
      if (mailingListEmailTypes != null)
        'mailingListEmailTypes': mailingListEmailTypes,
    };
  }
}

/// Options for listing feedback.
class ListFeedbackOptions {
  /// Filter by status.
  final FeedbackStatus? status;

  /// Filter by category.
  final FeedbackCategory? category;

  /// Page number (1-indexed).
  final int? page;

  /// Number of items per page.
  final int? perPage;

  const ListFeedbackOptions({
    this.status,
    this.category,
    this.page,
    this.perPage,
  });
}

/// Decodes a JSON array of feedback rows with the tolerant element-drop
/// contract (`AGENTS.md` line 82): a row whose `status` or `category` carries a
/// token this SDK version does not know — an [UnknownEnumValueException] — is
/// dropped, and every other row survives in order. A genuinely malformed row
/// (missing required key, type mismatch on a known field) still throws, because
/// swallowing it would turn a decode regression into a silently short list.
///
/// This is the single definition of the wrapper: `FeedbackApi.list` routes
/// through it, and `QA-UNIT10-SDK-PARITY`'s `-06` asserts it against the
/// server-generated tolerance corpus.
List<FeedbackItem> decodeFeedbackListTolerantly(List<dynamic> data) {
  final items = <FeedbackItem>[];
  for (final item in data) {
    try {
      items.add(FeedbackItem.fromJson(item as Map<String, dynamic>));
    } on UnknownEnumValueException {
      // Dropped: the row is from a newer server vocabulary.
    }
  }
  return items;
}

/// API client for feedback operations.
class FeedbackApi {
  final FeedbackKitHttpClient _http;

  FeedbackApi(this._http);

  /// Lists all feedback for the project.
  Future<List<FeedbackItem>> list([ListFeedbackOptions? options]) async {
    final params = <String, String?>{};

    if (options != null) {
      if (options.status != null) {
        params['status'] = options.status!.toJson();
      }
      if (options.category != null) {
        params['category'] = options.category!.toJson();
      }
      if (options.page != null) {
        params['page'] = options.page.toString();
      }
      if (options.perPage != null) {
        params['per_page'] = options.perPage.toString();
      }
    }

    return _http.get<List<FeedbackItem>>(
      '/feedbacks',
      params: params.isEmpty ? null : params,
      decoder: (data) {
        if (data is List) {
          return decodeFeedbackListTolerantly(data);
        }
        return <FeedbackItem>[];
      },
    );
  }

  /// Gets a single feedback item by ID.
  Future<FeedbackItem> get(String id) async {
    return _http.get<FeedbackItem>(
      '/feedbacks/$id',
      decoder: (data) => FeedbackItem.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Creates a new feedback item.
  Future<FeedbackItem> create(CreateFeedbackRequest request) async {
    final body = request.toJson();
    // Include userId from the HTTP client if available
    if (_http.userId != null) {
      body['userId'] = _http.userId;
    }
    return _http.post<FeedbackItem>(
      '/feedbacks',
      body: body,
      decoder: (data) => FeedbackItem.fromJson(data as Map<String, dynamic>),
    );
  }
}
