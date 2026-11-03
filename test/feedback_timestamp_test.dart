import 'package:feedbackkit_flutter/src/api/feedback_api.dart';
import 'package:feedbackkit_flutter/src/models/feedback.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FeedbackResponseDTO` declares both timestamps optional, and a nil optional
/// reaches the wire as JSON `null`. One such row used to throw out of the list
/// decoder and blank the whole list.
Map<String, dynamic> _row({
  required String id,
  Object? createdAt = '2026-01-02T03:04:05Z',
  Object? updatedAt = '2026-02-03T04:05:06Z',
  bool omitUpdatedAt = false,
}) {
  return {
    'id': id,
    'title': 'Title',
    'description': 'Description',
    'status': 'pending',
    'category': 'bug_report',
    'created_at': createdAt,
    if (!omitUpdatedAt) 'updated_at': updatedAt,
  };
}

void main() {
  final created = DateTime.parse('2026-01-02T03:04:05Z');
  final updated = DateTime.parse('2026-02-03T04:05:06Z');

  test('a null updated_at reads as the creation time', () {
    final item = FeedbackItem.fromJson(_row(id: 'a', updatedAt: null));
    expect(item.updatedAt, created);
    expect(item.createdAt, created);
  });

  test('a missing updated_at reads as the creation time', () {
    final item = FeedbackItem.fromJson(_row(id: 'a', omitUpdatedAt: true));
    expect(item.updatedAt, created);
  });

  test('a null created_at reads as the update time', () {
    final item = FeedbackItem.fromJson(_row(id: 'a', createdAt: null));
    expect(item.createdAt, updated);
    expect(item.updatedAt, updated);
  });

  test('both timestamps present are kept as sent', () {
    final item = FeedbackItem.fromJson(_row(id: 'a'));
    expect(item.createdAt, created);
    expect(item.updatedAt, updated);
  });

  test('a row with no timestamp at all is still malformed', () {
    expect(
      () => FeedbackItem.fromJson(_row(id: 'a', createdAt: null, updatedAt: null)),
      throwsA(isA<FormatException>()),
    );
  });

  test('one null updated_at does not fail the rest of the list', () {
    final items = decodeFeedbackListTolerantly([
      _row(id: 'first'),
      _row(id: 'null-updated-at', updatedAt: null),
      _row(id: 'last'),
    ]);
    expect(items.map((item) => item.id), ['first', 'null-updated-at', 'last']);
  });
}
