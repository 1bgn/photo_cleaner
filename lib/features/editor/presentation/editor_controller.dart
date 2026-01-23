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

import '../../gallery/domain/local_gallery_service.dart';
import '../application/inpaint_service.dart';
import '../application/media_save_service.dart';
import 'mask/brush_models.dart';

@injectable
class EditorController {
  EditorController(
      this._picker,
      this._inpaintService,
      this._segmenter,
      this._mediaSaveService, this._localGalleryService,
      );

  final ImagePicker _picker;
  final InpaintService _inpaintService;
  final SelfieSegmenter _segmenter;
  final MediaSaveService _mediaSaveService;
  final LocalGalleryService _localGalleryService;
  final imageFile = signal<File?>(null);
  final rawImage = signal<ui.Image?>(null);
  final mask = signal<SegmentationMask?>(null);
  final alphaMaskImage = signal<ui.Image?>(null);

  final selectionMode = signal<bool>(false);
  final isProcessing = signal<bool>(false);
  final errorMessage = signal<String?>(null);

  final blurAmount = signal<double>(0.0);
  final maskFeather = signal<double>(2.0);
  final maskThreshold = signal<double>(0.5);
  final maskSoftness = signal<double>(0.15);

  final brushEnabled = signal<bool>(false);
  final brushMode = signal<BrushMode>(BrushMode.add);
  final brushSize = signal<double>(28.0);

  final paintTick = signal<int>(0);
  final userMaskImage = signal<ui.Image?>(null);

  final List<BrushStroke> _strokes = [];
  BrushStroke? _active;

  Timer? _debounce;
  int _maskBuildToken = 0;
  int _inpaintToken = 0;
  bool _disposed = false;

  List<BrushStroke> get strokes => _strokes;
  BrushStroke? get activeStroke => _active;

  bool get canDraw => selectionMode.value && brushEnabled.value && !isProcessing.value && !_disposed;

  Future<void> saveToLocalGallery({bool asDisplayed = true}) async {
    final src = rawImage.value;
    if (src == null) throw StateError('Нет изображения');

    ui.Image imgToSave;

    if (asDisplayed) {
      imgToSave = await _renderResultImage(
        src: src,
        alphaMask: alphaMaskImage.value,
        blurAmount: blurAmount.value,
        maskFeather: maskFeather.value,
      );
    } else {
      imgToSave = src;
    }

    try {
      final bd = await imgToSave.toByteData(format: ui.ImageByteFormat.png);
      if (asDisplayed) imgToSave.dispose();
      if (bd == null) throw Exception('Не удалось получить байты');

      await _localGalleryService.savePng(bd.buffer.asUint8List());
    } catch (_) {
      if (asDisplayed) {
        try { imgToSave.dispose(); } catch (_) {}
      }
      rethrow;
    }
  }


  void toggleSelectionMode([bool? v]) {
    final next = v ?? !selectionMode.value;
    selectionMode.value = next;
    brushEnabled.value = next && !isProcessing.value;

    if (!next) {
      _active = null;
      paintTick.value++;
    }
  }

  void setBrushMode(BrushMode mode) => brushMode.value = mode;

  void clearUserMask() {
    _strokes.clear();
    _active = null;
    _disposeMaskSafely(userMaskImage.value);
    userMaskImage.value = null;
    paintTick.value++;
  }

  void beginStroke(ui.Offset pImageSpace) {
    if (!canDraw) return;

    final s = BrushStroke(
      mode: brushMode.value,
      size: brushSize.value,
    );
    s.points.add(pImageSpace);
    _active = s;
    paintTick.value++;
  }

  void appendPoint(ui.Offset pImageSpace) {
    if (!canDraw) return;

    final a = _active;
    if (a == null) return;

    if (a.points.isNotEmpty) {
      final last = a.points.last;
      if ((last - pImageSpace).distance < 0.8) return;
    }

    a.points.add(pImageSpace);
    paintTick.value++;
  }

  void endStroke({required ui.Image baseImage}) {
    if (!canDraw) return;

    final a = _active;
    if (a == null) return;

    _active = null;
    if (a.points.length >= 2) _strokes.add(a);
    paintTick.value++;

    if (!_hasAnyAddStroke) return;

    final token = ++_inpaintToken;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () async {
      await _runInpaint(token: token, baseImage: baseImage);
    });
  }

  Future<void> _runInpaint({required int token, required ui.Image baseImage}) async {
    try {
      if (_disposed || token != _inpaintToken) return;

      brushEnabled.value = false;
      isProcessing.value = true;

      final m = await _renderMaskImage(width: baseImage.width, height: baseImage.height);
      if (_disposed || token != _inpaintToken) {
        m.dispose();
        return;
      }
      _setMaskSafely(m);

      final maskBytes = await exportUserMaskPngBytes();
      if (maskBytes == null) return;

      final imageBytes = await _exportCurrentImagePngBytes();
      final resultBytes = await _inpaintService.inpaint(
        imageBytes: imageBytes,
        maskBytes: maskBytes,
      );

      if (_disposed || token != _inpaintToken) return;

      final decoded = await _decodeUiImage(resultBytes);
      if (_disposed || token != _inpaintToken) {
        decoded.dispose();
        return;
      }
      _setRawImageSafely(decoded);

      final newFile = await _writeTempResult(resultBytes);
      imageFile.value = newFile;

      clearUserMask();
    } catch (e) {
      errorMessage.value = 'Inpaint error: $e';
    } finally {
      if (_disposed) return;

      isProcessing.value = false;
      if (selectionMode.value) {
        brushEnabled.value = true;
      }
    }
  }

  bool get _hasAnyAddStroke => _strokes.any((s) => s.mode == BrushMode.add);

  Future<void> removeBackgroundLocally() async {
    final src = rawImage.value;
    final personMask = alphaMaskImage.value;

    if (src == null) {
      errorMessage.value = 'Нет изображения';
      return;
    }
    if (personMask == null) {
      errorMessage.value = 'Нет маски человека';
      return;
    }

    try {
      brushEnabled.value = false;
      isProcessing.value = true;

      final out = await _renderPersonCutout(
        src: src,
        alphaMask: personMask,
        feather: maskFeather.value,
      );

      if (_disposed) {
        out.dispose();
        return;
      }

      _setRawImageSafely(out);

      final bytes = await out.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        final f = await _writeTempResult(bytes.buffer.asUint8List());
        imageFile.value = f;
      }

      clearUserMask();
      selectionMode.value = false;
      brushEnabled.value = false;
    } catch (e) {
      errorMessage.value = 'Ошибка удаления фона: $e';
    } finally {
      if (!_disposed) isProcessing.value = false;
    }
  }

  Future<String?> saveFinalImageToGallery({String? album}) async {
    final src = rawImage.value;
    if (src == null) throw StateError('Нет изображения');

    final rendered = await _renderResultImage(
      src: src,
      alphaMask: alphaMaskImage.value,
      blurAmount: blurAmount.value,
      maskFeather: maskFeather.value,
    );

    final bd = await rendered.toByteData(format: ui.ImageByteFormat.png);
    rendered.dispose();

    if (bd == null) throw Exception('Не удалось получить байты');

    return _mediaSaveService.savePngToGallery(
      pngBytes: bd.buffer.asUint8List(),
      album: album,
    );
  }

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
      if (!_disposed) isProcessing.value = false;
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
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 120), () async {
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

  void clearAll() {
    _debounce?.cancel();
    _maskBuildToken++;
    _inpaintToken++;

    imageFile.value = null;
    mask.value = null;
    errorMessage.value = null;

    final oldRaw = rawImage.value;
    final oldAlpha = alphaMaskImage.value;
    final oldUserMask = userMaskImage.value;

    rawImage.value = null;
    alphaMaskImage.value = null;
    userMaskImage.value = null;

    if (oldRaw != null) _disposeImageAfterFrame(oldRaw);
    if (oldAlpha != null) _disposeImageAfterFrame(oldAlpha);
    if (oldUserMask != null) _disposeMaskSafely(oldUserMask);

    _strokes.clear();
    _active = null;
    paintTick.value++;
  }

  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _maskBuildToken++;
    _inpaintToken++;

    final r = rawImage.value;
    final a = alphaMaskImage.value;
    final u = userMaskImage.value;

    rawImage.value = null;
    alphaMaskImage.value = null;
    userMaskImage.value = null;

    if (r != null) _disposeImageAfterFrame(r);
    if (a != null) _disposeImageAfterFrame(a);
    if (u != null) _disposeMaskSafely(u);

    _segmenter.close();
  }

  Future<Uint8List?> exportUserMaskPngBytes() async {
    final img = userMaskImage.value;
    if (img == null) return null;
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd?.buffer.asUint8List();
  }

  Future<Uint8List> _exportCurrentImagePngBytes() async {
    final img = rawImage.value;
    if (img == null) throw StateError('No image');
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bd == null) throw Exception('Failed to encode image');
    return bd.buffer.asUint8List();
  }

  Future<File> _writeTempResult(Uint8List bytes) async {
    final dir = await Directory.systemTemp.createTemp('edited_');
    final file = File('${dir.path}/result.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<ui.Image> _renderMaskImage({
    required int width,
    required int height,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final rect = ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());

    canvas.drawRect(rect, ui.Paint()..color = const ui.Color(0xFF000000));

    void drawStroke(BrushStroke s) {
      if (s.points.length < 2) return;

      final paint = ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = s.size
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round
        ..isAntiAlias = true
        ..blendMode = ui.BlendMode.srcOver;

      paint.color = (s.mode == BrushMode.add)
          ? const ui.Color(0xFFFFFFFF)
          : const ui.Color(0xFF000000);

      final path = ui.Path()..moveTo(s.points[0].dx, s.points[0].dy);
      for (int i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final s in _strokes) {
      drawStroke(s);
    }
    if (_active != null) drawStroke(_active!);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    picture.dispose();
    return img;
  }

  Future<ui.Image> _renderPersonCutout({
    required ui.Image src,
    required ui.Image alphaMask,
    required double feather,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final rect = ui.Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble());

    canvas.saveLayer(rect, ui.Paint());
    canvas.drawImage(src, ui.Offset.zero, ui.Paint()..filterQuality = ui.FilterQuality.high);

    final maskRect = ui.Rect.fromLTWH(
      0,
      0,
      alphaMask.width.toDouble(),
      alphaMask.height.toDouble(),
    );

    canvas.drawImageRect(
      alphaMask,
      maskRect,
      rect,
      ui.Paint()
        ..isAntiAlias = true
        ..blendMode = ui.BlendMode.dstIn
        ..imageFilter = (feather > 0)
            ? ui.ImageFilter.blur(sigmaX: feather, sigmaY: feather)
            : null,
    );

    canvas.restore();

    final pic = recorder.endRecording();
    final img = await pic.toImage(src.width, src.height);
    pic.dispose();
    return img;
  }

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

    canvas.drawImage(
      src,
      Offset.zero,
      Paint()
        ..filterQuality = FilterQuality.high
        ..imageFilter = ui.ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
    );

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

  void _disposeImageAfterFrame(ui.Image img) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        img.dispose();
      } catch (_) {}
    });
  }

  void _disposeMaskSafely(ui.Image? img) {
    if (img == null) return;
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

  void _setMaskSafely(ui.Image newMask) {
    final old = userMaskImage.value;
    userMaskImage.value = newMask;
    if (old != null && old != newMask) _disposeMaskSafely(old);
    paintTick.value++;
  }
}
