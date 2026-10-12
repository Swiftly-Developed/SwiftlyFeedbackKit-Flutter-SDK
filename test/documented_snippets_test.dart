import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Type-checks the snippets in README.md and docs/getting-started.md.
///
/// The functions are referenced from [snippetAnchors] so the analyzer keeps
/// them. They are not executed: they need a project API key and a server.
void main() {
  test('documented snippets type-check against feedbackkit_flutter 1.2.2', () {
    expect(snippetAnchors, isNotEmpty);
  });
}

final snippetAnchors = <Object>[
  wrapApp,
  configureClient,
  listFromProvider,
  setUser,
  registerUser,
  feedbackPage,
  refreshList,
  filterList,
  listPage,
  openSubmitSheet,
  createFeedback,
  voteWithStatusEmail,
  unvote,
  listComments,
  trackPredefinedEvent,
  readSummary,
  pageEvents,
  handleCreateError,
];

Widget wrapApp() {
  return const FeedbackKitProvider(
    apiKey: 'your-api-key',
    child: MaterialApp(
      home: Scaffold(
        body: FeedbackList(),
      ),
    ),
  );
}

FeedbackKit configureClient() {
  return FeedbackKit.configure(
    apiKey: 'your-api-key',
    baseUrl: 'https://api.prod.getfeedbackkit.com/api/v1',
    timeout: 10000,
  );
}

Future<List<FeedbackItem>> listFromProvider(BuildContext context) async {
  final kit = FeedbackKitProvider.of(context);
  return kit.client.feedback.list();
}

Future<String> setUser(BuildContext context) async {
  final kit = FeedbackKitProvider.of(context);
  await kit.setUserId('user-123');
  return kit.client.resolveUserId();
}

Future<SDKUser> registerUser(FeedbackKitContext kit) {
  return kit.client.users.register(
    const RegisterUserRequest(
      userId: 'user-123',
      mrr: 9.99,
    ),
  );
}

Widget feedbackPage(BuildContext context) {
  return FeedbackList(
    onFeedbackTap: (feedback) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FeedbackDetailView(feedback: feedback),
        ),
      );
    },
    onVoteChange: (feedback, response) {
      FeedbackKitProvider.of(context).feedbackList.updateFeedback(
            feedback.copyWith(
              voteCount: response.voteCount,
              hasVoted: response.hasVoted,
            ),
          );
    },
  );
}

Future<void> refreshList(BuildContext context) {
  return FeedbackKitProvider.of(context).feedbackList.refresh();
}

Future<void> filterList(BuildContext context) async {
  final kit = FeedbackKitProvider.of(context);
  await kit.feedbackList.setStatusFilter(FeedbackStatus.inProgress);
  await kit.feedbackList.setCategoryFilter(FeedbackCategory.bugReport);
  await kit.feedbackList.clearFilters();
}

Future<List<FeedbackItem>> listPage(FeedbackKitContext kit) {
  return kit.client.feedback.list(
    const ListFeedbackOptions(
      status: FeedbackStatus.approved,
      category: FeedbackCategory.featureRequest,
      page: 1,
      perPage: 20,
    ),
  );
}

Future<void> openSubmitSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.9,
      child: SubmitFeedbackView(
        initialCategory: FeedbackCategory.featureRequest,
        onSubmitted: (feedback) {
          Navigator.of(sheetContext).pop();
          FeedbackKitProvider.of(context).feedbackList.refresh();
        },
        onCancel: () => Navigator.of(sheetContext).pop(),
      ),
    ),
  );
}

Future<FeedbackItem> createFeedback(FeedbackKitContext kit) {
  return kit.client.feedback.create(
    const CreateFeedbackRequest(
      title: 'Add dark mode',
      description: 'A system-matching dark theme.',
      category: FeedbackCategory.featureRequest,
      email: 'user@example.com',
      subscribeToMailingList: true,
      mailingListEmailTypes: ['operational', 'marketing'],
    ),
  );
}

Future<int> voteWithStatusEmail(
  FeedbackKitContext kit,
  String feedbackId,
) async {
  final response = await kit.client.votes.vote(
    feedbackId,
    email: 'user@example.com',
    notifyStatusChange: true,
  );
  return response.voteCount;
}

Future<bool> unvote(FeedbackKitContext kit, String feedbackId) async {
  final removed = await kit.client.votes.unvote(feedbackId);
  return removed.hasVoted;
}

Future<Comment> listComments(FeedbackKitContext kit, String feedbackId) async {
  final comments = await kit.client.comments.list(feedbackId);
  return kit.client.comments.create(
    feedbackId,
    CreateCommentRequest(
      content: 'This would help our team too.',
      userId: comments.isEmpty ? 'user-123' : comments.first.userId,
    ),
  );
}

Future<void> trackPredefinedEvent(FeedbackKitContext kit) {
  return kit.client.events.trackEvent(
    PredefinedEventNames.feedbackList,
    properties: const {'filter': 'feature_request'},
  );
}

Future<int> readSummary(FeedbackKitContext kit) async {
  final summary = await kit.client.metrics.summary(
    MetricSummaryOptions(
      measures: [MetricMeasure.eventCount],
      days: 365,
    ),
  );
  final scoped = summary.meta.eventScope == MetricEventScope.predefinedOnly;
  final days = summary.meta.retentionWindowDays;
  if (scoped && summary.meta.retentionClamped) {
    return days;
  }
  return summary.measure(MetricMeasure.eventCount)?.round() ?? days;
}

Future<DateTime> pageEvents(FeedbackKitContext kit) async {
  DateTime? lastSyncedAt;
  final dateTo = DateTime.now().toUtc();
  var page = 1;
  while (true) {
    final feed = await kit.client.metrics.events(
      MetricEventsOptions(
        dateFrom: lastSyncedAt,
        dateTo: dateTo,
        page: page,
      ),
    );
    if (page >= feed.meta.totalPages || feed.items.isEmpty) break;
    page++;
  }
  lastSyncedAt = dateTo;
  return lastSyncedAt;
}

Future<String> handleCreateError(FeedbackKitContext kit) async {
  try {
    await kit.client.feedback.create(
      const CreateFeedbackRequest(
        title: 'Add dark mode',
        description: 'A system-matching dark theme.',
        category: FeedbackCategory.featureRequest,
      ),
    );
    return 'ok';
  } on AuthenticationError {
    return '401';
  } on ValidationError {
    return '400';
  } on ForbiddenError {
    return '403';
  } on ConflictError {
    return '409';
  } on NotFoundError {
    return '404';
  } on PaymentRequiredError catch (error) {
    return error.code;
  } on RateLimitError catch (error) {
    return '${error.retryAfterSeconds ?? 0}';
  } on NetworkError {
    return 'network';
  } on FeedbackKitError catch (error) {
    return error.message;
  }
}
