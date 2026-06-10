import 'dart:math' as math;
import 'package:flutter/material.dart';

class CompassPointer extends StatelessWidget {
  /// Heading dalam derajat 
  final double heading;

  final double size;

  const CompassPointer({
    super.key,
    required this.heading,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
   
    final radians = heading * (math.pi / 180);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Transform.rotate(
        angle: radians, 
        child: CustomPaint(
      
          painter: _CompassArrowPainter(heading: heading),
        ),
      ),
    );
  }
}


class _CompassArrowPainter extends CustomPainter {

  final double heading;

  const _CompassArrowPainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.30;

  
    final northPath = Path()
      ..moveTo(cx, cy - r)         // ujung atas
      ..lineTo(cx + r * 0.35, cy)  // kanan tengah
      ..lineTo(cx, cy - r * 0.15)  // lekuk dalam
      ..lineTo(cx - r * 0.35, cy)  // kiri tengah
      ..close();

    canvas.drawPath(
      northPath,
      Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.fill,
    );


    final southPath = Path()
      ..moveTo(cx, cy + r)         // ujung bawah
      ..lineTo(cx + r * 0.35, cy)  // kanan tengah
      ..lineTo(cx, cy + r * 0.15)  // lekuk dalam
      ..lineTo(cx - r * 0.35, cy)  // kiri tengah
      ..close();

    canvas.drawPath(
      southPath,
      Paint()
        ..color = const Color(0xFF9E9E9E)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.18,
      Paint()..color = const Color(0xFF1A3C5E),
    );
  }

  @override

  bool shouldRepaint(_CompassArrowPainter old) => old.heading != heading;
}