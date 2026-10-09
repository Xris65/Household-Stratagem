import 'package:flutter/material.dart';
import 'services/audio_service.dart';
import 'timer_screen.dart';

class StratagemScreen extends StatefulWidget {
  const StratagemScreen({super.key});

  @override
  _StratagemScreenState createState() => _StratagemScreenState();
}

class _StratagemScreenState extends State<StratagemScreen> {
  final List<String> _sequence = [];

  void _onSwipe(String direction) {
    RealAudioService().playSwipe();
    setState(() {
      _sequence.add(direction);
      if (_sequence.length >= 4) {
        RealAudioService().playDeploy();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TimerScreen()),
        );
        _sequence.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('STRATAGEM DEPLOYMENT', style: TextStyle(color: Colors.yellowAccent)),
        backgroundColor: Colors.black87,
      ),
      body: GestureDetector(
        onPanEnd: (details) {
          final double dx = details.velocity.pixelsPerSecond.dx;
          final double dy = details.velocity.pixelsPerSecond.dy;
          final double threshold = 100.0;

          if (dx.abs() > dy.abs()) {
            if (dx > threshold) {
              _onSwipe('RIGHT');
            } else if (dx < -threshold) {
              _onSwipe('LEFT');
            }
          } else {
            if (dy > threshold) {
              _onSwipe('DOWN');
            } else if (dy < -threshold) {
              _onSwipe('UP');
            }
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ENTER STRATAGEM CODE',
                  style: TextStyle(color: Colors.yellowAccent, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _sequence.map((dir) {
                    IconData iconData;
                    switch (dir) {
                      case 'UP': iconData = Icons.arrow_upward; break;
                      case 'DOWN': iconData = Icons.arrow_downward; break;
                      case 'LEFT': iconData = Icons.arrow_back; break;
                      case 'RIGHT': iconData = Icons.arrow_forward; break;
                      default: iconData = Icons.help;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(iconData, color: Colors.cyanAccent, size: 40),
                    );
                  }).toList(),
                ),
                SizedBox(height: 50),
                Text(
                  'SWIPE TO INPUT',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
