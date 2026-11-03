import 'dart:convert';
import 'dart:io';

import 'package:feedbackkit_flutter/src/models/sdk_user.dart';
import 'package:flutter_test/flutter_test.dart';

/// `POST /users/register` answers with `SDKUserResponseDTO`: `id`, `user_id`,
/// `mrr`, `first_seen_at` and `last_seen_at`. The corpus is generated from it.
void main() {
  final corpus = jsonDecode(
    File('test/fixtures/sdk-user-wire-corpus.json').readAsStringSync(),
  ) as List<dynamic>;

  test('a full response binds every field the server sends', () {
    final user = SDKUser.fromJson(corpus[0] as Map<String, dynamic>);
    expect(user.id, '99999999-9999-4999-8999-999999999999');
    expect(user.userId, 'fixture-end-user');
    expect(user.mrr, 42.5);
    expect(user.firstSeenAt, DateTime.parse('2023-11-14T22:13:20Z'));
    expect(user.lastSeenAt, DateTime.parse('2023-11-14T23:13:20Z'));
  });

  test('an anonymous response leaves the optional fields null', () {
    final user = SDKUser.fromJson(corpus[1] as Map<String, dynamic>);
    expect(user.userId, 'fixture-anonymous');
    expect(user.mrr, isNull);
    expect(user.firstSeenAt, isNull);
    expect(user.lastSeenAt, isNull);
  });

  test('a whole-number mrr decodes as a double', () {
    final user = SDKUser.fromJson(const {
      'id': 'id',
      'user_id': 'u',
      'mrr': 10,
    });
    expect(user.mrr, 10.0);
  });

  test('the wire fields survive a toJson round trip', () {
    final row = corpus[0] as Map<String, dynamic>;
    final round = SDKUser.fromJson(SDKUser.fromJson(row).toJson());
    expect(round, SDKUser.fromJson(row));
    expect(round.userId, 'fixture-end-user');
    expect(round.mrr, 42.5);
    expect(round.lastSeenAt, DateTime.parse('2023-11-14T23:13:20Z'));
  });

  test('copyWith replaces the wire fields', () {
    final user = SDKUser.fromJson(corpus[1] as Map<String, dynamic>);
    expect(user.copyWith(mrr: 5).mrr, 5);
    expect(user.copyWith(userId: 'other').userId, 'other');
  });

  test('a call site written against 1.x still compiles and reads its values', () {
    // ignore: deprecated_member_use_from_same_package
    const user = SDKUser(id: 'id', email: 'a@b.invalid', name: 'A');
    // ignore: deprecated_member_use_from_same_package
    expect(user.email, 'a@b.invalid');
    // ignore: deprecated_member_use_from_same_package
    expect(user.name, 'A');
  });
}
