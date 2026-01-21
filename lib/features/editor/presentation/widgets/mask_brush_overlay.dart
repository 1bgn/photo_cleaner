import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../editor_controller.dart';
import 'mask_brush_painter.dart';

class MaskBrushOverlay extends StatelessWidget {
  const MaskBrushOverlay({
    super.key,
    required this.controller,
    required this.image,
  });

  final EditorController controller;
  final ui.Image image;

  ui.Offset _toImageSpace(Offset local, Size widgetSize) {
    final sx = image.width / widgetSize.width;
    final sy = image.height / widgetSize.height;

    final dx = (local.dx * sx).clamp(0.0, image.width.toDouble());
    final dy = (local.dy * sy).clamp(0.0, image.height.toDouble());
    return ui.Offset(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      // тик для перерисовки во время рисования
      controller.paintTick.watch(context);

      return LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) {
              final p = _toImageSpace(d.localPosition, size);
              controller.beginStroke(p);
            },
            onPanUpdate: (d) {
              final p = _toImageSpace(d.localPosition, size);
              controller.appendPoint(p);
            },
            onPanEnd: (_) {
              controller.endStroke(baseImage: image);
            },
            child: CustomPaint(
              painter: MaskBrushPainter(
                controller: controller,
                imageSize: Size(image.width.toDouble(), image.height.toDouble()),
              ),
            ),
          );
        },
      );
    });
  }
}
