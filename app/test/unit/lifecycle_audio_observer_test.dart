import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:household_stratagem/main.dart';
import 'package:household_stratagem/services/auth_service.dart';
import 'package:household_stratagem/services/household_repository.dart';
import 'package:household_stratagem/theme/theme_manager.dart';
import 'package:household_stratagem/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void simulateBackground(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  }

  void simulateForeground(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  group('HouseholdStratagemApp - AppLifecycle Audio Observer Tests', () {
    late MockAudioService mockAudio;
    late FakeAuthService authService;
    late InMemoryHouseholdRepository householdRepo;
    late ThemeManager themeManager;

    setUp(() {
      mockAudio = MockAudioService();
      authService = FakeAuthService();
      householdRepo = InMemoryHouseholdRepository(autoSeed: false);
      themeManager = ThemeManager();
    });

    tearDown(() {
      mockAudio.dispose();
    });

    testWidgets('Pauses app ambiance when minimized/paused, and resumes when app returns to foreground',
        (WidgetTester tester) async {
      await mockAudio.playBridgeLoop();
      expect(mockAudio.isBridgePlaying, isTrue);

      await tester.pumpWidget(HouseholdStratagemApp(
        authService: authService,
        householdRepo: householdRepo,
        themeManager: themeManager,
        audioService: mockAudio,
      ));
      await tester.pumpAndSettle();

      // Backgrounding app: inactive -> hidden -> paused
      simulateBackground(tester);
      await tester.pump();

      // App ambiance must be automatically paused
      expect(mockAudio.isBridgePlaying, isFalse);

      // Foregrounding app: hidden -> inactive -> resumed
      simulateForeground(tester);
      await tester.pump();

      // App ambiance resumes automatically
      expect(mockAudio.isBridgePlaying, isTrue);
    });

    testWidgets('Mission music continues playing in the background when app is minimized',
        (WidgetTester tester) async {
      await mockAudio.playMissionLoop('tactical_ambiance_1.mp3');
      expect(mockAudio.isPlaying, isTrue);
      expect(mockAudio.isMissionPaused, isFalse);

      await tester.pumpWidget(HouseholdStratagemApp(
        authService: authService,
        householdRepo: householdRepo,
        themeManager: themeManager,
        audioService: mockAudio,
      ));
      await tester.pumpAndSettle();

      // Simulate app minimizing / user puts phone in pocket: inactive -> hidden -> paused
      simulateBackground(tester);
      await tester.pump();

      // Mission music must CONTINUE playing!
      expect(mockAudio.isPlaying, isTrue);
      expect(mockAudio.isMissionPaused, isFalse);

      // Returning to foreground
      simulateForeground(tester);
      await tester.pump();

      // Mission music still uninterrupted
      expect(mockAudio.isPlaying, isTrue);
      expect(mockAudio.isMissionPaused, isFalse);
    });

    testWidgets('Disposes observer cleanly without throwing exceptions',
        (WidgetTester tester) async {
      await tester.pumpWidget(HouseholdStratagemApp(
        authService: authService,
        householdRepo: householdRepo,
        themeManager: themeManager,
        audioService: mockAudio,
      ));
      await tester.pumpAndSettle();

      // Replace root widget to trigger dispose
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      // Verify no crashes on subsequent lifecycle events
      simulateBackground(tester);
      await tester.pump();
    });
  });
}
