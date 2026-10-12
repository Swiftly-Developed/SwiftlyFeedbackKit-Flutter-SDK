# FeedbackKit Flutter SDK

> **These samples match this checkout, package version 1.2.2.** [pub.dev](https://pub.dev/packages/feedbackkit_flutter) still serves **1.0.1** (9 February 2026). `flutter pub add feedbackkit_flutter` installs that release, and the snippets below do not compile against it. The public repository [SwiftlyFeedbackKit-Flutter-SDK](https://github.com/Swiftly-Developed/SwiftlyFeedbackKit-Flutter-SDK) is at **1.1.1** (last pushed 16 August 2026) and is behind this checkout. Walk through setup in [docs/getting-started.md](docs/getting-started.md). What 1.0.1 cannot do is listed under [Published 1.0.1](#published-101).

Flutter SDK for [FeedbackKit](https://feedbackkit.app) - A feedback collection platform for your apps. The provider takes `apiKey` and `child`, plus optional `userId`, `baseUrl`, `theme`, `locale`, and `translations`. It does not take a `FeedbackKitClient`.

## Features

- **Easy Integration**: Simple provider-based setup with `FeedbackKitProvider`
- **Pre-built Widgets**: Ready-to-use `FeedbackList`, `FeedbackCard`, `SubmitFeedbackView`, and more
- **Theming**: Fully customizable themes with light and dark mode support
- **Optimistic Updates**: Vote buttons update instantly for great UX
- **Type-Safe**: Full type safety with Dart's strong typing

## Installation

This checkout is `1.2.2`. It is not on pub.dev. Depend on this directory so the snippets compile:

```yaml
dependencies:
  feedbackkit_flutter:
    path: ../SwiftlyFeedbackKit-Flutter
```

Then run:

```bash
flutter pub get
```

`flutter pub add feedbackkit_flutter` installs pub.dev **1.0.1**. A `^1.2.2` constraint does not resolve there. A git dependency on `SwiftlyFeedbackKit-Flutter-SDK` installs **1.1.1**, which is not this API. The example app already uses `path: ../`.

## Quick Start

### 1. Wrap your app with FeedbackKitProvider

```dart
import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const FeedbackKitProvider(
      apiKey: 'your-api-key',
      child: MaterialApp(
        home: FeedbackPage(),
      ),
    ),
  );
}
```

### 2. Display the feedback list

```dart
class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
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
void openSubmit(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SubmitFeedbackView(
        onSubmitted: (feedback) {
          Navigator.pop(context);
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    ),
  );
}
```

## Configuration

### FeedbackKitProvider Options

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `apiKey` | `String` | Yes | Your FeedbackKit API key |
| `child` | `Widget` | Yes | Usually your `MaterialApp` |
| `userId` | `String?` | No | Initial user ID for the session |
| `baseUrl` | `String?` | No | Defaults to the production API |
| `theme` | `FeedbackKitTheme` | No | Custom theme configuration |
| `locale` | `String?` | No | Override the catalog locale, for example `ar` or `pt-BR` |
| `translations` | `Map<String, String>?` | No | Override individual catalog strings |

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
  child: FeedbackPage(),
)
```

Use the dark theme preset:

```dart
theme: FeedbackKitTheme.dark,
```

## Widgets

### FeedbackList

Displays a scrollable list of feedback items. The first load waits until the user id is ready, so vote state matches the signed-in user.

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

`VoteButton` toggles the vote. It does not take `email` or `notifyStatusChange`. Pass those to `client.votes.vote` or `VoteNotifier.vote`. Completed and rejected statuses disable the button.

## Direct API Access

Access the API client directly for custom implementations:

```dart
final kit = FeedbackKitProvider.of(context);
const feedbackId = 'feedback-id';

// List feedback
final feedbackItems = await kit.client.feedback.list(
  const ListFeedbackOptions(
    status: FeedbackStatus.approved,
    category: FeedbackCategory.featureRequest,
  ),
);

// Create feedback. The configured user id is sent as user_id.
// email is sent as user_email. There is no userId parameter on the request.
final feedback = await kit.client.feedback.create(
  const CreateFeedbackRequest(
    title: 'New feature',
    description: 'Description here',
    category: FeedbackCategory.featureRequest,
  ),
);

// Vote
final response = await kit.client.votes.vote(feedbackId);

// Vote with a status-change email opt-in. The server stores the flag
// only together with an email. VoteButton does not send either value.
final optedIn = await kit.client.votes.vote(
  feedbackId,
  email: 'user@example.com',
  notifyStatusChange: true,
);

// Unvote. The user id is sent in the JSON body.
final removed = await kit.client.votes.unvote(feedbackId);

// List comments
final comments = await kit.client.comments.list(feedbackId);

// Add comment. userId is optional; the configured id is sent when you omit it.
// The JSON key is userId.
final comment = await kit.client.comments.create(
  feedbackId,
  const CreateCommentRequest(content: 'Great idea!'),
);

// Track events. The widgets do not call this.
await kit.client.events.trackEvent(
  PredefinedEventNames.feedbackDetail,
  properties: {'feedbackId': feedbackId},
);
```

### Metrics

The samples below sit in a method that already imported `package:flutter/foundation.dart` and bound `final kit = FeedbackKitProvider.of(context)`. `kit.client.metrics` reads the aggregates behind your project. Four operations — `summary`, `timeseries`, `breakdown` and `events` — all on the API-key surface. The 1.2.0 changelog recorded that testflight and production answered 404 for `/metrics/summary` on 25 August 2026. The development API served them. That check was not repeated here.

```dart
final series = await kit.client.metrics.timeseries(
  MetricTimeseriesOptions(
    measures: [MetricMeasure.feedbackCount, MetricMeasure.eventCount],
    granularity: MetricGranularity.day,
    days: 14,
  ),
);

for (final point in series.series) {
  // `point.bucket` is a string in the response's reporting zone. Render it
  // beside `series.meta.timezone`. DateTime.parse would relabel the bucket
  // with the device's own zone.
  final line = '${point.bucket} (${series.meta.timezone}): '
      '${point.measure(MetricMeasure.feedbackCount)}';
  debugPrint(line);
}
```

**Empty buckets are present and zero-valued, not omitted.** A quiet project
returns a full series of zeros, so a `if (series.series.isEmpty)` branch never
fires. Check the values, not the length.

**`values` is sparse, so every measure accessor returns `double?`.** A
breakdown's overflow row omits `unique_event_users` deliberately — a
distinct-user count is not additive across the names it absorbed — and
`item.measure(MetricMeasure.uniqueEventUsers)` is `null` there:

```dart
final breakdown = await kit.client.metrics.breakdown(
  MetricBreakdownOptions(
    measures: [MetricMeasure.eventCount, MetricMeasure.uniqueEventUsers],
    dimension: MetricDimension.eventName,
    days: 30,
  ),
);

for (final item in breakdown.items) {
  final users = item.measure(MetricMeasure.uniqueEventUsers); // double?
  final line = '${item.key}: ${users ?? '—'}${item.isOverflow ? ' (other)' : ''}';
  debugPrint(line);
}
```

#### What each plan reads — and what it does NOT do

Every line below is a **`200`**. None of them is an error, and none is a reason
to wrap a metrics call in a `catch` that renders an upsell.

- **Every plan reads metrics.** There is no plan on which `kit.client.metrics` fails.
- **Below Pro, a read counts only FeedbackKit's own three predefined events** —
  `PredefinedEventNames.all`. Your own event names are still ingested and
  retained; they simply are not counted yet, and they become readable on upgrade
  **with no re-tracking**. The response says so through
  `meta.eventScope == MetricEventScope.predefinedOnly`.
- **A window wider than the plan allows comes back clamped, not refused** —
  `meta.retentionClamped` is `true` and `meta.retentionWindowDays` carries the
  allowance (Free 30, Pro 90, Team 365). Read that number; never hardcode 30, 90, or 365.

```dart
final summary = await kit.client.metrics.summary(
  MetricSummaryOptions(
    measures: [MetricMeasure.eventCount],
    days: 365,
  ),
);

if (summary.meta.eventScope == MetricEventScope.predefinedOnly) {
  // Render an upsell from this 200, not from a caught exception.
}
if (summary.meta.retentionClamped) {
  final days = summary.meta.retentionWindowDays;
  debugPrint('Showing the last $days days.');
}
```

**`events.track` works on every plan, including Free.** Instrument first; the
history is waiting when you upgrade.

#### The raw event feed, and paging it

```dart
DateTime? lastSyncedAt;
var page = 1;
final dateTo = DateTime.now().toUtc(); // pin the window while paging
while (true) {
  final feed = await kit.client.metrics.events(
    MetricEventsOptions(dateFrom: lastSyncedAt, dateTo: dateTo, page: page),
  );
  debugPrint('${feed.items.length}');
  if (page >= feed.meta.totalPages) break;
  page++;
}
lastSyncedAt = dateTo; // next sync resumes here
```

The feed carries **two** meta blocks: `feed.meta` is pagination (`total`,
`page`, `perPage`, `totalPages`) and `feed.metrics` is the metrics meta every
other operation puts under `meta`.

⚠️ **The metrics API-key surface is rate limited to 60 requests per 60
seconds**, and this SDK adds **no** retry, backoff or automatic page-following.
A loop like the one above must pace itself. `perPage` is clamped client-side to
`1...200` as a courtesy; the server itself rejects an out-of-range value with a
`400` rather than clamping.

⚠️ The SDK has no request-cancellation model. If you rebuild on a rapidly
changing date range, discard stale responses yourself.

## User Management

The SDK always has a user id before it loads or writes. An id you pass in wins over one already stored, and it is saved for the next launch. If you pass none and nothing is stored, the SDK creates a `local_` id. Cleartext base URLs are rejected; `http://localhost` and `http://127.0.0.1` are allowed for a local server.

Set a user ID to associate feedback and votes with a user:

```dart
// Via provider. This id wins over one already stored.
const FeedbackKitProvider(
  apiKey: 'your-api-key',
  userId: 'user-123',
  child: FeedbackPage(),
)

// Or programmatically. This replaces a generated local_ id.
final kit = FeedbackKitProvider.of(context);
await kit.setUserId('user-123');
```

On a client from `FeedbackKit.configure`, call `resolveUserId` before `votes.vote` or `events.track`. Those methods throw `ValidationError` when the id is still empty. The provider does that resolution before `FeedbackList` loads.

Register user details. `email` and `name` still compile and are not sent. The widgets never send `mrr`. This call sends it only when you pass it:

```dart
await kit.client.users.register(
  const RegisterUserRequest(
    userId: 'user-123',
    mrr: 9.99,
  ),
);
```

## Error Handling

The SDK throws specific exceptions for different error cases:

```dart
try {
  await kit.client.feedback.create(
    const CreateFeedbackRequest(
      title: 'Add dark mode',
      description: 'A system-matching dark theme.',
      category: FeedbackCategory.featureRequest,
    ),
  );
} on AuthenticationError catch (e) {
  // Invalid API key (401)
} on PaymentRequiredError catch (e) {
  // 402. Not the Free feedback cap: that write still returns success
  // and sets FeedbackItem.isHiddenOverLimit.
} on ForbiddenError catch (e) {
  // Access denied (403)
} on NotFoundError catch (e) {
  // Resource not found (404)
} on ValidationError catch (e) {
  // Invalid input (400)
} on RateLimitError catch (e) {
  // Too many requests (429). e.retryAfterSeconds when the server sent one.
} on NetworkError catch (e) {
  // Connection issues
} on FeedbackKitError catch (e) {
  // Other errors
}
```

### The server's own error code

`FeedbackKitError.code` carries the server's machine-readable token when the
response came through the detailed error envelope, and `field` names the
parameter at fault. That is what separates the two errors a host app most needs
to treat differently:

```dart
try {
  await kit.client.metrics.breakdown(
    MetricBreakdownOptions(
      measures: [MetricMeasure.eventCount],
      dimension: MetricDimension.eventName,
      days: 30,
    ),
  );
} on PaymentRequiredError catch (e) {
  if (e.code == 'METRICS_CUSTOM_EVENTS_REQUIRE_PRO') {
    // 402. An upsell. dimension: eventName, a custom eventName filter,
    // and the raw event feed are the three requests with this code.
  }
} on ForbiddenError catch (e) {
  if (e.code == 'METRICS_MEASURE_REQUIRES_BEARER') {
    // 403. This measure is not on the API-key surface. Not an upsell.
  }
}
```

The shared middleware envelope (401, a project denial, 404, 429, 500) carries
**no** code, and the SDK does not invent one: `code` falls back to the error
class's own constant and `field` is null.

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

Make sure to replace `'your-api-key-here'` with your project API key from [feedbackkit.app](https://feedbackkit.app). Do not commit that key. The published 1.0.1 example and the public GitHub example both still contain one; rotate any key that shipped there.

## Published 1.0.1

pub.dev 1.0.1 (9 February 2026) is the only published version. It does not match this README.

| This checkout (1.2.2) | pub.dev 1.0.1 |
| --- | --- |
| `locale`, `translations` | Absent |
| Mailing-list fields on submit and vote | Absent |
| `client.metrics` | Absent |
| `RateLimitError`, `FeedbackKitError.field`, server `code` | Absent. 429 is a generic `FeedbackKitError` |
| Anonymous `local_` id, explicit id wins, list waits | Stored id overwrites an explicit one. No generated id. The list can load before an id exists |
| `votes.vote(..., email:, notifyStatusChange:)` sends `email` and `notify_status_change` | `notifyOnStatusChange` only, sent as `notify_on_status_change`, which does not set the flag. No `email` parameter |
| `unvote` sends `user_id` in the JSON body | `userId` on the query string, which `DELETE /feedbacks/:id/votes` ignores |
| `CreateFeedbackRequest.email` is sent as `user_email` | Sent as `email`, so the address is stored empty |
| `CreateCommentRequest` sends `userId` | Sends `content` only, so create returns 400 |
| `events.trackEvent` sends `event_name`, `user_id`, and string properties | Sends `name` and `timestamp`, omits `user_id`. Decoding a stored event expects `name` and crashes on `event_name` |
| `RegisterUserRequest(userId:, mrr:)` | `id`, `email`, and `name`. The server reads `user_id` and `mrr` only |
| HTTPS required, loopback HTTP allowed | Any base URL is accepted |
| Example API key is `your-api-key-here` | The example hardcodes a project API key |

The public repository `SwiftlyFeedbackKit-Flutter-SDK` at `main` is **1.1.1**, last pushed 16 August 2026. It has `locale`, `translations`, and mailing-list fields, and it still has the 1.0.1 vote, comment, event, and register wire keys. It has no metrics API. Its example still contains the project API key. It is not this checkout. This repository does not publish to pub.dev from a docs change.

## Privacy

Data this SDK sends is collected on your behalf. FeedbackKit is the processor. The widgets do not post monthly recurring revenue. `users.register` sends `mrr` only when you pass it. Store-form answers: [App Store privacy](../docs/privacy/APP-STORE-PRIVACY.md), [Google Play Data safety](../docs/privacy/GOOGLE-PLAY-DATA-SAFETY.md).

## Requirements

- Flutter 3.10.0 or higher
- Dart 3.0.0 or higher

## License

MIT License - see [LICENSE](LICENSE) for details.
