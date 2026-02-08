import 'package:feedbackkit_flutter/feedbackkit_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedbackStatus', () {
    test('fromJson converts snake_case correctly', () {
      expect(FeedbackStatus.fromJson('pending'), FeedbackStatus.pending);
      expect(FeedbackStatus.fromJson('approved'), FeedbackStatus.approved);
      expect(FeedbackStatus.fromJson('in_progress'), FeedbackStatus.inProgress);
      expect(FeedbackStatus.fromJson('testflight'), FeedbackStatus.testflight);
      expect(FeedbackStatus.fromJson('completed'), FeedbackStatus.completed);
      expect(FeedbackStatus.fromJson('rejected'), FeedbackStatus.rejected);
    });

    test('toJson converts to snake_case correctly', () {
      expect(FeedbackStatus.pending.toJson(), 'pending');
      expect(FeedbackStatus.approved.toJson(), 'approved');
      expect(FeedbackStatus.inProgress.toJson(), 'in_progress');
      expect(FeedbackStatus.testflight.toJson(), 'testflight');
      expect(FeedbackStatus.completed.toJson(), 'completed');
      expect(FeedbackStatus.rejected.toJson(), 'rejected');
    });

    test('canVote returns correct values', () {
      expect(FeedbackStatus.pending.canVote, true);
      expect(FeedbackStatus.approved.canVote, true);
      expect(FeedbackStatus.inProgress.canVote, true);
      expect(FeedbackStatus.testflight.canVote, true);
      expect(FeedbackStatus.completed.canVote, false);
      expect(FeedbackStatus.rejected.canVote, false);
    });

    test('displayName returns readable names', () {
      expect(FeedbackStatus.pending.displayName, 'Pending');
      expect(FeedbackStatus.inProgress.displayName, 'In Progress');
      expect(FeedbackStatus.testflight.displayName, 'TestFlight');
    });
  });

  group('FeedbackCategory', () {
    test('fromJson converts snake_case correctly', () {
      expect(
          FeedbackCategory.fromJson('feature_request'), FeedbackCategory.featureRequest);
      expect(FeedbackCategory.fromJson('bug_report'), FeedbackCategory.bugReport);
      expect(FeedbackCategory.fromJson('improvement'), FeedbackCategory.improvement);
      expect(FeedbackCategory.fromJson('other'), FeedbackCategory.other);
    });

    test('toJson converts to snake_case correctly', () {
      expect(FeedbackCategory.featureRequest.toJson(), 'feature_request');
      expect(FeedbackCategory.bugReport.toJson(), 'bug_report');
      expect(FeedbackCategory.improvement.toJson(), 'improvement');
      expect(FeedbackCategory.other.toJson(), 'other');
    });

    test('displayName returns readable names', () {
      expect(FeedbackCategory.featureRequest.displayName, 'Feature Request');
      expect(FeedbackCategory.bugReport.displayName, 'Bug Report');
    });
  });

  group('FeedbackItem', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'test-id',
        'title': 'Test Title',
        'description': 'Test Description',
        'status': 'in_progress',
        'category': 'feature_request',
        'vote_count': 5,
        'has_voted': true,
        'comment_count': 3,
        'user_id': 'user-123',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      final feedback = FeedbackItem.fromJson(json);

      expect(feedback.id, 'test-id');
      expect(feedback.title, 'Test Title');
      expect(feedback.description, 'Test Description');
      expect(feedback.status, FeedbackStatus.inProgress);
      expect(feedback.category, FeedbackCategory.featureRequest);
      expect(feedback.voteCount, 5);
      expect(feedback.hasVoted, true);
      expect(feedback.commentCount, 3);
      expect(feedback.userId, 'user-123');
    });

    test('copyWith creates modified copy', () {
      final feedback = FeedbackItem(
        id: 'test-id',
        title: 'Test Title',
        description: 'Test Description',
        status: FeedbackStatus.pending,
        category: FeedbackCategory.other,
        voteCount: 1,
        hasVoted: false,
        commentCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = feedback.copyWith(
        voteCount: 2,
        hasVoted: true,
      );

      expect(updated.id, feedback.id);
      expect(updated.title, feedback.title);
      expect(updated.voteCount, 2);
      expect(updated.hasVoted, true);
    });
  });

  group('Comment', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'comment-id',
        'feedback_id': 'feedback-id',
        'content': 'Test comment',
        'user_id': 'user-123',
        'author_name': 'John Doe',
        'is_team_member': true,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final comment = Comment.fromJson(json);

      expect(comment.id, 'comment-id');
      expect(comment.feedbackId, 'feedback-id');
      expect(comment.content, 'Test comment');
      expect(comment.userId, 'user-123');
      expect(comment.authorName, 'John Doe');
      expect(comment.isTeamMember, true);
    });
  });

  group('VoteResponse', () {
    test('fromJson parses correctly', () {
      final json = {
        'success': true,
        'vote_count': 10,
        'has_voted': true,
      };

      final response = VoteResponse.fromJson(json);

      expect(response.success, true);
      expect(response.voteCount, 10);
      expect(response.hasVoted, true);
    });
  });

  group('SDKUser', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'user-123',
        'email': 'test@example.com',
        'name': 'Test User',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final user = SDKUser.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
    });
  });
}
