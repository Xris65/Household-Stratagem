import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'services/audio_service.dart';

class TimerScreen extends StatefulWidget {
  final AudioService? audioService;

  const TimerScreen({super.key, this.audioService});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _timeLeft = 600; // 10 minutes
  Timer? _timer;
  bool _isSessionMuted = false;
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _audioService = widget.audioService ?? RealAudioService();
    _isSessionMuted = !_audioService.musicEnabled;
    final trackToPlay = _audioService.selectedTrack;
    _audioService.playMissionLoop(trackToPlay).catchError((e) {
      debugPrint('Audio play failed: $e');
    });
    if (_isSessionMuted) {
      _audioService.pauseMissionLoop();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
        }
      });
    });
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
    _audioService.stop();
    super.dispose();
  }

  void _validateMission() {
    _timer?.cancel();
    _timer = null;
    _audioService.stop();
    _audioService.playVictory();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('MISSION ACCOMPLISHED', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.yellowAccent,
      ),
    );
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
                    const Icon(Icons.graphic_eq, color: Colors.yellowAccent, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COMMUNICATIONS TACTIQUES',
                            style: TextStyle(
                              color: Colors.yellowAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
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
                  builder: (context, activeTrack, _) {
                        return Column(
                          children: RealAudioService.missionTracks.map((track) {
                            final isSelected = track.assetPath == activeTrack || track.id == activeTrack;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Material(
                                color: isSelected
                                    ? Colors.yellowAccent.withValues(alpha: 0.12)
                                    : const Color(0xFF1A1A1A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: BorderSide(
                                    color: isSelected ? Colors.yellowAccent : Colors.white12,
                                    width: isSelected ? 2.0 : 1.0,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                leading: Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: isSelected ? Colors.yellowAccent : Colors.white38,
                                ),
                                title: Text(
                                  track.title,
                                  style: TextStyle(
                                    color: isSelected ? Colors.yellowAccent : Colors.white,
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
                                          color: Colors.yellowAccent.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.yellowAccent, width: 1),
                                        ),
                                        child: const Text(
                                          'ACTIF',
                                          style: TextStyle(
                                            color: Colors.yellowAccent,
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
                                  if (_isSessionMuted) {
                                    await _audioService.pauseMissionLoop();
                                  }
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.graphic_eq, color: Colors.yellowAccent, size: 18),
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MISSION IN PROGRESS', style: TextStyle(color: Colors.yellowAccent)),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music, color: Colors.yellowAccent),
            tooltip: 'Changer de bande-son',
            onPressed: _showTacticalMusicSelector,
          ),
          IconButton(
            icon: Icon(
              _isSessionMuted ? Icons.volume_off : Icons.volume_up,
              color: _isSessionMuted ? const Color(0xFFFF5252) : Colors.yellowAccent,
            ),
            tooltip: _isSessionMuted ? 'Rétablir le son (mission)' : 'Couper le son (mission temporaire)',
            onPressed: _toggleSessionMute,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 60, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _isSessionMuted
                            ? const Color(0xFFFF5252)
                            : Colors.yellowAccent.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSessionMuted ? Icons.music_off : Icons.graphic_eq,
                          size: 16,
                          color: _isSessionMuted ? const Color(0xFFFF5252) : Colors.yellowAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isSessionMuted ? '[MUTÉ] ${track.title}' : 'PISTE: ${track.title}',
                          style: TextStyle(
                            color: _isSessionMuted ? Colors.white54 : Colors.yellowAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down, color: Colors.yellowAccent, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onLongPress: _validateMission,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'LONG PRESS TO VALIDATE',
                  style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
