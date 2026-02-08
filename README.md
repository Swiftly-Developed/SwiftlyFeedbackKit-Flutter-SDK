# FeedbackKit Flutter SDK

Flutter SDK for [FeedbackKit](https://feedbackkit.app) - A feedback collection platform for your apps.

## Features

- **Easy Integration**: Simple provider-based setup with `FeedbackKitProvider`
- **Pre-built Widgets**: Ready-to-use `FeedbackList`, `FeedbackCard`, `SubmitFeedbackView`, and more
- **Theming**: Fully customizable themes with light and dark mode support
- **Optimistic Updates**: Vote buttons update instantly for great UX
- **Type-Safe**: Full type safety with Dart's strong typing

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  feedbackkit_flutter: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Wrap your app with FeedbackKitProvider

```dart
import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';

void main() {
  runApp(
    FeedbackKitProvider(
      apiKey: 'your-api-key',
      child: MyApp(),
    ),
  );
}
```

### 2. Display the feedback list

```dart
class FeedbackPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feedback')),
      body: FeedbackList(
        onFeedbackTap: (feedback) {
          // Navigate to detail view
        },
      ),
    );
  }
}
```

### 3. Add a submit feedback form

```dart
SubmitFeedbackView(
  onSubmitted: (feedback) {
    // Handle submission
    Navigator.pop(context);
  },
  onCancel: () {
    Navigator.pop(context);
  },
)
```

## Configuration

### FeedbackKitProvider Options

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `apiKey` | `String` | Yes | Your FeedbackKit API key |
| `baseUrl` | `String` | No | Custom API URL (defaults to production) |
| `userId` | `String` | No | Initial user ID for the session |
| `theme` | `FeedbackKitTheme` | No | Custom theme configuration |

### Theming

```dart
FeedbackKitProvider(
  apiKey: 'your-api-key',
  theme: FeedbackKitTheme(
    primaryColor: Color(0xFF6366F1),
    backgroundColor: Color(0xFFF9FAFB),
    cardBackgroundColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF111827),
    secondaryTextColor: Color(0xFF6B7280),
    borderRadius: 12.0,
    spacing: 8.0,
    statusColors: StatusColors(
      pending: Color(0xFF6B7280),
      approved: Color(0xFF3B82F6),
      inProgress: Color(0xFFF97316),
      testflight: Color(0xFF06B6D4),
      completed: Color(0xFF22C55E),
      rejected: Color(0xFFEF4444),
    ),
    categoryColors: CategoryColors(
      featureRequest: Color(0xFF8B5CF6),
      bugReport: Color(0xFFEF4444),
      improvement: Color(0xFF3B82F6),
      other: Color(0xFF6B7280),
    ),
  ),
  child: MyApp(),
)
```

Use the dark theme preset:

```dart
theme: FeedbackKitTheme.dark,
```

## Widgets

### FeedbackList

Displays a scrollable list of feedback items with pull-to-refresh.

```dart
FeedbackList(
  autoLoad: true,
  onFeedbackTap: (feedback) {},
  onVoteChange: (feedback, response) {},
  emptyBuilder: (context) => Text('No feedback yet'),
  errorBuilder: (context, error) => Text('Error: $error'),
  loadingBuilder: (context) => CircularProgressIndicator(),
)
```

### FeedbackCard

A card displaying a single feedback item.

```dart
FeedbackCard(
  feedback: feedback,
  onTap: () {},
  onVoteChange: (response) {},
)
```

### FeedbackDetailView

Full detail view with comments.

```dart
FeedbackDetailView(
  feedback: feedback,
  onVoteChange: (response) {},
)
```

### SubmitFeedbackView

Form for submitting new feedback.

```dart
SubmitFeedbackView(
  initialCategory: FeedbackCategory.featureRequest,
  onSubmitted: (feedback) {},
  onCancel: () {},
)
```

### StatusBadge / CategoryBadge

Badges for displaying status and category.

```dart
StatusBadge(status: FeedbackStatus.approved)
CategoryBadge(category: FeedbackCategory.bugReport)
```

### VoteButton

Button for voting with optimistic updates.

```dart
VoteButton(
  feedback: feedback,
  size: VoteButtonSize.medium,
  showCount: true,
  onVoteChange: (response) {},
)
```

## Direct API Access

Access the API client directly for custom implementations:

```dart
final context = FeedbackKitProvider.of(context);

// List feedback
final feedbackItems = await context.client.feedback.list(
  ListFeedbackOptions(
    status: FeedbackStatus.approved,
    category: FeedbackCategory.featureRequest,
  ),
);

// Create feedback
final feedback = await context.client.feedback.create(
  CreateFeedbackRequest(
    title: 'New feature',
    description: 'Description here',
    category: FeedbackCategory.featureRequest,
  ),
);

// Vote
final response = await context.client.votes.vote(feedbackId);

// Unvote
final response = await context.client.votes.unvote(feedbackId);

// List comments
final comments = await context.client.comments.list(feedbackId);

// Add comment
final comment = await context.client.comments.create(
  feedbackId,
  CreateCommentRequest(content: 'Great idea!'),
);

// Track events
await context.client.events.trackEvent(
  'feedback_viewed',
  properties: {'feedbackId': feedbackId},
);
```

## User Management

Set a user ID to associate feedback and votes with a user:

```dart
// Via provider
FeedbackKitProvider(
  apiKey: 'your-api-key',
  userId: 'user-123',
  child: MyApp(),
)

// Or programmatically
final context = FeedbackKitProvider.of(context);
await context.setUserId('user-123');
```

Register user details:

```dart
await context.client.users.register(
  RegisterUserRequest(
    id: 'user-123',
    email: 'user@example.com',
    name: 'John Doe',
  ),
);
```

## Error Handling

The SDK throws specific exceptions for different error cases:

```dart
try {
  await context.client.feedback.create(request);
} on AuthenticationError catch (e) {
  // Invalid API key (401)
} on PaymentRequiredError catch (e) {
  // Upgrade required (402)
} on ForbiddenError catch (e) {
  // Access denied (403)
} on NotFoundError catch (e) {
  // Resource not found (404)
} on ValidationError catch (e) {
  // Invalid input (400)
} on NetworkError catch (e) {
  // Connection issues
} on FeedbackKitError catch (e) {
  // Other errors
}
```

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

Make sure to replace `'your-api-key-here'` with your actual API key from [feedbackkit.app](https://feedbackkit.app).

## Requirements

- Flutter 3.10.0 or higher
- Dart 3.0.0 or higher

## License

MIT License - see [LICENSE](LICENSE) for details.
