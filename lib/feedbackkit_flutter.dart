/// Flutter SDK for FeedbackKit - A feedback collection platform for your apps.
library feedbackkit_flutter;

// Client
export 'src/client/feedbackkit_client.dart';
export 'src/client/feedbackkit_config.dart';

// API
export 'src/api/comments_api.dart' show CreateCommentRequest;
export 'src/api/feedback_api.dart'
    show CreateFeedbackRequest, ListFeedbackOptions;
export 'src/api/users_api.dart' show RegisterUserRequest;

// Models
export 'src/models/comment.dart';
export 'src/models/feedback.dart' show FeedbackItem;
export 'src/models/feedback_category.dart';
export 'src/models/feedback_status.dart';
export 'src/models/sdk_user.dart';
export 'src/models/tracked_event.dart';
export 'src/models/vote_response.dart';

// Errors
export 'src/errors/feedbackkit_error.dart';

// Internationalization
export 'src/i18n/feedbackkit_localizations.dart';

// State Management
export 'src/state/feedbackkit_provider.dart';
export 'src/state/notifiers/feedback_list_notifier.dart';
export 'src/state/notifiers/vote_notifier.dart';

// Theme
export 'src/theme/feedbackkit_theme.dart';

// Widgets
export 'src/widgets/category_badge.dart';
export 'src/widgets/feedback_card.dart';
export 'src/widgets/feedback_detail_view.dart';
export 'src/widgets/feedback_list.dart';
export 'src/widgets/status_badge.dart';
export 'src/widgets/submit_feedback_view.dart';
export 'src/widgets/vote_button.dart';
