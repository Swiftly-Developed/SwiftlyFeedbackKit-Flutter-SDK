import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FeedbackKitExampleApp());
}

class FeedbackKitExampleApp extends StatelessWidget {
  const FeedbackKitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FeedbackKitProvider(
      // Placeholder. Replace with your project key. Do not commit a real key.
      // pub.dev 1.0.1's example shipped one; rotate any key copied from there.
      apiKey: 'your-api-key-here',
      // Loopback HTTP is allowed. Any other cleartext base URL is rejected.
      baseUrl: 'http://localhost:8080/api/v1',
      // Optional. Omit this and the SDK creates a persisted local_ id.
      // VoteButton does not send notifyStatusChange or an email. See
      // docs/getting-started.md for votes.vote with those arguments.
      userId: 'example-user-123',
      // Optional: Customize the theme
      theme: const FeedbackKitTheme(
        primaryColor: Color(0xFF6366F1),
      ),
      child: MaterialApp(
        title: 'FeedbackKit Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
          useMaterial3: true,
        ),
        home: const FeedbackHomePage(),
      ),
    );
  }
}

class FeedbackHomePage extends StatefulWidget {
  const FeedbackHomePage({super.key});

  @override
  State<FeedbackHomePage> createState() => _FeedbackHomePageState();
}

class _FeedbackHomePageState extends State<FeedbackHomePage> {
  int _currentIndex = 0;
  FeedbackListStyle _listStyle = FeedbackListStyle.showcase;

  @override
  Widget build(BuildContext context) {
    final isShowcase = _listStyle == FeedbackListStyle.showcase;
    return Scaffold(
      appBar: AppBar(
        title: const Text('FeedbackKit Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              tooltip: isShowcase ? 'Use Classic list' : 'Use Showcase list',
              icon: Icon(
                isShowcase
                    ? Icons.view_agenda_outlined
                    : Icons.dashboard_outlined,
              ),
              onPressed: () => setState(() {
                _listStyle = isShowcase
                    ? FeedbackListStyle.classic
                    : FeedbackListStyle.showcase;
              }),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          FeedbackListPage(listStyle: _listStyle),
          const SubmitFeedbackPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Submit',
          ),
        ],
      ),
    );
  }
}

class FeedbackListPage extends StatelessWidget {
  final FeedbackListStyle listStyle;

  const FeedbackListPage({super.key, required this.listStyle});

  @override
  Widget build(BuildContext context) {
    return FeedbackList(
      listStyle: listStyle,
      onFeedbackTap: (feedback) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FeedbackDetailPage(feedback: feedback),
          ),
        );
      },
      onVoteChange: (feedback, response) {
        // Update the feedback list when a vote changes
        final provider = FeedbackKitProvider.of(context);
        provider.feedbackList.updateFeedback(
          feedback.copyWith(
            voteCount: response.voteCount,
            hasVoted: response.hasVoted,
          ),
        );
      },
    );
  }
}

class FeedbackDetailPage extends StatelessWidget {
  final FeedbackItem feedback;

  const FeedbackDetailPage({
    super.key,
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FeedbackDetailView(
        feedback: feedback,
        onVoteChange: (response) {
          // Update the feedback list when a vote changes
          final provider = FeedbackKitProvider.of(context);
          provider.feedbackList.updateFeedback(
            feedback.copyWith(
              voteCount: response.voteCount,
              hasVoted: response.hasVoted,
            ),
          );
        },
      ),
    );
  }
}

class SubmitFeedbackPage extends StatelessWidget {
  const SubmitFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubmitFeedbackView(
      onSubmitted: (feedback) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feedback submitted: ${feedback.title}'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the feedback list
        final provider = FeedbackKitProvider.of(context);
        provider.feedbackList.refresh();
      },
    );
  }
}
