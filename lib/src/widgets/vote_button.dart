import 'package:flutter/widgets.dart';

import '../models/feedback.dart' show FeedbackItem;
import '../models/vote_response.dart';
import '../state/feedbackkit_provider.dart';
import '../theme/feedbackkit_theme.dart';

/// Size variants for the vote button.
enum VoteButtonSize {
  small,
  medium,
  large,
}

/// A button for voting on feedback items with optimistic updates.
class VoteButton extends StatefulWidget {
  /// The feedback item to vote on.
  final FeedbackItem feedback;

  /// Size of the button.
  final VoteButtonSize size;

  /// Whether to show the vote count.
  final bool showCount;

  /// Callback when the vote state changes.
  final void Function(VoteResponse)? onVoteChange;

  /// Optional custom theme (uses provider theme by default).
  final FeedbackKitTheme? theme;

  const VoteButton({
    super.key,
    required this.feedback,
    this.size = VoteButtonSize.medium,
    this.showCount = true,
    this.onVoteChange,
    this.theme,
  });

  @override
  State<VoteButton> createState() => _VoteButtonState();
}

class _VoteButtonState extends State<VoteButton> {
  late bool _localHasVoted;
  late int _localVoteCount;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _localHasVoted = widget.feedback.hasVoted;
    _localVoteCount = widget.feedback.voteCount;
  }

  @override
  void didUpdateWidget(VoteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedback.id != widget.feedback.id) {
      _localHasVoted = widget.feedback.hasVoted;
      _localVoteCount = widget.feedback.voteCount;
    }
  }

  bool get _canVote => widget.feedback.status.canVote && !_isVoting;

  Future<void> _handleTap() async {
    if (!_canVote) return;

    final context = FeedbackKitProvider.of(this.context);

    setState(() {
      _isVoting = true;
    });

    // Optimistic update
    final previousHasVoted = _localHasVoted;
    final previousVoteCount = _localVoteCount;

    setState(() {
      if (_localHasVoted) {
        _localHasVoted = false;
        _localVoteCount = (_localVoteCount - 1).clamp(0, double.maxFinite.toInt());
      } else {
        _localHasVoted = true;
        _localVoteCount++;
      }
    });

    try {
      final response = await context.votes.toggle(
        widget.feedback.id,
        hasVoted: previousHasVoted,
      );

      if (response != null) {
        setState(() {
          _localHasVoted = response.hasVoted;
          _localVoteCount = response.voteCount;
        });
        widget.onVoteChange?.call(response);
      } else {
        // Revert on failure
        setState(() {
          _localHasVoted = previousHasVoted;
          _localVoteCount = previousVoteCount;
        });
      }
    } catch (_) {
      // Revert on error
      setState(() {
        _localHasVoted = previousHasVoted;
        _localVoteCount = previousVoteCount;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    }
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case VoteButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case VoteButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case VoteButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case VoteButtonSize.small:
        return 12;
      case VoteButtonSize.medium:
        return 14;
      case VoteButtonSize.large:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ??
        FeedbackKitProvider.maybeOf(context)?.theme ??
        const FeedbackKitTheme();

    final isDisabled = !_canVote;

    return GestureDetector(
      onTap: isDisabled ? null : _handleTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: _padding,
          decoration: BoxDecoration(
            color: _localHasVoted
                ? theme.primaryColor
                : theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(theme.borderRadius / 2),
            border: Border.all(
              color: _localHasVoted
                  ? theme.primaryColor
                  : theme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\u25B2', // Up arrow
                style: TextStyle(
                  color: _localHasVoted
                      ? const Color(0xFFFFFFFF)
                      : theme.primaryColor,
                  fontSize: _fontSize,
                ),
              ),
              if (widget.showCount) ...[
                SizedBox(width: theme.spacing / 2),
                Text(
                  '$_localVoteCount',
                  style: TextStyle(
                    color: _localHasVoted
                        ? const Color(0xFFFFFFFF)
                        : theme.primaryColor,
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_isVoting) ...[
                SizedBox(width: theme.spacing / 2),
                SizedBox(
                  width: _fontSize,
                  height: _fontSize,
                  child: const _LoadingIndicator(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatefulWidget {
  const _LoadingIndicator();

  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: child,
        );
      },
      child: const Text(
        '\u25CB', // Circle
        style: TextStyle(fontSize: 10),
      ),
    );
  }
}
