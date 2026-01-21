import 'dart:io';
import 'package:gal/gal.dart';
import 'package:injectable/injectable.dart';

import '../domain/media_save_service.dart';

@LazySingleton(as: MediaSaveService)
class MediaSaveServiceImpl implements MediaSaveService {
  @override
  Future<String?> savePngToGallery({
    required List<int> pngBytes,
    String? album,
    String? fileNameNoExt,
  }) async {
    // 1) permission
    final hasAccess = await Gal.hasAccess(toAlbum: album != null);
    if (!hasAccess) {
      await Gal.requestAccess(toAlbum: album != null);
    }

    // 2) пишем во временный файл (самый надёжный вариант)
    final name = fileNameNoExt ?? 'edited_${DateTime.now().millisecondsSinceEpoch}';
    final tmp = await Directory.systemTemp.createTemp('save_');
    final file = File('${tmp.path}/$name.png');
    await file.writeAsBytes(pngBytes, flush: true);

    // 3) сохраняем в Photos/Gallery
    // Gal.putImage поддерживает сохранение в альбом (album) :contentReference[oaicite:4]{index=4}
    await Gal.putImage(file.path, album: album);

    return file.path; // это путь temp-файла, как “идентификатор” (в галерее будет своя копия)
  }
}
