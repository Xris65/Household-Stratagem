import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chore.dart';
import '../services/household_repository.dart';
import '../services/audio_service.dart';

/// Tactical mission debriefing and victory screen displayed after successfully
/// completing a cleaning operation (either by timer expiration or hold-to-validate).
class MissionCompleteScreen extends StatelessWidget {
  final Chore chore;
  final int durationSeconds;
  final int creditsReward;
  final int medalsReward;
  final String userId;
  final HouseholdRepository householdRepo;
  final AudioService? audioService;
  final VoidCallback? onReturnHome;

  const MissionCompleteScreen({
    super.key,
    required this.chore,
    required this.durationSeconds,
    this.creditsReward = 50,
    this.medalsReward = 1,
    required this.userId,
    required this.householdRepo,
    this.audioService,
    this.onReturnHome,
  });

  /// Formats duration in seconds into standard tactical MM:SS format.
  String _formatDuration(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final m = s ~/ 60;
    final remS = s % 60;
    return '${m.toString().padLeft(2, '0')}:${remS.toString().padLeft(2, '0')}';
  }

  /// Maps room name to a tactical visual icon.
  IconData _getRoomIcon(String room) {
    final lower = room.toLowerCase();
    if (lower.contains('cuis')) {
      return Icons.kitchen;
    } else if (lower.contains('bain') || lower.contains('douche') || lower.contains('eau')) {
      return Icons.bathtub;
    } else if (lower.contains('salon') || lower.contains('sejour') || lower.contains('séjour')) {
      return Icons.weekend;
    } else if (lower.contains('cham')) {
      return Icons.bed;
    } else {
      return Icons.meeting_room;
    }
  }

  void _handleReturnToCommand(BuildContext context) {
    HapticFeedback.heavyImpact();
    if (onReturnHome != null) {
      onReturnHome!();
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    const goldColor = Color(0xFFFFD54F);

    return Scaffold(
      backgroundColor: const Color(0xFF070707),
      appBar: AppBar(
        title: Text(
          'DÉBRIEFING TACTIQUE',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: primary.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Glowing Title Section
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.12),
                    border: Border.all(color: primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.military_tech,
                    color: primary,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'MISSION ACCOMPLIE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.5,
                    shadows: [
                      Shadow(
                        color: primary.withValues(alpha: 0.8),
                        blurRadius: 20,
                      ),
                      Shadow(
                        color: primary.withValues(alpha: 0.4),
                        blurRadius: 35,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: primary.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    '[ PROTOCOLE D\'ASSAINISSEMENT EXÉCUTÉ ]',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Chore Recap Card
              _buildChoreRecapCard(context, primary),
              const SizedBox(height: 16),

              // Time Spent Card
              _buildTimeSpentCard(context, primary),
              const SizedBox(height: 16),

              // Rewards Card
              _buildRewardsCard(context, primary, goldColor),
              const SizedBox(height: 28),

              // Tactical Action Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  key: const Key('btn_return_command'),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text(
                    'Retour au Commandement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.black,
                    elevation: 8,
                    shadowColor: primary.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Colors.white24, width: 1),
                    ),
                  ),
                  onPressed: () => _handleReturnToCommand(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoreRecapCard(BuildContext context, Color primary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in, color: primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'RÉCAPITULATIF DE L\'OBJECTIF',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            chore.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              // Room Category Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getRoomIcon(chore.room), color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      chore.room.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Difficulty Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield, color: Color(0xFFFFB74D), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'DIFFICULTÉ ${chore.difficulty}/5',
                      style: const TextStyle(
                        color: Color(0xFFFFB74D),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSpentCard(BuildContext context, Color primary) {
    final formattedTime = _formatDuration(durationSeconds);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primary.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.timer, color: primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TEMPS D\'ENGAGEMENT',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: TextStyle(
                    color: primary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsCard(BuildContext context, Color primary, Color goldColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: goldColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: goldColor.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: goldColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'RÉCOMPENSES DE COMMANDEMENT',
                style: TextStyle(
                  color: goldColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Credits Reward Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: primary.withValues(alpha: 0.6), width: 1.2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.monetization_on, color: primary, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        '+$creditsReward Crédits',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'RÉQUISITIONS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Medal Reward Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: goldColor.withValues(alpha: 0.6), width: 1.2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.military_tech, color: goldColor, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        '+$medalsReward Médaille',
                        style: TextStyle(
                          color: goldColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'HONNEUR',
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
