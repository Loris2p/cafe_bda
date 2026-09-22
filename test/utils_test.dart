import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:boutique_bda/core/utils.dart';

void main() {
  group('Utils Tests', () {
    test('parseFirestoreDate parses Timestamp correctly', () {
      final now = DateTime(2026, 9, 22, 12, 0, 0);
      final timestamp = Timestamp.fromDate(now);

      final parsed = parseFirestoreDate(timestamp);
      expect(parsed, now);
    });

    test('parseFirestoreDate parses DateTime and ISO String correctly', () {
      final now = DateTime(2026, 9, 22, 12, 0, 0);
      expect(parseFirestoreDate(now), now);

      final isoStr = now.toIso8601String();
      expect(parseFirestoreDate(isoStr), now);

      expect(parseFirestoreDate(null), isNull);
      expect(parseFirestoreDate(''), isNull);
      expect(parseFirestoreDate('invalid'), isNull);
    });

    test('parseRequiredFirestoreDate returns fallback when null or invalid', () {
      final parsed = parseRequiredFirestoreDate(null);
      expect(parsed, isA<DateTime>());
    });

    test('parseDouble and parseInt handle various inputs robustly', () {
      expect(parseDouble(12.5), 12.5);
      expect(parseDouble(10), 10.0);
      expect(parseDouble('15.75'), 15.75);
      expect(parseDouble('invalid', 0.0), 0.0);
      expect(parseDouble(null, 2.5), 2.5);

      expect(parseInt(12), 12);
      expect(parseInt(12.8), 12);
      expect(parseInt('42'), 42);
      expect(parseInt('invalid', 0), 0);
      expect(parseInt(null, 5), 5);
    });

    test('generateRandomPassword returns expected length', () {
      final pwd10 = generateRandomPassword(10);
      expect(pwd10.length, 10);

      final pwd16 = generateRandomPassword(16);
      expect(pwd16.length, 16);
    });
  });
}
