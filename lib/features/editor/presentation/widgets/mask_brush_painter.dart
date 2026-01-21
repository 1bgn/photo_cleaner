import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../editor_controller.dart';
import '../mask/brush_models.dart';

class MaskBrushPainter extends CustomPainter {
  MaskBrushPainter({
    required this.controller,
    required this.imageSize,
  });

  final EditorController controller;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    Offset toWidget(ui.Offset p) {
      final sx = size.width / imageSize.width;
      final sy = size.height / imageSize.height;
      return Offset(p.dx * sx, p.dy * sy);
    }

    void drawStroke(BrushStroke s) {
      if (s.points.length < 2) return;

      final scaledWidth =
      (s.size * (size.width / imageSize.width)).clamp(1.0, 120.0);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = scaledWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;

      // превью: add = красный, erase = циан
      if (s.mode == BrushMode.add) {
        paint.color = const ui.Color(0x88FF0000);
      } else {
        paint.color = const ui.Color(0x8800FFFF);
      }

      final path = Path()
        ..moveTo(toWidget(s.points[0]).dx, toWidget(s.points[0]).dy);

      for (int i = 1; i < s.points.length; i++) {
        final p = toWidget(s.points[i]);
        path.lineTo(p.dx, p.dy);
      }

      canvas.drawPath(path, paint);
    }

    for (final s in controller.strokes) {
      drawStroke(s);
    }
    final a = controller.activeStroke;
    if (a != null) drawStroke(a);
  }

  @override
  bool shouldRepaint(covariant MaskBrushPainter oldDelegate) => true;
}
