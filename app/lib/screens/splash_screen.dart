import 'package:flutter/material.dart';
import 'dart:async';
import 'auth_gate.dart';
import '../services/auth_service.dart';
import '../services/household_repository.dart';

import '../widgets/tactical_loader.dart';

class SplashScreen extends StatefulWidget {
  final AuthService authService;
  final HouseholdRepository householdRepo;

  const SplashScreen({
    super.key,
    required this.authService,
    required this.householdRepo,
  });

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AuthGate(
              authService: widget.authService,
              householdRepo: widget.householdRepo,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF050505),
      body: Stack(
        children: [
          // Deep dark grid background
          CustomPaint(
            painter: GridPainter(color: Theme.of(context).primaryColor),
            child: Container(),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TacticalLoader(size: 150),
                SizedBox(height: 50),
                Text(
                  'HOUSEHOLD STRATAGEM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    shadows: [
                      Shadow(color: Theme.of(context).primaryColor, blurRadius: 15.0),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'INITIALISATION DU SYSTÈME...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

    double spacing = 40.0;
    
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


