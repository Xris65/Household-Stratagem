import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chore.dart';
import '../services/household_repository.dart';
import '../services/audio_service.dart';
import '../engine/stratagem_engine.dart';
import 'timer_screen.dart';

class StratagemScreen extends StatefulWidget {
  final Chore chore;
  final String userId;
  final HouseholdRepository householdRepo;

  const StratagemScreen({super.key, required this.chore, required this.userId, required this.householdRepo});

  @override
  _StratagemScreenState createState() => _StratagemScreenState();
}

class _StratagemScreenState extends State<StratagemScreen> {
  late List<String> _targetSequence;
  int _currentIndex = 0;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _targetSequence = widget.chore.stratagemSequence.isNotEmpty
        ? widget.chore.stratagemSequence
        : StratagemEngine.generateSequenceForDifficulty(widget.chore.difficulty);
  }

  void _triggerError() async {
    setState(() => _isError = true);
    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _currentIndex = 0;
        _isError = false;
      });
    }
  }

  void _onSwipe(String direction) {
    if (_isError) return;

    setState(() {
      if (StratagemEngine.isMoveCorrect(_targetSequence, _currentIndex, direction)) {
        HapticFeedback.heavyImpact();
        RealAudioService().playSwipe();
        _currentIndex++;
        if (_currentIndex >= _targetSequence.length) {
          RealAudioService().playDeploy();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TimerScreen(chore: widget.chore, userId: widget.userId, householdRepo: widget.householdRepo)),
          );
        }
      } else {
        _triggerError();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chore.name)),
      body: GestureDetector(
        onPanEnd: (details) {
          final dx = details.velocity.pixelsPerSecond.dx;
          final dy = details.velocity.pixelsPerSecond.dy;

          if (dx.abs() > dy.abs()) {
            if (dx > 100) {
              _onSwipe('RIGHT');
            } else if (dx < -100) {
              _onSwipe('LEFT');
            }
          } else {
            if (dy > 100) {
              _onSwipe('DOWN');
            } else if (dy < -100) {
              _onSwipe('UP');
            }
          }
        },
        child: Container(
          color: Colors.transparent, // required for gesture detector
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isError ? 'Séquence réinitialisée' : 'Balayez pour valider la séquence',
                  style: TextStyle(
                    color: _isError ? Theme.of(context).colorScheme.error : Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16,
                    fontWeight: _isError ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(_targetSequence.length, (index) {
                    final direction = _targetSequence[index];
                    final isActive = index == _currentIndex;
                    final isDone = index < _currentIndex;
                    
                    Color iconColor;
                    if (_isError) {
                      iconColor = Theme.of(context).colorScheme.error;
                    } else if (isDone) {
                      iconColor = Theme.of(context).primaryColor;
                    } else if (isActive) {
                      iconColor = Colors.white;
                    } else {
                      iconColor = Colors.white30;
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? iconColor.withValues(alpha: 0.1) : Colors.transparent,
                        border: Border.all(color: iconColor.withValues(alpha: isActive || _isError ? 1.0 : 0.3), width: isActive ? 2 : 1),
                      ),
                      child: Icon(
                        _getIconForDirection(direction),
                        size: 32,
                        color: iconColor,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForDirection(String dir) {
    switch(dir) {
      case 'UP': return Icons.keyboard_arrow_up;
      case 'DOWN': return Icons.keyboard_arrow_down;
      case 'LEFT': return Icons.keyboard_arrow_left;
      case 'RIGHT': return Icons.keyboard_arrow_right;
      default: return Icons.help_outline;
    }
  }
}
