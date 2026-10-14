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
      if (email != null) 'user_email': email,
      if (subscribeToMailingList != null)
        'subscribe_to_mailing_list': subscribeToMailingList,
      if (mailingListEmailTypes != null)
        'mailing_list_email_types': mailingListEmailTypes,
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

List<FeedbackItem> _legacyFeedbackRows(dynamic data) {
  return decodeFeedbackListTolerantly(data);
}

int? _jsonInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

class _FeedbackPage {
  final List<FeedbackItem> items;
  final int page;
  final int perPage;
  final int totalPages;
  final bool legacy;

  const _FeedbackPage({
    required this.items,
    required this.page,
    required this.perPage,
    required this.totalPages,
    required this.legacy,
  });

  factory _FeedbackPage.legacy(List<FeedbackItem> items) {
    return _FeedbackPage(
      items: items,
      page: 1,
      perPage: items.length,
      totalPages: 1,
      legacy: true,
    );
  }
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

  /// Lists feedback for the project.
  ///
  /// When [ListFeedbackOptions.page] is omitted, every page is requested and
  /// concatenated. A JSON array is the previous server and is already complete.
  Future<List<FeedbackItem>> list([ListFeedbackOptions? options]) async {
    final first = await _page(options, page: options?.page, perPage: options?.perPage);
    if (first.legacy || options?.page != null) {
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
      final more = await _page(options, page: next, perPage: size);
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

  Future<_FeedbackPage> _page(
    ListFeedbackOptions? options, {
    int? page,
    int? perPage,
  }) {
    final params = <String, String?>{};
    if (options != null) {
      if (options.status != null) {
        params['status'] = options.status!.toJson();
      }
      if (options.category != null) {
        params['category'] = options.category!.toJson();
      }
    }
    params['paged'] = '1';
    if (page != null) {
      params['page'] = page.toString();
    }
    if (perPage != null) {
      params['per_page'] = perPage.toString();
    }
    return _http.get<_FeedbackPage>(
      '/feedbacks',
      params: params,
      decoder: (data) {
        if (data is List) {
          return _FeedbackPage.legacy(_legacyFeedbackRows(data));
        }
        if (data is Map) {
          final rows = data['items'];
          final items = rows is List
              ? decodeFeedbackListTolerantly(rows)
              : <FeedbackItem>[];
          final meta = data['meta'];
          final metaMap = meta is Map ? meta : const <String, dynamic>{};
          return _FeedbackPage(
            items: items,
            page: _jsonInt(metaMap['page']) ?? 1,
            perPage: _jsonInt(metaMap['per_page']) ?? items.length,
            totalPages: _jsonInt(metaMap['total_pages']) ?? 1,
            legacy: false,
          );
        }
        return _FeedbackPage.legacy(const <FeedbackItem>[]);
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
    final userId = _http.userId?.trim();
    if (userId != null && userId.isNotEmpty) {
      body['user_id'] = userId;
    }
    return _http.post<FeedbackItem>(
      '/feedbacks',
      body: body,
      decoder: (data) => FeedbackItem.fromJson(data as Map<String, dynamic>),
    );
  }
}
