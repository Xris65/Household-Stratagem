import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/chore.dart';
import '../models/mission_log.dart';
import '../services/household_repository.dart';
import '../services/audio_service.dart';

class TimerScreen extends StatefulWidget {
  final Chore chore;
  final String userId;
  final HouseholdRepository householdRepo;

  const TimerScreen({super.key, required this.chore, required this.userId, required this.householdRepo});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  int _timeLeft = 0;
  int _initialTime = 0;
  bool _isRunning = false;
  Timer? _timer;
  
  late AudioService _audioService;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.chore.durationMinutes * 60;
    _initialTime = _timeLeft;
    
    _audioService = RealAudioService();
    final trackToPlay = _audioService.selectedTrack;
    _audioService.playMissionLoop(trackToPlay).catchError((e) {
      debugPrint('Audio play failed: $e');
    });

    _radarController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _radarController.dispose();
    _audioService.stop();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _timer = Timer.periodic(Duration(seconds: 1), (timer) {
          setState(() {
            if (_timeLeft > 0) {
              _timeLeft--;
            } else {
              _isRunning = false;
              _timer?.cancel();
            }
          });
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _adjustTime(int deltaSeconds) {
    if (_isRunning) return;
    setState(() {
      _timeLeft += deltaSeconds;
      if (_timeLeft < 60) _timeLeft = 60; // minimum 1 min
      _initialTime = _timeLeft;
    });
  }

  Future<void> _validateMission() async {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    _audioService.stop();
    _audioService.playVictory();
    
    final duration = _initialTime - _timeLeft;
    final log = MissionLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      choreId: widget.chore.id,
      choreName: widget.chore.name,
      room: widget.chore.room,
      completedAt: DateTime.now(),
      durationSeconds: duration > 0 ? duration : 0,
      success: true,
    );
    await widget.householdRepo.logMission(widget.userId, log);
    
    final updatedChore = widget.chore.copyWith(lastCompletedAt: DateTime.now());
    await widget.householdRepo.updateChore(widget.userId, updatedChore);

    if (mounted) {
      Navigator.pop(context); // Return to Home
    }
  }

  @override
  Widget build(BuildContext context) {
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    
    final isCritical = _timeLeft <= 60 && _isRunning;
    final timerColor = isCritical ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor;
    final progress = _initialTime > 0 ? (_timeLeft / _initialTime) : 0.0;

    return Scaffold(
      backgroundColor: Color(0xFF050505),
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
          ValueListenableBuilder<bool>(
            valueListenable: _audioService.muteNotifier,
            builder: (context, isMuted, child) {
              return IconButton(
                icon: Icon(
                  isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  _audioService.toggleMute();
                },
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), height: 1.0),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            // Tactical Objectives Panel
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Color(0xFF141414),
                border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8), width: 2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15), blurRadius: 15, spreadRadius: 2),
                ],
              ),
              child: Column(
                children: [
                  Text('OBJECTIF PRIMAIRE', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, letterSpacing: 3.0, fontSize: 12)),
                  SizedBox(height: 12),
                  Text(
                    widget.chore.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'LIEU: ${widget.chore.room.toUpperCase()}',
                    style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
            Spacer(),
            
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
            Spacer(),
            
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
            HazardButton(onValidated: _validateMission),
          ],
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
  const HazardButton({super.key, required this.onValidated});

  @override
  _HazardButtonState createState() => _HazardButtonState();
}

class _HazardButtonState extends State<HazardButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 1500));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_triggered) {
        _triggered = true;
        widget.onValidated();
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
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) {
        if (!_triggered) _controller.reverse();
      },
      onTapCancel: () {
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


