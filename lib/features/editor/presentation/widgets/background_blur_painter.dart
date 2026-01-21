import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

class BackgroundBlurPainter extends CustomPainter {
  final ui.Image image;
  final ui.Image? alphaMask;
  final double blurAmount;
  final double maskFeather;

  const BackgroundBlurPainter({
    required this.image,
    required this.alphaMask,
    required this.blurAmount,
    required this.maskFeather,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 ||
        size.height <= 0 ||
        size.width.isNaN ||
        size.height.isNaN ||
        size.width.isInfinite ||
        size.height.isInfinite) {
      return;
    }

    final dst = Offset.zero & size;

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    if (src.width <= 0 || src.height <= 0) return;

    canvas.save();
    canvas.clipRect(dst);

    // 1) blurred bg
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.high
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: blurAmount,
          sigmaY: blurAmount,
        ),
    );

    final mask = alphaMask;
    if (mask == null) {
      canvas.restore();
      return;
    }

    // 2) sharp person with dstIn mask
    canvas.saveLayer(dst, Paint());

    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );

    final maskSrc = Rect.fromLTWH(
      0,
      0,
      mask.width.toDouble(),
      mask.height.toDouble(),
    );

    if (maskSrc.width > 0 && maskSrc.height > 0) {
      canvas.drawImageRect(
        mask,
        maskSrc,
        dst,
        Paint()
          ..isAntiAlias = true
          ..blendMode = ui.BlendMode.dstIn
          ..imageFilter = (maskFeather > 0)
              ? ui.ImageFilter.blur(sigmaX: maskFeather, sigmaY: maskFeather)
              : null,
      );
    }

    canvas.restore(); // layer
    canvas.restore(); // clip
  }

  @override
  bool shouldRepaint(covariant BackgroundBlurPainter old) {
    return old.image != image ||
        old.alphaMask != alphaMask ||
        old.blurAmount != blurAmount ||
        old.maskFeather != maskFeather;
  }
}
