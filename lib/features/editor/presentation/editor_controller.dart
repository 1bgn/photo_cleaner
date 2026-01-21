import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:signals/signals.dart';

@injectable
class BackgroundBlurController {
  BackgroundBlurController(
      this._picker,
      this._segmenter,
      );

  final ImagePicker _picker;
  final SelfieSegmenter _segmenter;

  // ------------------- signals (state) -------------------

  final imageFile = signal<File?>(null);
  final rawImage = signal<ui.Image?>(null);
  final mask = signal<SegmentationMask?>(null);

  /// Готовая RGBA альфа-маска (в белом цвете, alpha = уверенность)
  final alphaMaskImage = signal<ui.Image?>(null);

  final isProcessing = signal<bool>(false);
  final errorMessage = signal<String?>(null);

  final blurAmount = signal<double>(25.0);

  final maskFeather = signal<double>(2.0);

  final maskThreshold = signal<double>(0.5);

  final maskSoftness = signal<double>(0.15);

  // ------------------- internals -------------------

  Timer? _maskRebuildDebounce;
  int _maskBuildToken = 0;
  bool _disposed = false;

  void dispose() {
    _disposed = true;
    _maskRebuildDebounce?.cancel();
    _maskBuildToken++;

    // dispose ui.Image безопасно
    final r = rawImage.value;
    final a = alphaMaskImage.value;

    rawImage.value = null;
    alphaMaskImage.value = null;

    if (r != null) _disposeImageAfterFrame(r);
    if (a != null) _disposeImageAfterFrame(a);

    _segmenter.close();
  }

  // ---------------- SAFETY: never dispose image "right now" ----------------

  void _disposeImageAfterFrame(ui.Image img) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        img.dispose();
      } catch (_) {}
    });
  }

  void _setRawImageSafely(ui.Image? newImage) {
    final old = rawImage.value;
    rawImage.value = newImage;
    if (old != null && old != newImage) _disposeImageAfterFrame(old);
  }

  void _setAlphaMaskSafely(ui.Image? newMask) {
    final old = alphaMaskImage.value;
    alphaMaskImage.value = newMask;
    if (old != null && old != newMask) _disposeImageAfterFrame(old);
  }

  void clearAll() {
    _maskRebuildDebounce?.cancel();
    _maskBuildToken++;

    imageFile.value = null;
    mask.value = null;
    errorMessage.value = null;

    final oldRaw = rawImage.value;
    final oldMask = alphaMaskImage.value;

    rawImage.value = null;
    alphaMaskImage.value = null;

    if (oldRaw != null) _disposeImageAfterFrame(oldRaw);
    if (oldMask != null) _disposeImageAfterFrame(oldMask);
  }

  // ------------------- public API -------------------

  Future<void> pickAndProcessImage() async {
    if (_disposed) return;

    isProcessing.value = true;
    errorMessage.value = null;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 1000,
        maxWidth: 700,
      );
      if (picked == null) return;

      // очистка предыдущего
      clearAll();
      imageFile.value = File(picked.path);

      final fileSize = await imageFile.value!.length();
      if (fileSize > 10 * 1024 * 1024) {
        errorMessage.value = 'Файл слишком большой (максимум 10MB)';
        return;
      }

      final inputImage = InputImage.fromFile(imageFile.value!);
      final segMask = await _segmenter.processImage(inputImage);

      if (segMask == null) {
        errorMessage.value = 'Не удалось сегментировать изображение';
        return;
      }

      final data = await imageFile.value!.readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      final img = frame.image;

      // build alpha mask
      final alpha = await _buildAlphaMaskImage(
        segMask,
        threshold: maskThreshold.value,
        softness: maskSoftness.value,
      );

      if (_disposed) {
        img.dispose();
        alpha.dispose();
        return;
      }

      mask.value = segMask;
      _setRawImageSafely(img);
      _setAlphaMaskSafely(alpha);
    } catch (e) {
      errorMessage.value = 'Ошибка: $e';
    } finally {
      isProcessing.value = false;
    }
  }

  void applyMaskSettings({
    required double feather,
    required double threshold,
    required double softness,
  }) {
    maskFeather.value = feather;
    maskThreshold.value = threshold;
    maskSoftness.value = softness;

    scheduleAlphaMaskRebuild();
  }

  void scheduleAlphaMaskRebuild() {
    final currentMask = mask.value;
    if (currentMask == null || _disposed) return;

    final token = ++_maskBuildToken;
    _maskRebuildDebounce?.cancel();

    _maskRebuildDebounce = Timer(const Duration(milliseconds: 120), () async {
      final built = await _buildAlphaMaskImage(
        currentMask,
        threshold: maskThreshold.value,
        softness: maskSoftness.value,
      );

      if (_disposed || token != _maskBuildToken) {
        built.dispose();
        return;
      }

      _setAlphaMaskSafely(built);
    });
  }

  Future<File> renderAndSaveToTempPng() async {
    final src = rawImage.value;
    if (src == null) {
      throw StateError('Нет изображения для сохранения');
    }

    final rendered = await _renderResultImage(
      src: src,
      alphaMask: alphaMaskImage.value,
      blurAmount: blurAmount.value,
      maskFeather: maskFeather.value,
    );

    final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
    rendered.dispose();

    if (byteData == null) throw Exception('Не удалось получить байты изображения');

    final tempDir = await Directory.systemTemp.createTemp();
    final outputFile = File('${tempDir.path}/blurred_output.png');
    await outputFile.writeAsBytes(byteData.buffer.asUint8List());

    return outputFile;
  }

  // ------------------- rendering + mask build -------------------

  Future<ui.Image> _buildAlphaMaskImage(
      SegmentationMask segMask, {
        required double threshold,
        required double softness,
      }) async {
    final w = segMask.width;
    final h = segMask.height;

    final bytes = Uint8List(w * h * 4);
    final n = math.min(segMask.confidences.length, w * h);

    double smoothstep(double e0, double e1, double x) {
      if ((e1 - e0).abs() < 1e-9) return x >= e1 ? 1.0 : 0.0;
      final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
      return t * t * (3 - 2 * t);
    }

    final e0 = threshold - softness;
    final e1 = threshold + softness;

    for (int i = 0; i < w * h; i++) {
      final c = (i < n) ? segMask.confidences[i] : 0.0;
      final a = smoothstep(e0, e1, c);
      final alpha = (a * 255).round();

      final o = i * 4;
      bytes[o + 0] = 255;
      bytes[o + 1] = 255;
      bytes[o + 2] = 255;
      bytes[o + 3] = alpha;
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      bytes,
      w,
      h,
      ui.PixelFormat.rgba8888,
          (img) => completer.complete(img),
    );

    return completer.future;
  }

  Future<ui.Image> _renderResultImage({
    required ui.Image src,
    required ui.Image? alphaMask,
    required double blurAmount,
    required double maskFeather,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final fullRect = Rect.fromLTWH(
      0,
      0,
      src.width.toDouble(),
      src.height.toDouble(),
    );

    // 1) blurred bg
    canvas.drawImage(
      src,
      Offset.zero,
      Paint()
        ..filterQuality = FilterQuality.high
        ..imageFilter = ui.ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
    );

    // 2) sharp person
    if (alphaMask != null) {
      canvas.saveLayer(fullRect, Paint());

      canvas.drawImage(
        src,
        Offset.zero,
        Paint()..filterQuality = FilterQuality.high,
      );

      final maskSrc = Rect.fromLTWH(
        0,
        0,
        alphaMask.width.toDouble(),
        alphaMask.height.toDouble(),
      );

      canvas.drawImageRect(
        alphaMask,
        maskSrc,
        fullRect,
        Paint()
          ..isAntiAlias = true
          ..blendMode = ui.BlendMode.dstIn
          ..imageFilter = (maskFeather > 0)
              ? ui.ImageFilter.blur(sigmaX: maskFeather, sigmaY: maskFeather)
              : null,
      );

      canvas.restore();
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(src.width, src.height);
    picture.dispose();
    return img;
  }
}
