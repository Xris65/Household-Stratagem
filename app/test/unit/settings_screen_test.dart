import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/screens/settings_screen.dart';
import 'package:household_stratagem/screens/onboarding_screen.dart';
import 'package:household_stratagem/services/auth_service.dart';
import 'package:household_stratagem/services/household_repository.dart';
import 'package:household_stratagem/services/audio_service.dart';
import 'package:household_stratagem/models/user_profile.dart';
import 'package:household_stratagem/theme/theme_manager.dart';

void main() {
  group('SettingsScreen Audio Preview & Configuration Tests', () {
    late FakeAuthService authService;
    late InMemoryHouseholdRepository householdRepo;
    late MockAudioService audioService;
    late ThemeManager themeManager;

    setUp(() {
      authService = FakeAuthService();
      householdRepo = InMemoryHouseholdRepository();
      audioService = MockAudioService();
      themeManager = ThemeManager();
    });

    Widget createTestWidget() {
      return ThemeProvider(
        notifier: themeManager,
        child: MaterialApp(
          home: SettingsScreen(
            userId: 'agent-42',
            authService: authService,
            householdRepo: householdRepo,
            audioService: audioService,
          ),
        ),
      );
    }

    testWidgets('renders all 6 selectable tracks in music selection',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 3200));
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('BANDE-SON DES MISSIONS (6 PISTES)'), findsOneWidget);
      expect(SettingsScreen.selectableTracks.length, equals(6));

      for (final track in SettingsScreen.selectableTracks) {
        expect(find.text(track.title), findsOneWidget);
      }
    });

    testWidgets('renders sample preview button next to each track',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 3200));
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final playButtons = find.byIcon(Icons.play_circle_fill_rounded);
      expect(playButtons, findsNWidgets(6));
    });

    testWidgets(
        'tapping preview toggles play/stop icon and selecting track updates repo and audioService',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 3200));
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      final initialProfile = UserProfile(
        userId: 'agent-42',
        agentName: 'TestAgent',
        selectedAudioTrack: 'tactical_ambiance_1.mp3',
      );
      await householdRepo.saveUserProfile(initialProfile);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap preview on track 2
      final track2Preview = find.byIcon(Icons.play_circle_fill_rounded).at(1);
      await tester.tap(track2Preview);
      await tester.pump();

      // Track 2 should now have stop icon
      expect(find.byIcon(Icons.stop_circle_rounded), findsOneWidget);
      expect(find.text('▶ LECTURE'), findsOneWidget);
      expect(audioService.previewPlayCount, equals(1));
      expect(audioService.previewingTrackNotifier.value, equals('tactical_ambiance_2.mp3'));

      // Tap stop on track 2 preview
      final stopButton = find.byIcon(Icons.stop_circle_rounded);
      await tester.tap(stopButton);
      await tester.pump();

      // All 6 buttons are back to play icon
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsNWidgets(6));
      expect(find.text('▶ LECTURE'), findsNothing);
      expect(audioService.previewStopCount, equals(1));
      expect(audioService.previewingTrackNotifier.value, isNull);

      // Select track 3
      final track3Title = find.text('Mission Charlie: Heavy Recon');
      await tester.tap(track3Title);
      await tester.pumpAndSettle();

      // AudioService was updated
      expect(audioService.selectedTrack, equals('tactical_ambiance_3.mp3'));

      // User profile in householdRepo was updated
      final updatedProfile = await householdRepo.getUserProfile('agent-42');
      expect(updatedProfile?.selectedAudioTrack,
          equals('tactical_ambiance_3.mp3'));
    });

    testWidgets(
        'active theme card badge is prominent with [ACTIF] and check_circle',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 3200));
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('[ACTIF]'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets(
        'credits section details all 6 tracks and bridge ambiance with CC licenses',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 3200));
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to credits card
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Crédits Audio & Licences'), findsOneWidget);
      expect(find.textContaining('Epic Battle'), findsWidgets);
      expect(find.textContaining('Epic Questionmark'), findsWidgets);
      expect(find.textContaining('Heavy Recon'), findsWidgets);
      expect(find.textContaining('Passerelle de Commandement (Bridge Ambiance)'),
          findsOneWidget);
      expect(find.textContaining('Signal de Déploiement (Tactical Deploy)'),
          findsOneWidget);
      expect(find.textContaining('Fanfare de Victoire (Victory Fanfare)'),
          findsOneWidget);
      expect(find.textContaining('CC BY 3.0'), findsWidgets);
      expect(find.textContaining('CC0 1.0 Universal'), findsWidgets);
    });

    testWidgets(
        'provides two completely independent toggles for App Ambiance and Mission Music',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 3200));
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ambiance Générale de l\'App'), findsOneWidget);
      expect(find.text('Musique de Mission (Timer)'), findsOneWidget);
      expect(find.text('Bruitages d\'action (SFX)'), findsOneWidget);

      // Initially both are true
      expect(audioService.appAmbianceEnabled, isTrue);
      expect(audioService.missionMusicEnabled, isTrue);

      // Toggle App Ambiance off
      final appAmbianceFinder =
          find.widgetWithText(SwitchListTile, 'Ambiance Générale de l\'App');
      await tester.tap(appAmbianceFinder);
      await tester.pumpAndSettle();

      // App Ambiance is now false, but Mission Music is STILL true!
      expect(audioService.appAmbianceEnabled, isFalse);
      expect(audioService.missionMusicEnabled, isTrue);

      // Toggle Mission Music off
      final missionMusicFinder =
          find.widgetWithText(SwitchListTile, 'Musique de Mission (Timer)');
      await tester.tap(missionMusicFinder);
      await tester.pumpAndSettle();

      // Now both are false
      expect(audioService.appAmbianceEnabled, isFalse);
      expect(audioService.missionMusicEnabled, isFalse);

      // Toggle App Ambiance back on
      await tester.tap(appAmbianceFinder);
      await tester.pumpAndSettle();

      // App Ambiance is true, Mission Music remains false!
      expect(audioService.appAmbianceEnabled, isTrue);
      expect(audioService.missionMusicEnabled, isFalse);
    });

    testWidgets('renders real dynamic user profile stats from repository',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 3200));
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      final customProfile = UserProfile(
        userId: 'agent-42',
        agentName: 'Commander-Ghost',
        level: 7,
        medals: 25,
        credits: 850,
      );
      await householdRepo.saveUserProfile(customProfile);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Statistiques du soldat'), findsOneWidget);
      expect(find.text('AGENT : COMMANDER-GHOST'), findsOneWidget);
      expect(find.text('RANG 7'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('850'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('renders graceful default profile stats when profile is null',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 3200));
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Statistiques du soldat'), findsOneWidget);
      expect(find.text('AGENT : NETTOYEUR-1'), findsOneWidget);
      expect(find.text('RANG 1'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2)); // medals & credits
    });

    testWidgets('renders top priority chores config card and opens onboarding',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 3200));
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Configuration des Corvées'), findsOneWidget);
      expect(find.text('Personnaliser les pièces, tâches, fréquences et durées'),
          findsOneWidget);
      expect(find.text('ÉDITEUR'), findsOneWidget);

      await tester.tap(find.text('Configuration des Corvées'));
      await tester.pumpAndSettle();

      // Successfully navigated to OnboardingScreen
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('previewingTrackNotifier updates keep play/stop button and [▶ LECTURE] badge reactive and synchronized',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 3200));
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially all are play buttons
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsNWidgets(6));
      expect(find.byIcon(Icons.stop_circle_rounded), findsNothing);
      expect(find.text('▶ LECTURE'), findsNothing);

      // Externally update notifier to track 3
      audioService.previewingTrackNotifier.value = 'tactical_ambiance_3.mp3';
      await tester.pump();

      // UI reacts instantly: stop button and badge on track 3
      expect(find.byIcon(Icons.stop_circle_rounded), findsOneWidget);
      expect(find.text('▶ LECTURE'), findsOneWidget);

      // Externally clear notifier
      audioService.previewingTrackNotifier.value = null;
      await tester.pump();

      expect(find.byIcon(Icons.stop_circle_rounded), findsNothing);
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsNWidgets(6));
      expect(find.text('▶ LECTURE'), findsNothing);
    });

    testWidgets('leaving SettingsScreen restores general app ambiance and stops preview',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 3200));
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      // Start bridge loop
      await audioService.playBridgeLoop();
      expect(audioService.isBridgePlaying, isTrue);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap preview on track 1: bridge ambiance is paused, preview starts
      await tester.tap(find.byIcon(Icons.play_circle_fill_rounded).first);
      await tester.pump();

      expect(audioService.isPreviewActive, isTrue);
      expect(audioService.isBridgePlaying, isFalse);

      // Leave screen (simulate pop / dispose)
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      // Preview is stopped and bridge ambiance is restored!
      expect(audioService.isPreviewActive, isFalse);
      expect(audioService.isBridgePlaying, isTrue);
    });

    testWidgets('selecting a track stops active preview and restores ambiance',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 3200));
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetPhysicalSize();
      });

      await audioService.playBridgeLoop();
      expect(audioService.isBridgePlaying, isTrue);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Start preview on track 2
      final track2Preview = find.byIcon(Icons.play_circle_fill_rounded).at(1);
      await tester.tap(track2Preview);
      await tester.pump();

      expect(audioService.isPreviewActive, isTrue);
      expect(audioService.isBridgePlaying, isFalse);

      // Select track 4
      final track4Title = find.text('Mission Delta: Dark Synth');
      await tester.tap(track4Title);
      await tester.pumpAndSettle();

      // Preview is stopped and bridge ambiance is restored!
      expect(audioService.isPreviewActive, isFalse);
      expect(audioService.selectedTrack, equals('tactical_ambiance_4.mp3'));
      expect(audioService.isBridgePlaying, isTrue);
    });
  });
}
