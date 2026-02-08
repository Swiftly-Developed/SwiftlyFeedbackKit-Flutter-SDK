import 'package:flutter/widgets.dart';

import '../client/feedbackkit_client.dart';
import '../theme/feedbackkit_theme.dart';
import 'notifiers/feedback_list_notifier.dart';
import 'notifiers/vote_notifier.dart';

/// Provides FeedbackKit services to the widget tree.
class FeedbackKitProvider extends StatefulWidget {
  /// The API key for authentication.
  final String apiKey;

  /// Base URL for the API.
  final String? baseUrl;

  /// Initial user ID.
  final String? userId;

  /// Theme for FeedbackKit widgets.
  final FeedbackKitTheme? theme;

  /// Child widget.
  final Widget child;

  const FeedbackKitProvider({
    super.key,
    required this.apiKey,
    this.baseUrl,
    this.userId,
    this.theme,
    required this.child,
  });

  @override
  State<FeedbackKitProvider> createState() => _FeedbackKitProviderState();

  /// Gets the FeedbackKit context from the widget tree.
  static FeedbackKitContext of(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_FeedbackKitInheritedWidget>();
    if (inherited == null) {
      throw FlutterError(
        'FeedbackKitProvider.of() called with a context that does not '
        'contain a FeedbackKitProvider.\n'
        'Ensure that a FeedbackKitProvider widget is an ancestor of the '
        'context used to call FeedbackKitProvider.of().',
      );
    }
    return inherited.context;
  }

  /// Gets the FeedbackKit context, or null if not available.
  static FeedbackKitContext? maybeOf(BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_FeedbackKitInheritedWidget>();
    return inherited?.context;
  }
}

class _FeedbackKitProviderState extends State<FeedbackKitProvider> {
  late FeedbackKit _client;
  late FeedbackListNotifier _feedbackListNotifier;
  late VoteNotifier _voteNotifier;
  late FeedbackKitTheme _theme;
  String? _userId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initClient();
  }

  void _initClient() {
    _client = FeedbackKit.configure(
      apiKey: widget.apiKey,
      baseUrl: widget.baseUrl,
      userId: widget.userId,
    );

    _feedbackListNotifier = FeedbackListNotifier(_client);
    _voteNotifier = VoteNotifier(_client);
    _theme = widget.theme ?? const FeedbackKitTheme();
    _userId = widget.userId;

    _loadStoredUserId();
  }

  Future<void> _loadStoredUserId() async {
    final storedUserId = await _client.loadUserId();
    if (mounted) {
      setState(() {
        _userId = storedUserId ?? widget.userId;
        _isInitialized = true;
      });
    }
  }

  @override
  void didUpdateWidget(FeedbackKitProvider oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Recreate client if API key or base URL changes
    if (oldWidget.apiKey != widget.apiKey ||
        oldWidget.baseUrl != widget.baseUrl) {
      _client.close();
      _feedbackListNotifier.dispose();
      _voteNotifier.dispose();
      _initClient();
    }

    // Update user ID if changed
    if (oldWidget.userId != widget.userId && widget.userId != null) {
      _setUserId(widget.userId!);
    }

    // Update theme if changed
    if (widget.theme != null && widget.theme != _theme) {
      setState(() {
        _theme = widget.theme!;
      });
    }
  }

  Future<void> _setUserId(String userId) async {
    await _client.setUserId(userId);
    if (mounted) {
      setState(() {
        _userId = userId;
      });
    }
  }

  @override
  void dispose() {
    _client.close();
    _feedbackListNotifier.dispose();
    _voteNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FeedbackKitInheritedWidget(
      context: FeedbackKitContext(
        client: _client,
        feedbackList: _feedbackListNotifier,
        votes: _voteNotifier,
        theme: _theme,
        userId: _userId,
        isInitialized: _isInitialized,
        setUserId: _setUserId,
      ),
      child: widget.child,
    );
  }
}

/// Context object containing FeedbackKit services.
class FeedbackKitContext {
  /// The FeedbackKit client.
  final FeedbackKit client;

  /// Notifier for feedback list state.
  final FeedbackListNotifier feedbackList;

  /// Notifier for vote operations.
  final VoteNotifier votes;

  /// Theme for FeedbackKit widgets.
  final FeedbackKitTheme theme;

  /// Current user ID.
  final String? userId;

  /// Whether the provider has finished initializing.
  final bool isInitialized;

  /// Function to update the user ID.
  final Future<void> Function(String) setUserId;

  const FeedbackKitContext({
    required this.client,
    required this.feedbackList,
    required this.votes,
    required this.theme,
    required this.userId,
    required this.isInitialized,
    required this.setUserId,
  });
}

class _FeedbackKitInheritedWidget extends InheritedWidget {
  final FeedbackKitContext context;

  const _FeedbackKitInheritedWidget({
    required this.context,
    required super.child,
  });

  @override
  bool updateShouldNotify(_FeedbackKitInheritedWidget oldWidget) {
    return context.userId != oldWidget.context.userId ||
        context.theme != oldWidget.context.theme ||
        context.isInitialized != oldWidget.context.isInitialized;
  }
}
