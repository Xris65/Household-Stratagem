import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/chore.dart';
import '../models/mission_log.dart';
import '../models/user_profile.dart';
import '../services/household_repository.dart';
import '../services/audio_service.dart';
import 'mission_complete_screen.dart';

class TimerScreen extends StatefulWidget {
  final Chore chore;
  final String userId;
  final HouseholdRepository householdRepo;
  final AudioService? audioService;

  const TimerScreen({
    super.key,
    required this.chore,
    required this.userId,
    required this.householdRepo,
    this.audioService,
  });

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  int _timeLeft = 0;
  int _initialTime = 0;
  bool _isRunning = false;
  Timer? _timer;
  bool _isSessionMuted = false;
  bool _isCompleting = false;
  
  late AudioService _audioService;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.chore.durationMinutes * 60;
    _initialTime = _timeLeft;
    
    _audioService = widget.audioService ?? RealAudioService();
    _isSessionMuted = !_audioService.musicEnabled;
    final trackToPlay = _audioService.selectedTrack;
    _audioService.playMissionLoop(trackToPlay).catchError((e) {
      debugPrint('Audio play failed: $e');
    });
    if (_isSessionMuted) {
      _audioService.pauseMissionLoop();
    }

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  void _toggleSessionMute() {
    setState(() {
      _isSessionMuted = !_isSessionMuted;
    });
    if (_isSessionMuted) {
      _audioService.pauseMissionLoop();
    } else {
      _audioService.resumeMissionLoop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _radarController.dispose();
    if (!_isCompleting) {
      _audioService.stop();
    }
    super.dispose();
  }

  void _toggleTimer() {
    if (_isCompleting) return;
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        if (_timeLeft <= 0) {
          _isRunning = false;
          _completeMission();
          return;
        }
        _radarController.repeat();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          if (_isCompleting) {
            timer.cancel();
            return;
          }
          if (_timeLeft > 1) {
            setState(() {
              _timeLeft--;
            });
          } else {
            setState(() {
              _timeLeft = 0;
              _isRunning = false;
            });
            timer.cancel();
            _timer = null;
            _radarController.stop();
            _completeMission();
          }
        });
      } else {
        _radarController.stop();
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  void _adjustTime(int deltaSeconds) {
    if (_isRunning || _isCompleting) return;
    setState(() {
      _timeLeft += deltaSeconds;
      if (_timeLeft < 60) _timeLeft = 60; // minimum 1 min
      _initialTime = _timeLeft;
    });
  }

  Future<void> _completeMission() async {
    if (_isCompleting) return;
    _isCompleting = true;

    HapticFeedback.heavyImpact();
    _timer?.cancel();
    _timer = null;
    if (_radarController.isAnimating) {
      _radarController.stop();
    }
    if (_isRunning) {
      setState(() {
        _isRunning = false;
      });
    }

    // Immediately stop mission music!
    await _audioService.stop();
    // Play victory SFX!
    await _audioService.playVictory();

    // Calculate actual duration taken (_initialTime - _timeLeft or full duration if 00:00)
    final durationTaken = (_timeLeft <= 0)
        ? _initialTime
        : math.max(0, _initialTime - _timeLeft);

    final now = DateTime.now();
    final log = MissionLog(
      id: now.millisecondsSinceEpoch.toString(),
      choreId: widget.chore.id,
      choreName: widget.chore.name,
      room: widget.chore.room,
      completedAt: now,
      durationSeconds: durationTaken,
      success: true,
    );

    try {
      // 1. Save mission log
      await widget.householdRepo.logMission(widget.userId, log);

      // 2. Update chore lastCompletedAt so urgency resets to 0% on home screen
      final updatedChore = widget.chore.copyWith(lastCompletedAt: now);
      await widget.householdRepo.updateChore(widget.userId, updatedChore);

      // 3. Grant rewards: fetch current UserProfile, add +50 Credits and +1 Medal, and save back
      final currentProfile = await widget.householdRepo.getUserProfile(widget.userId);
      final profile = currentProfile ?? UserProfile(userId: widget.userId);
      final updatedProfile = profile.copyWith(
        credits: profile.credits + 50,
        medals: profile.medals + 1,
      );
      await widget.householdRepo.saveUserProfile(updatedProfile);
    } catch (e) {
      debugPrint('Error saving mission completion: $e');
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MissionCompleteScreen(
            chore: widget.chore,
            durationSeconds: durationTaken,
            creditsReward: 50,
            medalsReward: 1,
            userId: widget.userId,
            householdRepo: widget.householdRepo,
            audioService: _audioService,
          ),
        ),
      );
    }
  }

  void _showTacticalMusicSelector() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Colors.white24, width: 1),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(context);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.graphic_eq, color: theme.colorScheme.secondary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COMMUNICATIONS TACTIQUES',
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'SÉLECTION BANDE-SON EN DIRECT',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60),
                      onPressed: () {
                        if (Navigator.canPop(sheetContext)) {
                          Navigator.pop(sheetContext);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: _audioService.selectedTrackNotifier,
                  builder: (_, activeTrack, _) {
                        return Column(
                          children: RealAudioService.missionTracks.map((track) {
                            final isSelected = track.assetPath == activeTrack || track.id == activeTrack;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Material(
                                color: isSelected
                                    ? theme.primaryColor.withValues(alpha: 0.12)
                                    : const Color(0xFF1A1A1A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: BorderSide(
                                    color: isSelected ? theme.primaryColor : Colors.white12,
                                    width: isSelected ? 2.0 : 1.0,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                leading: Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: isSelected ? theme.primaryColor : Colors.white38,
                                ),
                                title: Text(
                                  track.title,
                                  style: TextStyle(
                                    color: isSelected ? theme.primaryColor : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  '${track.subtitle} • ${track.artist}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: isSelected
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: theme.primaryColor, width: 1),
                                        ),
                                        child: Text(
                                          'ACTIF',
                                          style: TextStyle(
                                            color: theme.primaryColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      )
                                    : null,
                                onTap: () async {
                                  HapticFeedback.selectionClick();
                                  final messenger = ScaffoldMessenger.of(context);
                                  Navigator.pop(sheetContext);
                                  await _audioService.switchMissionTrack(track.id);
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.graphic_eq, color: theme.primaryColor, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'BANDE-SON ENGAGÉE : ${track.title}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF1E1E1E),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    
    final isCritical = _timeLeft <= 60 && _isRunning;
    final timerColor = isCritical ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor;
    final progress = _initialTime > 0 ? (_timeLeft / _initialTime) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: Text('MISSION ACTIVE', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.queue_music, color: Theme.of(context).primaryColor),
            tooltip: 'Changer de bande-son',
            onPressed: _showTacticalMusicSelector,
          ),
          IconButton(
            icon: Icon(
              _isSessionMuted ? Icons.volume_off : Icons.volume_up,
              color: _isSessionMuted ? const Color(0xFFFF5252) : Theme.of(context).primaryColor,
            ),
            tooltip: _isSessionMuted ? 'Rétablir le son (mission)' : 'Couper le son (mission temporaire)',
            onPressed: _toggleSessionMute,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), height: 1.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
            // Tactical Objectives Panel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8), width: 2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15), blurRadius: 15, spreadRadius: 2),
                ],
              ),
              child: Column(
                children: [
                  Text('OBJECTIF PRIMAIRE', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, letterSpacing: 3.0, fontSize: 12)),
                  const SizedBox(height: 12),
                  Text(
                    widget.chore.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LIEU: ${widget.chore.room.toUpperCase()}',
                    style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
            // Tactical Live Audio Transmission Banner
            ValueListenableBuilder<String>(
              valueListenable: _audioService.selectedTrackNotifier,
              builder: (context, currentTrackPath, _) {
                final track = RealAudioService.missionTracks.firstWhere(
                  (t) => t.assetPath == currentTrackPath || t.id == currentTrackPath,
                  orElse: () => RealAudioService.missionTracks.first,
                );
                return InkWell(
                  onTap: _showTacticalMusicSelector,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101010),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _isSessionMuted
                            ? const Color(0xFFFF5252).withValues(alpha: 0.6)
                            : Theme.of(context).primaryColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSessionMuted ? Icons.music_off : Icons.graphic_eq,
                          size: 16,
                          color: _isSessionMuted ? const Color(0xFFFF5252) : Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isSessionMuted
                                ? '[SILENCE RADIO] ${track.title.toUpperCase()}'
                                : 'PISTE: ${track.title.toUpperCase()}',
                            style: TextStyle(
                              color: _isSessionMuted ? Colors.white54 : Theme.of(context).primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CHANGER',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Neon Countdown & Radar
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(timerColor.withValues(alpha: 0.5)),
                  ),
                ),
                if (_isRunning)
                  SizedBox(
                    width: 320,
                    height: 320,
                    child: AnimatedBuilder(
                      animation: _radarController,
                      builder: (_, child) {
                        return Transform.rotate(
                          angle: _radarController.value * 2 * math.pi,
                          child: CustomPaint(
                            painter: RadarPainter(color: timerColor),
                          ),
                        );
                      },
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: timerColor,
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        shadows: [
                          Shadow(color: timerColor.withValues(alpha: 0.8), blurRadius: 20),
                          Shadow(color: timerColor.withValues(alpha: 0.4), blurRadius: 40),
                        ],
                      ),
                    ),
                    if (!_isRunning && _timeLeft > 0)
                      Text('EN ATTENTE...', style: TextStyle(color: Colors.white54, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Time Adjustment (Only when paused)
            if (!_isRunning)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).primaryColor, size: 36),
                    onPressed: () => _adjustTime(-60),
                  ),
                  SizedBox(width: 40),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor, size: 36),
                    onPressed: () => _adjustTime(60),
                  ),
                ],
              ),
            SizedBox(height: 24),
            
            // Play/Pause Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _toggleTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.transparent : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  foregroundColor: _isRunning ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor,
                  side: BorderSide(color: _isRunning ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  _isRunning ? 'SUSPENDRE MISSION' : 'DÉMARRER MISSION',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Hazard Action Button
            HazardButton(
              onValidated: _completeMission,
              isEnabled: !_isCompleting,
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final Color color;
  RadarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [Colors.transparent, color.withValues(alpha: 0.1), color.withValues(alpha: 0.6)],
        stops: [0.0, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi / 2, // 90 degree sweep
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HazardButton extends StatefulWidget {
  final VoidCallback onValidated;
  final bool isEnabled;
  const HazardButton({
    super.key,
    required this.onValidated,
    this.isEnabled = true,
  });

  @override
  _HazardButtonState createState() => _HazardButtonState();
}

class _HazardButtonState extends State<HazardButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_triggered) {
        _triggered = true;
        if (mounted) {
          widget.onValidated();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        if (!widget.isEnabled || _triggered) return;
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onPointerUp: (_) {
        if (!_triggered) _controller.reverse();
      },
      onPointerCancel: (_) {
        if (!_triggered) _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final isPressing = _controller.value > 0;
          return Container(
            height: 65,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Theme.of(context).colorScheme.secondary, width: isPressing ? 4 : 2),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                if (isPressing)
                  BoxShadow(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: _controller.value,
                  heightFactor: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3), Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'MAINTENIR POUR VALIDER',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


