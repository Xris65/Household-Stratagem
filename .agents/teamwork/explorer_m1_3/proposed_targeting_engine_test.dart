import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/models.dart';
import 'package:household_stratagem/targeting_engine.dart';

void main() {
  final fixedNow = DateTime(2026, 10, 4, 12, 0, 0);

  group('TargetingEngine - calculateUrgencyScore', () {
    test('never completed chore receives base 1000 + (difficulty * 10)', () {
      final choreDiff1 = Chore(
        id: '1',
        name: 'Tâche simple jamais faite',
        difficulty: 1,
        periodicityDays: 7,
        lastCompletedAt: null,
      );
      final choreDiff3 = Chore(
        id: '2',
        name: 'Tâche moyenne jamais faite',
        difficulty: 3,
        periodicityDays: 7,
        lastCompletedAt: null,
      );
      final choreDiff5 = Chore(
        id: '3',
        name: 'Tâche difficile jamais faite',
        difficulty: 5,
        periodicityDays: 7,
        lastCompletedAt: null,
      );

      expect(TargetingEngine.calculateUrgencyScore(choreDiff1, now: fixedNow), closeTo(1010.0, 0.001));
      expect(TargetingEngine.calculateUrgencyScore(choreDiff3, now: fixedNow), closeTo(1030.0, 0.001));
      expect(TargetingEngine.calculateUrgencyScore(choreDiff5, now: fixedNow), closeTo(1050.0, 0.001));
    });

    test('chore completed exactly on due date has overdueRatio = 1.0', () {
      // Completed exactly 7 days ago, periodicity is 7 days
      final chore = Chore(
        id: '1',
        name: 'Nettoyer le four',
        difficulty: 2,
        periodicityDays: 7,
        lastCompletedAt: fixedNow.subtract(const Duration(days: 7)),
      );

      // (1.0 * 100.0) + (2 * 5.0) = 100.0 + 10.0 = 110.0
      final score = TargetingEngine.calculateUrgencyScore(chore, now: fixedNow);
      expect(score, closeTo(110.0, 0.01));
    });

    test('chore completed halfway to due date has overdueRatio = 0.5', () {
      // Completed 5 days ago, periodicity is 10 days
      final chore = Chore(
        id: '2',
        name: 'Laver les vitres',
        difficulty: 4,
        periodicityDays: 10,
        lastCompletedAt: fixedNow.subtract(const Duration(days: 5)),
      );

      // (0.5 * 100.0) + (4 * 5.0) = 50.0 + 20.0 = 70.0
      final score = TargetingEngine.calculateUrgencyScore(chore, now: fixedNow);
      expect(score, closeTo(70.0, 0.01));
    });

    test('chore completed just now has overdueRatio = 0.0', () {
      final chore = Chore(
        id: '3',
        name: 'Vider poubelles',
        difficulty: 1,
        periodicityDays: 3,
        lastCompletedAt: fixedNow,
      );

      // (0.0 * 100.0) + (1 * 5.0) = 5.0
      final score = TargetingEngine.calculateUrgencyScore(chore, now: fixedNow);
      expect(score, closeTo(5.0, 0.01));
    });

    test('heavily overdue chore exceeds 200 urgency score', () {
      // Completed 21 days ago, periodicity is 7 days (overdueRatio = 3.0)
      final chore = Chore(
        id: '4',
        name: 'Détartrer la cafetière',
        difficulty: 3,
        periodicityDays: 7,
        lastCompletedAt: fixedNow.subtract(const Duration(days: 21)),
      );

      // (3.0 * 100.0) + (3 * 5.0) = 300.0 + 15.0 = 315.0
      final score = TargetingEngine.calculateUrgencyScore(chore, now: fixedNow);
      expect(score, closeTo(315.0, 0.01));
    });
  });

  group('TargetingEngine - getTopTargets', () {
    test('returns empty list when input is empty', () {
      final targets = TargetingEngine.getTopTargets([], now: fixedNow);
      expect(targets, isEmpty);
    });

    test('handles list with fewer than 3 chores safely', () {
      final chores = [
        Chore(
          id: '1',
          name: 'Chore A',
          difficulty: 1,
          periodicityDays: 7,
          lastCompletedAt: fixedNow.subtract(const Duration(days: 7)),
        ),
      ];

      final targets = TargetingEngine.getTopTargets(chores, now: fixedNow);
      expect(targets.length, equals(1));
      expect(targets.first.id, equals('1'));
    });

    test('sorts and returns top 3 most urgent chores out of multiple candidates', () {
      final chores = [
        Chore(
          id: 'c_fresh',
          name: 'Faite aujourd hui',
          difficulty: 1,
          periodicityDays: 7,
          lastCompletedAt: fixedNow, // score: 5.0
        ),
        Chore(
          id: 'c_never_hard',
          name: 'Jamais faite difficile',
          difficulty: 5,
          periodicityDays: 14,
          lastCompletedAt: null, // score: 1050.0
        ),
        Chore(
          id: 'c_overdue',
          name: 'En retard',
          difficulty: 2,
          periodicityDays: 7,
          lastCompletedAt: fixedNow.subtract(const Duration(days: 14)), // score: 210.0
        ),
        Chore(
          id: 'c_never_easy',
          name: 'Jamais faite facile',
          difficulty: 1,
          periodicityDays: 7,
          lastCompletedAt: null, // score: 1010.0
        ),
        Chore(
          id: 'c_due_today',
          name: 'Due aujourd hui',
          difficulty: 3,
          periodicityDays: 7,
          lastCompletedAt: fixedNow.subtract(const Duration(days: 7)), // score: 115.0
        ),
      ];

      final targets = TargetingEngine.getTopTargets(chores, count: 3, now: fixedNow);

      expect(targets.length, equals(3));
      // Top 1: c_never_hard (1050.0)
      expect(targets[0].id, equals('c_never_hard'));
      // Top 2: c_never_easy (1010.0)
      expect(targets[1].id, equals('c_never_easy'));
      // Top 3: c_overdue (210.0)
      expect(targets[2].id, equals('c_overdue'));
    });

    test('respects custom count parameter', () {
      final chores = [
        Chore(id: '1', name: 'A', difficulty: 1, periodicityDays: 7, lastCompletedAt: null),
        Chore(id: '2', name: 'B', difficulty: 2, periodicityDays: 7, lastCompletedAt: null),
        Chore(id: '3', name: 'C', difficulty: 3, periodicityDays: 7, lastCompletedAt: null),
      ];

      final top1 = TargetingEngine.getTopTargets(chores, count: 1, now: fixedNow);
      expect(top1.length, equals(1));

      final top2 = TargetingEngine.getTopTargets(chores, count: 2, now: fixedNow);
      expect(top2.length, equals(2));
    });

    test('does not mutate original list', () {
      final chores = [
        Chore(id: '1', name: 'Low', difficulty: 1, periodicityDays: 7, lastCompletedAt: fixedNow),
        Chore(id: '2', name: 'High', difficulty: 5, periodicityDays: 7, lastCompletedAt: null),
      ];

      final originalFirst = chores.first.id;
      TargetingEngine.getTopTargets(chores, now: fixedNow);
      expect(chores.first.id, equals(originalFirst));
    });

    test('backward compatibility: instance method getAvailableTargets still functions', () {
      final engine = TargetingEngine();
      final available = engine.getAvailableTargets();
      expect(available, isNotEmpty);
      expect(available.length, greaterThanOrEqualTo(1));
    });
  });
}
