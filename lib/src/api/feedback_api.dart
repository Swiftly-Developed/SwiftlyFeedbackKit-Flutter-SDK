import '../http/http_client.dart';
import '../models/feedback.dart' show FeedbackItem;
import '../models/feedback_category.dart';
import '../models/feedback_status.dart';

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

  const CreateFeedbackRequest({
    required this.title,
    required this.description,
    required this.category,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category.toJson(),
      if (email != null) 'email': email,
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
          return data
              .map((item) => FeedbackItem.fromJson(item as Map<String, dynamic>))
              .toList();
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
