import 'package:flutter/material.dart';
import 'dart:math' as math;

class TacticalLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const TacticalLoader({
    super.key,
    this.size = 80.0,
    this.color,
  });

  @override
  State<TacticalLoader> createState() => _TacticalLoaderState();
}

class _TacticalLoaderState extends State<TacticalLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.color ?? Theme.of(context).primaryColor;
    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _OuterRingPainter(color: themeColor.withValues(alpha: 0.8)),
              ),
              Container(
                width: widget.size * 0.15,
                height: widget.size * 0.15,
                decoration: BoxDecoration(
                  color: themeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: themeColor, blurRadius: 15, spreadRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // ignore: use_null_aware_elements
                if (child != null) child,
                Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(widget.size * 0.8, widget.size * 0.8),
                    painter: _RadarSweepPainter(color: themeColor),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OuterRingPainter extends CustomPainter {
  final Color color;
  _OuterRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    const dashCount = 12;
    const sweepAngle = (2 * math.pi) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        final rect = Rect.fromCircle(center: center, radius: radius);
        canvas.drawArc(rect, i * sweepAngle, sweepAngle * 0.6, false, glowPaint);
        canvas.drawArc(rect, i * sweepAngle, sweepAngle * 0.6, false, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarSweepPainter extends CustomPainter {
  final Color color;
  _RadarSweepPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [Colors.transparent, color.withValues(alpha: 0.3), color],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      rect,
      0,
      math.pi / 2, // 90 degree sweep
      true,
      paint,
    );

    // Leading edge solid thick line
    final edgePaint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    final edgeX = center.dx + radius * math.cos(math.pi / 2);
    final edgeY = center.dy + radius * math.sin(math.pi / 2);
    canvas.drawLine(center, Offset(edgeX, edgeY), edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


