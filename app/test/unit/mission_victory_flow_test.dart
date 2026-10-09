import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/models/chore.dart';
import 'package:household_stratagem/models/user_profile.dart';
import 'package:household_stratagem/services/household_repository.dart';
import 'package:household_stratagem/services/audio_service.dart';
import 'package:household_stratagem/screens/timer_screen.dart';
import 'package:household_stratagem/screens/mission_complete_screen.dart';

void _setTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('MissionCompleteScreen (Debriefing & Victory Screen)', () {
    late Chore testChore;
    late InMemoryHouseholdRepository mockRepo;
    const testUserId = 'soldier_76';

    setUp(() {
      testChore = Chore(
        id: 'chore_patrol',
        name: 'Dégraissage Four',
        difficulty: 4,
        room: 'Cuisine',
        periodicityDays: 7,
        durationMinutes: 15,
        swipeSequence: ['up', 'right', 'down'],
      );
      mockRepo = InMemoryHouseholdRepository(autoSeed: false);
    });

    testWidgets('Displays glowing title MISSION ACCOMPLIE and tactical subtext', (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: MissionCompleteScreen(
            chore: testChore,
            durationSeconds: 300,
            userId: testUserId,
            householdRepo: mockRepo,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('MISSION ACCOMPLIE'), findsOneWidget);
      expect(find.text('DÉBRIEFING TACTIQUE'), findsOneWidget);
      expect(find.text('[ PROTOCOLE D\'ASSAINISSEMENT EXÉCUTÉ ]'), findsOneWidget);
    });

    testWidgets('Displays chore recap: name, room category, and difficulty', (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: MissionCompleteScreen(
            chore: testChore,
            durationSeconds: 125,
            userId: testUserId,
            householdRepo: mockRepo,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('RÉCAPITULATIF DE L\'OBJECTIF'), findsOneWidget);
      expect(find.text('DÉGRAISSAGE FOUR'), findsOneWidget);
      expect(find.text('CUISINE'), findsOneWidget);
      expect(find.text('DIFFICULTÉ 4/5'), findsOneWidget);
      expect(find.byIcon(Icons.kitchen), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('Displays formatted duration in MM:SS (e.g. 125s -> 02:05)', (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: MissionCompleteScreen(
            chore: testChore,
            durationSeconds: 125,
            userId: testUserId,
            householdRepo: mockRepo,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('TEMPS D\'ENGAGEMENT'), findsOneWidget);
      expect(find.text('02:05'), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('Displays rewards card clearly with +50 Crédits and +1 Médaille', (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: MissionCompleteScreen(
            chore: testChore,
            durationSeconds: 600,
            userId: testUserId,
            householdRepo: mockRepo,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('RÉCOMPENSES DE COMMANDEMENT'), findsOneWidget);
      expect(find.text('+50 Crédits'), findsOneWidget);
      expect(find.text('+1 Médaille'), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
      expect(find.byIcon(Icons.military_tech), findsWidgets);
    });

    testWidgets('Tapping "Retour au Commandement" invokes return callback', (tester) async {
      _setTestViewport(tester);
      bool returned = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MissionCompleteScreen(
            chore: testChore,
            durationSeconds: 600,
            userId: testUserId,
            householdRepo: mockRepo,
            onReturnHome: () {
              returned = true;
            },
          ),
        ),
      );
      await tester.pump();

      final returnBtn = find.text('Retour au Commandement');
      expect(returnBtn, findsOneWidget);
      await tester.ensureVisible(returnBtn);

      await tester.tap(returnBtn);
      await tester.pump();

      expect(returned, isTrue);
    });

    testWidgets('Tapping "Retour au Commandement" pops route if in navigator', (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MissionCompleteScreen(
                      chore: testChore,
                      durationSeconds: 60,
                      userId: testUserId,
                      householdRepo: mockRepo,
                    ),
                  ),
                );
              },
              child: const Text('GO_TO_DEBRIEF'),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('GO_TO_DEBRIEF'));
      await tester.pumpAndSettle();

      expect(find.text('MISSION ACCOMPLIE'), findsOneWidget);

      final returnBtn = find.text('Retour au Commandement');
      await tester.ensureVisible(returnBtn);
      await tester.tap(returnBtn);
      await tester.pumpAndSettle();

      expect(find.text('GO_TO_DEBRIEF'), findsOneWidget);
      expect(find.text('MISSION ACCOMPLIE'), findsNothing);
    });
  });

  group('TimerScreen Victory Flow (Timer Expiration & Hold-to-Validate)', () {
    late MockAudioService mockAudio;
    late InMemoryHouseholdRepository mockRepo;
    late Chore testChore;
    const testUserId = 'test_agent_007';

    setUp(() {
      mockAudio = MockAudioService();
      mockRepo = InMemoryHouseholdRepository(autoSeed: false);
      testChore = Chore(
        id: 'chore_quick_clean',
        name: 'Désinfecter plan de travail',
        difficulty: 2,
        room: 'Cuisine',
        periodicityDays: 3,
        durationMinutes: 1, // 60 seconds
        swipeSequence: ['up', 'down'],
      );
    });

    tearDown(() {
      mockAudio.dispose();
    });

    testWidgets('Hold-to-validate gesture completes mission, awards rewards, logs mission, and navigates', (tester) async {
      _setTestViewport(tester);
      // Seed user profile with 100 credits and 2 medals
      await mockRepo.saveUserProfile(UserProfile(
        userId: testUserId,
        agentName: 'Agent-Alpha',
        credits: 100,
        medals: 2,
      ));
      await mockRepo.saveChores(testUserId, [testChore]);

      await tester.pumpWidget(
        MaterialApp(
          home: TimerScreen(
            chore: testChore,
            userId: testUserId,
            householdRepo: mockRepo,
            audioService: mockAudio,
          ),
        ),
      );
      await tester.pump();

      // Mission music started
      expect(mockAudio.isPlaying, isTrue);

      // Locate HazardButton and perform hold gesture
      final holdBtn = find.text('MAINTENIR POUR VALIDER');
      expect(holdBtn, findsOneWidget);
      await tester.ensureVisible(holdBtn);

      final gesture = await tester.startGesture(tester.getCenter(holdBtn));
      // Hold for 2000ms (20 steps of 100ms) to exceed 1500ms duration
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      // 1. Mission music stopped
      expect(mockAudio.isPlaying, isFalse);
      expect(mockAudio.stopCount, greaterThanOrEqualTo(1));

      // 2. Victory sound played
      expect(mockAudio.victoryCount, equals(1));

      // 3. Mission logged
      final logs = await mockRepo.getMissionLogs(testUserId);
      expect(logs.length, equals(1));
      expect(logs.first.choreId, equals(testChore.id));
      expect(logs.first.success, isTrue);

      // 4. Chore lastCompletedAt updated
      final chores = await mockRepo.getChores(testUserId);
      expect(chores.first.lastCompletedAt, isNotNull);

      // 5. User rewards granted: +50 credits (150 total) and +1 medal (3 total)
      final profile = await mockRepo.getUserProfile(testUserId);
      expect(profile, isNotNull);
      expect(profile!.credits, equals(150));
      expect(profile.medals, equals(3));

      // 6. MissionCompleteScreen navigated
      expect(find.text('MISSION ACCOMPLIE'), findsOneWidget);
      expect(find.text('+50 Crédits'), findsOneWidget);
      expect(find.text('+1 Médaille'), findsOneWidget);
    });

    testWidgets('Countdown reaching 00:00 automatically triggers mission victory flow', (tester) async {
      _setTestViewport(tester);
      // Profile initialized with 0 credits and 0 medals
      await mockRepo.saveUserProfile(UserProfile(userId: testUserId));
      await mockRepo.saveChores(testUserId, [testChore]);

      // Create chore with 1 minute duration (minimum allowed by adjustTime)
      await tester.pumpWidget(
        MaterialApp(
          home: TimerScreen(
            chore: testChore, // 60s
            userId: testUserId,
            householdRepo: mockRepo,
            audioService: mockAudio,
          ),
        ),
      );
      await tester.pump();

      // Start mission timer
      final startBtn = find.text('DÉMARRER MISSION');
      expect(startBtn, findsOneWidget);
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      await tester.pump();

      // Fast-forward 60 seconds
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();

      // 1. Mission music stopped
      expect(mockAudio.isPlaying, isFalse);
      expect(mockAudio.stopCount, greaterThanOrEqualTo(1));

      // 2. Victory sound played
      expect(mockAudio.victoryCount, equals(1));

      // 3. Mission log recorded
      final logs = await mockRepo.getMissionLogs(testUserId);
      expect(logs.length, equals(1));
      expect(logs.first.durationSeconds, equals(60));

      // 4. Chore updated
      final chores = await mockRepo.getChores(testUserId);
      expect(chores.first.lastCompletedAt, isNotNull);

      // 5. Rewards granted
      final profile = await mockRepo.getUserProfile(testUserId);
      expect(profile!.credits, equals(50));
      expect(profile.medals, equals(1));

      // 6. Navigation to MissionCompleteScreen happened
      expect(find.text('MISSION ACCOMPLIE'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
      expect(find.text('+50 Crédits'), findsOneWidget);
      expect(find.text('+1 Médaille'), findsOneWidget);
    });

    testWidgets('Mission victory flow handles missing initial profile safely', (tester) async {
      _setTestViewport(tester);
      // No profile saved prior to mission
      await tester.pumpWidget(
        MaterialApp(
          home: TimerScreen(
            chore: testChore,
            userId: 'new_user_without_profile',
            householdRepo: mockRepo,
            audioService: mockAudio,
          ),
        ),
      );
      await tester.pump();

      final holdBtn = find.text('MAINTENIR POUR VALIDER');
      await tester.ensureVisible(holdBtn);
      final gesture = await tester.startGesture(tester.getCenter(holdBtn));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      // Profile should be created with +50 credits and +1 medal
      final profile = await mockRepo.getUserProfile('new_user_without_profile');
      expect(profile, isNotNull);
      expect(profile!.credits, equals(50));
      expect(profile.medals, equals(1));
      expect(find.text('MISSION ACCOMPLIE'), findsOneWidget);
    });

    testWidgets('Full flow: Home -> Timer -> MissionComplete -> Home reloads chores with 0% urgency', (tester) async {
      _setTestViewport(tester);
      // Chore was last completed 10 days ago (urgency > 100%)
      final expiredChore = testChore.copyWith(
        lastCompletedAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      await mockRepo.saveChores(testUserId, [expiredChore]);
      await mockRepo.saveUserProfile(UserProfile(userId: testUserId, credits: 0, medals: 0));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TimerScreen(
                        chore: expiredChore,
                        userId: testUserId,
                        householdRepo: mockRepo,
                        audioService: mockAudio,
                      ),
                    ),
                  );
                },
                child: const Text('COMMANDEMENT_ROOT'),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Navigate to Timer
      await tester.tap(find.text('COMMANDEMENT_ROOT'));
      await tester.pumpAndSettle();

      final holdBtn = find.text('MAINTENIR POUR VALIDER');
      expect(holdBtn, findsOneWidget);
      await tester.ensureVisible(holdBtn);

      // Validate mission
      final gesture = await tester.startGesture(tester.getCenter(holdBtn));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      // Debriefing screen shown
      expect(find.text('MISSION ACCOMPLIE'), findsOneWidget);

      // Tap Return to Commandement
      final returnBtn = find.text('Retour au Commandement');
      await tester.ensureVisible(returnBtn);
      await tester.tap(returnBtn);
      await tester.pumpAndSettle();

      // Back on commandement root
      expect(find.text('COMMANDEMENT_ROOT'), findsOneWidget);

      // Chore in repo now has recent lastCompletedAt
      final chores = await mockRepo.getChores(testUserId);
      final updated = chores.first;
      expect(updated.lastCompletedAt, isNotNull);
      final difference = DateTime.now().difference(updated.lastCompletedAt!);
      expect(difference.inMinutes, lessThan(1));
    });
  });
}
