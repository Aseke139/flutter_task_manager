import 'dart:math';
import 'package:flutter/material.dart';
import '../models/detection_models.dart';

class RadarPainter extends CustomPainter {
  final double sweepAngle;
  final List<DetectedBody> bodies;
  final List<RadarBlip> blips;
  final DetectionLevel level;
  final double pulseRadius;

  RadarPainter({
    required this.sweepAngle,
    required this.bodies,
    required this.blips,
    required this.level,
    required this.pulseRadius,
  });

  Color get _radarColor {
    switch (level) {
      case DetectionLevel.none:
        return const Color(0xFF00FF41);
      case DetectionLevel.low:
        return const Color(0xFF00FF41);
      case DetectionLevel.medium:
        return const Color(0xFFFFFF00);
      case DetectionLevel.high:
        return const Color(0xFFFF8800);
      case DetectionLevel.critical:
        return const Color(0xFFFF0000);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final color = _radarColor;

    _drawBackground(canvas, center, radius, color);
    _drawGridCircles(canvas, center, radius, color);
    _drawCrossLines(canvas, center, radius, color);
    _drawSweep(canvas, center, radius, color);
    _drawBlips(canvas, center, radius);
    _drawBodies(canvas, center, radius, color);
    _drawPulse(canvas, center, radius, color);
    _drawBorderRing(canvas, center, radius, color);
  }

  void _drawBackground(Canvas canvas, Offset center, double radius, Color color) {
    final bgPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Radial gradient overlay
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.05),
          color.withOpacity(0.02),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, gradientPaint);
  }

  void _drawGridCircles(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, paint);
    }

    // Range labels
    final textStyle = TextStyle(
      color: color.withOpacity(0.4),
      fontSize: 9,
      fontFamily: 'monospace',
    );
    final ranges = ['25%', '50%', '75%', '100%'];
    for (int i = 0; i < 4; i++) {
      final r = radius * (i + 1) / 4;
      final tp = TextPainter(
        text: TextSpan(text: ranges[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center + Offset(4, -r - tp.height));
    }
  }

  void _drawCrossLines(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 0.5;

    for (int i = 0; i < 12; i++) {
      final angle = i * pi / 6;
      canvas.drawLine(
        center,
        center + Offset(radius * cos(angle), radius * sin(angle)),
        paint,
      );
    }
  }

  void _drawSweep(Canvas canvas, Offset center, double radius, Color color) {
    // Sweep trail (gradient arc)
    const sweepSpan = pi / 2.5;
    final sweepPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 40; i++) {
      final t = i / 40.0;
      final startAngle = sweepAngle - sweepSpan * t;
      final opacity = (1.0 - t) * 0.35;

      sweepPaint.shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepSpan / 40,
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepSpan / 40,
        true,
        sweepPaint,
      );
    }

    // Sweep line
    final linePaint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      center + Offset(radius * cos(sweepAngle), radius * sin(sweepAngle)),
      linePaint,
    );
  }

  void _drawBlips(Canvas canvas, Offset center, double radius) {
    for (final blip in blips) {
      final intensity = blip.fadedIntensity;
      if (intensity <= 0) continue;

      final pos = center + Offset(
        blip.position.dx * radius,
        blip.position.dy * radius,
      );

      // Outer glow
      canvas.drawCircle(
        pos,
        8.0 * intensity,
        Paint()
          ..color = Colors.greenAccent.withOpacity(intensity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Core dot
      canvas.drawCircle(
        pos,
        3.0 * intensity,
        Paint()..color = Colors.greenAccent.withOpacity(intensity * 0.9),
      );
    }
  }

  void _drawBodies(Canvas canvas, Offset center, double radius, Color color) {
    for (final body in bodies) {
      final pos = center + Offset(
        body.radarPosition.dx * radius,
        body.radarPosition.dy * radius,
      );

      final bodyColor = body.isMoving
          ? Colors.redAccent
          : Colors.yellowAccent;

      // Outer pulse ring
      canvas.drawCircle(
        pos,
        14.0,
        Paint()
          ..color = bodyColor.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Inner glow
      canvas.drawCircle(
        pos,
        7.0,
        Paint()
          ..color = bodyColor.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Core dot
      canvas.drawCircle(
        pos,
        4.0,
        Paint()..color = bodyColor,
      );

      // Human silhouette icon (simple cross)
      final iconPaint = Paint()
        ..color = bodyColor.withOpacity(0.8)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      // Head
      canvas.drawCircle(pos + const Offset(0, -14), 4, Paint()..color = bodyColor.withOpacity(0.7));
      // Body line
      canvas.drawLine(pos + const Offset(0, -10), pos + const Offset(0, -2), iconPaint);
      // Arms
      canvas.drawLine(pos + const Offset(-5, -8), pos + const Offset(5, -8), iconPaint);
      // Legs
      canvas.drawLine(pos + const Offset(0, -2), pos + const Offset(-4, 5), iconPaint);
      canvas.drawLine(pos + const Offset(0, -2), pos + const Offset(4, 5), iconPaint);

      // Motion indicator
      if (body.isMoving) {
        final motionPaint = Paint()
          ..color = Colors.redAccent.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(pos, 18, motionPaint);
      }
    }
  }

  void _drawPulse(Canvas canvas, Offset center, double radius, Color color) {
    if (level == DetectionLevel.none) return;

    final pulseR = pulseRadius * radius;
    canvas.drawCircle(
      center,
      pulseR,
      Paint()
        ..color = color.withOpacity(0.1 * (1 - pulseRadius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawBorderRing(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Tick marks
    final tickPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 72; i++) {
      final angle = i * pi / 36;
      final isLong = i % 9 == 0;
      final inner = isLong ? radius - 8 : radius - 4;
      canvas.drawLine(
        center + Offset(inner * cos(angle), inner * sin(angle)),
        center + Offset(radius * cos(angle), radius * sin(angle)),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => true;
}
