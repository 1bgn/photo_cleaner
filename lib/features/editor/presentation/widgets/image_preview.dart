import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../editor_controller.dart';
import 'background_blur_painter.dart';

class ImagePreview extends StatelessWidget {
  const ImagePreview({super.key, required this.controller});

  final BackgroundBlurController controller;

  @override
  Widget build(BuildContext context) {

    return Watch((context, ) {
      final img = controller.rawImage.watch(context);
      if (img == null) return const SizedBox.shrink();

      final mask = controller.alphaMaskImage.watch(context);
      final blur = controller.blurAmount.watch(context);
      final feather = controller.maskFeather.watch(context);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imgW = img.width.toDouble();
            final imgH = img.height.toDouble();
            final ratio = imgW / imgH;

            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;

            double drawW = maxW;
            double drawH = drawW / ratio;

            if (drawH > maxH) {
              drawH = maxH;
              drawW = drawH * ratio;
            }

            if (drawW <= 0 || drawH <= 0) return const SizedBox.shrink();

            return Center(
              child: SizedBox(
                width: drawW,
                height: drawH,
                child: CustomPaint(
                  painter: BackgroundBlurPainter(
                    image: img,
                    alphaMask: mask,
                    blurAmount: blur,
                    maskFeather: feather,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
