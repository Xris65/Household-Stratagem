import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/household_repository.dart';
import '../services/auth_service.dart';
import '../services/audio_service.dart';
import '../models/chore.dart';
import '../engine/targeting_engine.dart';
import '../engine/stratagem_engine.dart';
import 'timer_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final HouseholdRepository householdRepo;
  final AuthService authService;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.householdRepo,
    required this.authService,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Chore> _topChores = [];
  int _selectedIndex = 0;
  
  List<String> _targetSequence = [];
  int _currentSwipeIndex = 0;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadChores();
    RealAudioService().playBridgeLoop();
  }

  Future<void> _loadChores() async {
    final chores = await widget.householdRepo.getChores(widget.userId);
    setState(() {
      _topChores = TargetingEngine.getTopTargets(chores, count: 3);
      if (_topChores.isNotEmpty) {
        _selectedIndex = 0;
        _initSequenceForChore(_topChores[_selectedIndex]);
      }
    });
  }

  void _initSequenceForChore(Chore chore) {
    _targetSequence = chore.stratagemSequence.isNotEmpty
        ? chore.stratagemSequence
        : StratagemEngine.generateSequenceForDifficulty(chore.difficulty);
    _currentSwipeIndex = 0;
    _isError = false;
  }

  void _triggerError() async {
    setState(() => _isError = true);
    HapticFeedback.vibrate();
    await Future.delayed(Duration(milliseconds: 100));
    HapticFeedback.vibrate();
    await Future.delayed(Duration(milliseconds: 100));
    HapticFeedback.vibrate();
    await Future.delayed(Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _currentSwipeIndex = 0;
        _isError = false;
      });
    }
  }

  void _onSwipe(String direction) {
    if (_isError || _topChores.isEmpty) return;

    setState(() {
      if (StratagemEngine.isMoveCorrect(_targetSequence, _currentSwipeIndex, direction)) {
        HapticFeedback.heavyImpact();
        RealAudioService().playSwipe();
        
        _currentSwipeIndex++;
        if (_currentSwipeIndex >= _targetSequence.length) {
          RealAudioService().playDeploy();
          final selectedChore = _topChores[_selectedIndex];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TimerScreen(
                chore: selectedChore,
                userId: widget.userId,
                householdRepo: widget.householdRepo,
              ),
            ),
          ).then((_) {
            _loadChores();
            RealAudioService().resumeBridgeLoop();
          });
        }
      } else {
        _triggerError();
      }
    });
  }

  Widget _buildMissionCard(BuildContext context, int index, Chore chore, bool isSelected) {
    String priorityText;
    if (index == 0) {
      priorityText = '[ PRIORITÉ 1 - CRITIQUE ]';
    } else if (index == 1) {
      priorityText = '[ PRIORITÉ 2 - ÉLEVÉE ]';
    } else {
      priorityText = '[ PRIORITÉ 3 - NORMALE ]';
    }

    final daysElapsed = chore.lastCompletedAt == null ? chore.periodicityDays : DateTime.now().difference(chore.lastCompletedAt!).inDays;
    final progress = (daysElapsed / chore.periodicityDays).clamp(0.05, 1.0);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _initSequenceForChore(chore);
        });
      },
      child: Container(
        width: 260,
        margin: EdgeInsets.only(right: 16, bottom: 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main Card Body
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF141414) : Color(0xFF1A1A1A).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.white12,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2)]
                    : [],
              ),
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MISSION', style: TextStyle(color: isSelected ? Theme.of(context).primaryColor : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                  SizedBox(height: 4),
                  Text(
                    chore.name.toUpperCase(),
                    maxLines: 3,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, height: 1.2),
                  ),
                  SizedBox(height: 8),
                  Text(
                    chore.room.toUpperCase(),
                    style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text(priorityText, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  Text('⏱ ${chore.durationMinutes} MIN • DIFF: ${chore.difficulty}', style: TextStyle(color: isSelected ? Theme.of(context).primaryColor : Colors.white30, fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(height: 12),
                  // Progress percentage and bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('URGENCE: ${(progress * 100).toInt()}%', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: 1.0)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5), blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Top "ACTIVE" Pill
            if (isSelected)
              Positioned(
                top: -12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.5), blurRadius: 8)],
                    ),
                    child: Text('CIBLE ACTIVE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackpad() {
    return GestureDetector(
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
        height: 300,
        margin: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Stack(
          children: [
            CustomPaint(painter: GridPainter(color: Theme.of(context).primaryColor), child: Container()),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 64, color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                  SizedBox(height: 16),
                  Text(
                    'ZONE TACTIQUE - EFFECTUEZ LA SÉQUENCE',
                    style: TextStyle(color: Theme.of(context).primaryColor.withValues(alpha: 0.5), fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStratagemTerminal() {
    return Container(
      padding: EdgeInsets.only(top: 20, bottom: 40, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Color(0xFF050505),
        border: Border(top: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
        boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Column(
        children: [
          Text(
            _isError ? 'SÉQUENCE COMPROMISE' : 'SÉQUENCE D\'ACTIVATION',
            style: TextStyle(
              color: _isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(_targetSequence.length, (index) {
              final direction = _targetSequence[index];
              final isActive = index == _currentSwipeIndex;
              final isDone = index < _currentSwipeIndex;
              
              Color bgColor;
              Color iconColor;
              Color borderColor;

              if (_isError) {
                bgColor = Theme.of(context).colorScheme.error.withValues(alpha: 0.2);
                iconColor = Theme.of(context).colorScheme.error;
                borderColor = Theme.of(context).colorScheme.error;
              } else if (isDone) {
                bgColor = Theme.of(context).primaryColor;
                iconColor = Colors.black;
                borderColor = Theme.of(context).primaryColor;
              } else if (isActive) {
                bgColor = Theme.of(context).primaryColor.withValues(alpha: 0.2);
                iconColor = Theme.of(context).primaryColor;
                borderColor = Theme.of(context).primaryColor;
              } else {
                bgColor = Colors.transparent;
                iconColor = Colors.white54;
                borderColor = Colors.white24;
              }

              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: borderColor, width: isActive ? 3 : 2),
                  boxShadow: (isDone || isActive) && !_isError ? [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)] : null,
                ),
                child: Center(
                  child: Icon(
                    _getIconForDirection(direction),
                    size: 36,
                    color: iconColor,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text('Terminal Tactique', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.secondary),
            tooltip: 'Configuration Système',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    userId: widget.userId,
                    householdRepo: widget.householdRepo,
                    authService: widget.authService,
                  ),
                ),
              ).then((_) => _loadChores());
            },
          ),
        ],
      ),
      body: _topChores.isEmpty
          ? Center(child: Text('Aucune tâche disponible.', style: TextStyle(color: Colors.white)))
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Panel: Missions
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(right: BorderSide(color: Colors.white10)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'CIBLES PRIORITAIRES',
                                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  itemCount: _topChores.length,
                                  itemBuilder: (context, index) {
                                    final chore = _topChores[index];
                                    final isSelected = index == _selectedIndex;
                                    return SizedBox(
                                      height: 250,
                                      child: _buildMissionCard(context, index, chore, isSelected)
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Right Panel: Trackpad + Terminal
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: _buildTrackpad()),
                              ),
                            ),
                            _buildStratagemTerminal(),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mobile Portrait Layout
                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'CIBLES PRIORITAIRES',
                                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                ),
                                SizedBox(height: 12),
                                SizedBox(
                                  height: 320,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _topChores.length,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    itemBuilder: (context, index) {
                                      final chore = _topChores[index];
                                      final isSelected = index == _selectedIndex;
                                      return _buildMissionCard(context, index, chore, isSelected);
                                    },
                                  ),
                                ),
                                SizedBox(height: 16),
                                _buildTrackpad(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildStratagemTerminal(),
                    ],
                  );
                }
              },
            ),
    );
  }

  IconData _getIconForDirection(String dir) {
    switch(dir) {
      case 'UP': return Icons.arrow_upward;
      case 'DOWN': return Icons.arrow_downward;
      case 'LEFT': return Icons.arrow_back;
      case 'RIGHT': return Icons.arrow_forward;
      default: return Icons.help_outline;
    }
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;
    double spacing = 30.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
