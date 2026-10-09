import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/models/chore.dart';
import 'package:household_stratagem/services/household_repository.dart';
import 'package:household_stratagem/services/audio_service.dart';
import 'package:household_stratagem/screens/timer_screen.dart' as screen_ts;
import 'package:household_stratagem/timer_screen.dart' as root_ts;

void main() {
  group('TimerScreen (screens/timer_screen.dart) - Temporary Mute & Track Switcher', () {
    late MockAudioService mockAudio;
    late InMemoryHouseholdRepository mockRepo;
    late Chore testChore;

    setUp(() {
      mockAudio = MockAudioService();
      mockRepo = InMemoryHouseholdRepository(autoSeed: false);
      testChore = Chore(
        id: 'chore_clean_dishes',
        name: 'Nettoyer la vaisselle',
        difficulty: 3,
        room: 'Cuisine',
        periodicityDays: 1,
        durationMinutes: 10,
        swipeSequence: ['up', 'down'],
      );
    });

    tearDown(() {
      mockAudio.dispose();
    });

    testWidgets('Initializes with mission music playing when musicEnabled is true', (tester) async {
      await mockAudio.setMusicEnabled(true);

      await tester.pumpWidget(
        MaterialApp(
          home: screen_ts.TimerScreen(
            chore: testChore,
            userId: 'user_test',
            householdRepo: mockRepo,
            audioService: mockAudio,
          ),
        ),
      );
      await tester.pump();

      expect(mockAudio.isPlaying, isTrue);
      expect(mockAudio.currentTrack, equals('tactical_ambiance_1.mp3'));
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.textContaining('NETTOYER LA VAISSELLE'), findsOneWidget);
      expect(find.textContaining('PISTE: MISSION ALPHA'), findsOneWidget);
    });

    testWidgets('Tapping mute button toggles _isSessionMuted and pauses/resumes mission loop', (tester) async {
      await mockAudio.setMusicEnabled(true);

      await tester.pumpWidget(
        MaterialApp(
          home: screen_ts.TimerScreen(
            chore: testChore,
            userId: 'user_test',
            householdRepo: mockRepo,
            audioService: mockAudio,
          ),
        ),
      );
      await tester.pump();

      // Initially unmuted: shows volume_up
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(mockAudio.isMissionPaused, isFalse);
      expect(mockAudio.musicEnabled, isTrue);

      // Tap mute button: triggers _toggleSessionMute
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();

      // Icon immediately updates to volume_off
      expect(find.byIcon(Icons.volume_off), findsWidgets);
      expect(mockAudio.isMissionPaused, isTrue);
      expect(mockAudio.pauseCount, equals(1));
      // Permanent global setting remains strictly untouched!
      expect(mockAudio.musicEnabled, isTrue);

      // Tap again: unmutes and resumes
      await tester.tap(find.byIcon(Icons.volume_off).first);
      await tester.pump();

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(mockAudio.isMissionPaused, isFalse);
      expect(mockAudio.resumeCount, equals(1));
      // Permanent global setting still strictly untouched!
      expect(mockAudio.musicEnabled, isTrue);
    });

    testWidgets('In-mission music selector sheet allows live track switching', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen_ts.TimerScreen(
            chore: testChore,
            userId: 'user_test',
            householdRepo: mockRepo,
            audioService: mockAudio,
          ),
        ),
      );
      await tester.pump();

      // Open selector via tactical queue_music button
      expect(find.byIcon(Icons.queue_music), findsOneWidget);
      await tester.tap(find.byIcon(Icons.queue_music));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify bottom sheet appeared with tactical tracks
      expect(find.text('COMMUNICATIONS TACTIQUES'), findsOneWidget);
      expect(find.text('Mission Bravo: Tactical Questionmark'), findsOneWidget);

      // Tap on track 2
      await tester.tap(find.text('Mission Bravo: Tactical Questionmark'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Audio switched to track 2
      expect(mockAudio.switchTrackCount, equals(1));
      expect(mockAudio.selectedTrack, equals('tactical_ambiance_2.mp3'));
      expect(mockAudio.currentTrack, equals('tactical_ambiance_2.mp3'));

      // In-mission banner updated on-screen
      expect(find.textContaining('PISTE: MISSION BRAVO'), findsOneWidget);
    });

    testWidgets('Tapping live audio banner opens music selector sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen_ts.TimerScreen(
            chore: testChore,
            userId: 'user_test',
            householdRepo: mockRepo,
            audioService: mockAudio,
          ),
        ),
      );
      await tester.pump();

      // Tap on the CHANGER badge in the banner
      await tester.tap(find.text('CHANGER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('COMMUNICATIONS TACTIQUES'), findsOneWidget);
      expect(find.text('Mission Charlie: Heavy Recon'), findsOneWidget);

      // Select Mission Charlie
      await tester.tap(find.text('Mission Charlie: Heavy Recon'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(mockAudio.selectedTrack, equals('tactical_ambiance_3.mp3'));
    });

    testWidgets('Safe disposal does not throw use-after-dispose crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen_ts.TimerScreen(
            chore: testChore,
            userId: 'user_test',
            householdRepo: mockRepo,
            audioService: mockAudio,
          ),
        ),
      );
      await tester.pump();

      // Start timer
      await tester.ensureVisible(find.text('DÉMARRER MISSION'));
      await tester.tap(find.text('DÉMARRER MISSION'));
      await tester.pump(const Duration(seconds: 1));

      // Pop/replace widget
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('NEW SCREEN'))),
      );
      await tester.pump(const Duration(seconds: 2));

      // Stop was called on audio service
      expect(mockAudio.stopCount, greaterThanOrEqualTo(1));
    });
  });

  group('TimerScreen (root lib/timer_screen.dart) - Temporary Mute & Track Switcher', () {
    late MockAudioService mockAudio;

    setUp(() {
      mockAudio = MockAudioService();
    });

    tearDown(() {
      mockAudio.dispose();
    });

    testWidgets('Initializes with timer and audio controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: root_ts.TimerScreen(audioService: mockAudio),
        ),
      );
      await tester.pump();

      expect(find.text('MISSION IN PROGRESS'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.byIcon(Icons.queue_music), findsOneWidget);
      expect(mockAudio.isPlaying, isTrue);
    });

    testWidgets('Tapping mute button toggles session mute and pauses loop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: root_ts.TimerScreen(audioService: mockAudio),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(mockAudio.isMissionPaused, isFalse);

      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();

      expect(find.byIcon(Icons.volume_off), findsWidgets);
      expect(mockAudio.isMissionPaused, isTrue);

      await tester.tap(find.byIcon(Icons.volume_off).first);
      await tester.pump();

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(mockAudio.isMissionPaused, isFalse);
    });

    testWidgets('In-mission music switcher changes track on the fly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: root_ts.TimerScreen(audioService: mockAudio),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.queue_music));
      await tester.pumpAndSettle();

      expect(find.text('COMMUNICATIONS TACTIQUES'), findsOneWidget);
      await tester.tap(find.text('Mission Bravo: Tactical Questionmark'));
      await tester.pumpAndSettle();

      expect(mockAudio.selectedTrack, equals('tactical_ambiance_2.mp3'));
      expect(mockAudio.switchTrackCount, equals(1));
    });
  });
}
