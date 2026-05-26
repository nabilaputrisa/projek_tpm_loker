// lib/widgets/compass_pointer.dart
//
// Widget panah kompas yang berputar mengikuti heading magnetometer.
// Dipakai sebagai overlay di atas peta (MapPreviewWidget).

import 'dart:math' as math;
import 'package:flutter/material.dart';

class CompassPointer extends StatelessWidget {
  /// Heading dalam derajat (0–360). 0 = Utara.
  final double heading;

  /// Ukuran widget (diameter lingkaran latar). Default 44.
  final double size;

  const CompassPointer({
    super.key,
    required this.heading,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    // FIX BUG 1: Tanda POSITIF, bukan negatif.
    //
    // Logika yang benar:
    //   - Panah secara default menunjuk ke atas (Utara = 0°).
    //   - Flutter Transform.rotate dengan sudut positif → berputar SEARAH jarum jam.
    //   - heading 90° (Timur) → panah harus berputar 90° ke kanan (searah jarum jam).
    //   - Jadi angle = +radians, bukan -radians.
    //
    // Kesalahan sebelumnya: angle: -radians
    //   Akibatnya: heading 90° → panah ke Barat (terbalik).
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
        angle: radians, // FIX: positif → searah jarum jam = benar
        child: CustomPaint(
          // FIX BUG 2: Teruskan heading ke painter agar shouldRepaint bisa
          // membandingkan nilai lama vs baru secara akurat.
          painter: _CompassArrowPainter(heading: heading),
        ),
      ),
    );
  }
}

/// Melukis panah kompas dua warna (merah = Utara, abu = Selatan).
class _CompassArrowPainter extends CustomPainter {
  // FIX BUG 2: Tambah parameter heading agar shouldRepaint bisa bekerja.
  final double heading;

  const _CompassArrowPainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.30;

    // ── Panah Utara (merah) ───────────────────────────────────────────
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

    // ── Panah Selatan (abu-abu) ────────────────────────────────────────
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

    // ── Titik tengah ──────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.18,
      Paint()..color = const Color(0xFF1A3C5E),
    );
  }

  @override
  // FIX BUG 2: Repaint hanya jika heading benar-benar berubah.
  // Sebelumnya selalu `false` → painter tidak pernah tahu harus repaint.
  // (Meski rotasi ditangani Transform.rotate di atas, ini tetap best practice
  // agar painter selalu sinkron dengan state yang benar.)
  bool shouldRepaint(_CompassArrowPainter old) => old.heading != heading;
}