import 'package:flutter/material.dart';
import 'dart:async';
import 'services/audio_service.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _timeLeft = 600; // 10 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    RealAudioService().playMissionLoop(RealAudioService().selectedTrack);
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    RealAudioService().stop();
    super.dispose();
  }

  void _validateMission() {
    _timer?.cancel();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('MISSION ACCOMPLISHED', style: TextStyle(color: Colors.black)), backgroundColor: Colors.yellowAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('MISSION IN PROGRESS', style: TextStyle(color: Colors.yellowAccent)),
        backgroundColor: Colors.black87,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.redAccent, fontSize: 60, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 50),
            GestureDetector(
              onLongPress: _validateMission,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
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
