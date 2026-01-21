import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image_picker/image_picker.dart';

class BackgroundBlurPage extends StatefulWidget {
  const BackgroundBlurPage({super.key});

  @override
  State<BackgroundBlurPage> createState() => _BackgroundBlurPageState();
}

class _BackgroundBlurPageState extends State<BackgroundBlurPage> {
  final _picker = ImagePicker();
  late final SelfieSegmenter _segmenter;

  File? _imageFile;
  ui.Image? _rawImage;
  SegmentationMask? _mask;

  /// Готовая RGBA альфа-маска (в белом цвете, alpha = уверенность)
  ui.Image? _alphaMaskImage;

  bool _isProcessing = false;
  String? _errorMessage;

  double _blurAmount = 25.0;

  /// Сглаживание края (blur маски при применении)
  double _maskFeather = 2.0;

  /// Порог сегментации (центральная точка)
  double _maskThreshold = 0.5;

  /// Ширина мягкого перехода вокруг threshold (0..0.5)
  double _maskSoftness = 0.15;

  @override
  void initState() {
    super.initState();
    _segmenter = SelfieSegmenter(
      mode: SegmenterMode.single,
      enableRawSizeMask: true,
    );
  }

  @override
  void dispose() {
    _segmenter.close();
    _rawImage?.dispose();
    _alphaMaskImage?.dispose();
    super.dispose();
  }

  // --- Маска: confidences -> RGBA Image (alpha = уверенность) ---
  Future<ui.Image> _buildAlphaMaskImage(
    SegmentationMask mask, {
    required double threshold,
    required double softness,
  }) async {
    final w = mask.width;
    final h = mask.height;

    // ui.decodeImageFromPixels ожидает RGBA8888
    final bytes = Uint8List(w * h * 4);
    final n = math.min(mask.confidences.length, w * h);

    double smoothstep(double e0, double e1, double x) {
      final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
      return t * t * (3 - 2 * t);
    }

    final e0 = threshold - softness;
    final e1 = threshold + softness;

    for (int i = 0; i < w * h; i++) {
      final c = (i < n) ? mask.confidences[i] : 0.0;
      final a = smoothstep(e0, e1, c);
      final alpha = (a * 255).round();

      final o = i * 4;
      bytes[o + 0] = 255; // R
      bytes[o + 1] = 255; // G
      bytes[o + 2] = 255; // B
      bytes[o + 3] = alpha; // A
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

  // --- Вспомогательно: собрать итоговую картинку (как в painter) ---
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

    // 1) Размытый фон
    canvas.drawImage(
      src,
      Offset.zero,
      Paint()
        ..filterQuality = FilterQuality.high
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: blurAmount,
          sigmaY: blurAmount,
        ),
    );

    // 2) Чёткий человек поверх (если есть маска)
    if (alphaMask != null) {
      canvas.saveLayer(fullRect, Paint());

      // 2.1 Оригинал
      canvas.drawImage(
        src,
        Offset.zero,
        Paint()..filterQuality = FilterQuality.high,
      );

      // 2.2 dstIn маска
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

  Future<void> _saveResult() async {
    if (_rawImage == null) return;

    // Сначала спросим пользователя
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить результат'),
        content: const Text('Хотите сохранить обработанное изображение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      setState(() => _isProcessing = true);

      // Рендерим итог
      final rendered = await _renderResultImage(
        src: _rawImage!,
        alphaMask: _alphaMaskImage,
        blurAmount: _blurAmount,
        maskFeather: _maskFeather,
      );

      final byteData = await rendered.toByteData(
        format: ui.ImageByteFormat.png,
      );
      rendered.dispose();

      if (byteData == null) {
        throw Exception('Не удалось получить байты изображения');
      }

      // Пишем во временную папку
      final tempDir = await Directory.systemTemp.createTemp();
      final outputFile = File('${tempDir.path}/blurred_output.png');
      await outputFile.writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Сохранено: ${outputFile.path}')));

      // Если нужно именно "в галерею" — подключите пакет image_gallery_saver / gallery_saver
      // и сохраните оттуда.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickAndProcessImage() async {
    bool progressShown = false;

    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 1000,
        maxWidth: 700,
      );
      if (picked == null) return;

      _rawImage?.dispose();
      _alphaMaskImage?.dispose();
      _rawImage = null;
      _alphaMaskImage = null;
      _mask = null;

      _imageFile = File(picked.path);

      final fileSize = await _imageFile!.length();
      if (fileSize > 10 * 1024 * 1024) {
        setState(() => _errorMessage = 'Файл слишком большой (максимум 10MB)');
        return;
      }

      final inputImage = InputImage.fromFile(_imageFile!);

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Обработка изображения...'),
            ],
          ),
        ),
      );
      progressShown = true;

      final mask = await _segmenter.processImage(inputImage);

      if (mounted && progressShown) {
        Navigator.of(context).pop();
        progressShown = false;
      }

      if (mask == null) {
        setState(() => _errorMessage = 'Не удалось сегментировать изображение');
        return;
      }

      // Загружаем исходную картинку как ui.Image
      final data = await _imageFile!.readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      final img = frame.image;

      // Строим альфа-маску
      final alphaMask = await _buildAlphaMaskImage(
        mask,
        threshold: _maskThreshold,
        softness: _maskSoftness,
      );

      if (!mounted) {
        img.dispose();
        alphaMask.dispose();
        return;
      }

      setState(() {
        _rawImage = img;
        _mask = mask;
        _alphaMaskImage = alphaMask;
      });
    } catch (e) {
      if (mounted && progressShown) {
        Navigator.of(context).pop();
        progressShown = false;
      }
      if (mounted) {
        setState(() => _errorMessage = 'Ошибка: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _rawImage != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Фон блюр (Selfie Seg)')),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_rawImage != null)
            FloatingActionButton.small(
              onPressed: _isProcessing ? null : _saveResult,
              backgroundColor: Colors.green,
              child: const Icon(Icons.save, size: 20),
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _isProcessing ? null : _pickAndProcessImage,
            backgroundColor: _isProcessing ? Colors.grey : Colors.blue,
            child: _isProcessing
                ? const CircularProgressIndicator(strokeWidth: 2)
                : const Icon(Icons.photo),
          ),
        ],
      ),
      body: Center(
        child: !hasImage
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Выберите фото'),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              )
            : SafeArea(
          child: Column(
            children: [
              // --- Контролы (фиксируем, чтобы не прыгали строки) ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Сила размытия: ${_blurAmount.toStringAsFixed(1)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Slider(
                      value: _blurAmount,
                      min: 0.0,
                      max: 50.0,
                      divisions: 500,
                      label: _blurAmount.toStringAsFixed(1),
                      onChanged: (v) => setState(() => _blurAmount = v),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Feather края: ${_maskFeather.toStringAsFixed(1)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Slider(
                      value: _maskFeather,
                      min: 0.0,
                      max: 12.0,
                      divisions: 120,
                      label: _maskFeather.toStringAsFixed(1),
                      onChanged: (v) => setState(() => _maskFeather = v),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Threshold: ${_maskThreshold.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Slider(
                      value: _maskThreshold,
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      label: _maskThreshold.toStringAsFixed(2),
                      onChanged: (v) async {
                        setState(() => _maskThreshold = v);
                        if (_mask != null) {
                          _alphaMaskImage?.dispose();
                          final alphaMask = await _buildAlphaMaskImage(
                            _mask!,
                            threshold: _maskThreshold,
                            softness: _maskSoftness,
                          );
                          if (!mounted) {
                            alphaMask.dispose();
                            return;
                          }
                          setState(() => _alphaMaskImage = alphaMask);
                        }
                      },
                    ),
                    Text(
                      'Softness: ${_maskSoftness.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Slider(
                      value: _maskSoftness,
                      min: 0.0,
                      max: 0.5,
                      divisions: 50,
                      label: _maskSoftness.toStringAsFixed(2),
                      onChanged: (v) async {
                        setState(() => _maskSoftness = v);
                        if (_mask != null) {
                          _alphaMaskImage?.dispose();
                          final alphaMask = await _buildAlphaMaskImage(
                            _mask!,
                            threshold: _maskThreshold,
                            softness: _maskSoftness,
                          );
                          if (!mounted) {
                            alphaMask.dispose();
                            return;
                          }
                          setState(() => _alphaMaskImage = alphaMask);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // --- Превью занимает всё оставшееся место и вписывается в экран ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final imgW = _rawImage!.width.toDouble();
                      final imgH = _rawImage!.height.toDouble();
                      final ratio = imgW / imgH;

                      final maxW = constraints.maxWidth;
                      final maxH = constraints.maxHeight;

                      double drawW = maxW;
                      double drawH = drawW / ratio;

                      if (drawH > maxH) {
                        drawH = maxH;
                        drawW = drawH * ratio;
                      }

                      return Center(
                        child: SizedBox(
                          width: drawW,
                          height: drawH,
                          child: CustomPaint(
                            painter: _BackgroundBlurPainter(
                              image: _rawImage!,
                              alphaMask: _alphaMaskImage,
                              blurAmount: _blurAmount,
                              maskFeather: _maskFeather,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // --- Инфо/ошибки внизу ---
              if (_mask != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Маска: ${_mask!.width}x${_mask!.height}'),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),

      ),
    );
  }
}

class _BackgroundBlurPainter extends CustomPainter {
  final ui.Image image;
  final ui.Image? alphaMask;
  final double blurAmount;
  final double maskFeather;

  const _BackgroundBlurPainter({
    required this.image,
    required this.alphaMask,
    required this.blurAmount,
    required this.maskFeather,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Offset.zero & size;

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    // ВАЖНО: блюр может рисоваться “за пределы”, поэтому клипаем
    canvas.save();
    canvas.clipRect(dst);

    // 1) Размытый фон (в размер превью)
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

    if (alphaMask == null) {
      canvas.restore();
      return;
    }

    // 2) Чёткий человек поверх: dstIn маска
    canvas.saveLayer(dst, Paint());

    // 2.1 оригинал
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );

    // 2.2 маска (масштабируем в dst)
    final maskSrc = Rect.fromLTWH(
      0,
      0,
      alphaMask!.width.toDouble(),
      alphaMask!.height.toDouble(),
    );

    canvas.drawImageRect(
      alphaMask!,
      maskSrc,
      dst,
      Paint()
        ..isAntiAlias = true
        ..blendMode = ui.BlendMode.dstIn
        ..imageFilter = (maskFeather > 0)
            ? ui.ImageFilter.blur(sigmaX: maskFeather, sigmaY: maskFeather)
            : null,
    );

    canvas.restore(); // слой с человеком
    canvas.restore(); // clipRect
  }

  @override
  bool shouldRepaint(covariant _BackgroundBlurPainter old) {
    return old.image != image ||
        old.alphaMask != alphaMask ||
        old.blurAmount != blurAmount ||
        old.maskFeather != maskFeather;
  }
}

