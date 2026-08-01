import 'package:flutter/material.dart';

/// Paints a small speech-bubble tail on the bottom edge of a bubble.
class BubbleTailPainter extends CustomPainter {
  /// Creates a tail painter.
  const BubbleTailPainter({required this.color, required this.isOutgoing});

  /// Tail fill color (match the bubble).
  final Color color;

  /// Whether the tail points to the right (outgoing) or left (incoming).
  final bool isOutgoing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (isOutgoing) {
      path.moveTo(0, 0);
      path.quadraticBezierTo(size.width, 0, size.width, size.height);
      path.quadraticBezierTo(size.width * 0.4, size.height * 0.4, 0, 0);
    } else {
      path.moveTo(size.width, 0);
      path.quadraticBezierTo(0, 0, 0, size.height);
      path.quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.4,
        size.width,
        0,
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isOutgoing != isOutgoing;
}
