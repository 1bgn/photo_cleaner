import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/local_gallery_item.dart';
import '../domain/local_gallery_service.dart';

@LazySingleton(as: LocalGalleryService)
class LocalGalleryServiceImpl implements LocalGalleryService {
  static const _dirName = 'editor_gallery';

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/$_dirName');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  String _makeId() => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  Future<LocalGalleryItem> savePng(Uint8List pngBytes) async {
    final d = await _dir();
    final id = _makeId();
    final file = File('${d.path}/$id.png');
    await file.writeAsBytes(pngBytes, flush: true);

    return LocalGalleryItem(
      id: id,
      path: file.path,
      createdAtMillis: int.parse(id),
    );
  }

  @override
  Future<List<LocalGalleryItem>> list() async {
    final d = await _dir();
    final files = d
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.png'))
        .toList();

    files.sort((a, b) => b.path.compareTo(a.path)); // по имени = по времени

    return files.map((f) {
      final name = f.uri.pathSegments.last;
      final id = name.replaceAll('.png', '');
      final ts = int.tryParse(id) ?? 0;
      return LocalGalleryItem(id: id, path: f.path, createdAtMillis: ts);
    }).toList();
  }

  @override
  Future<void> delete(String id) async {
    final d = await _dir();
    final file = File('${d.path}/$id.png');
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> clear() async {
    final d = await _dir();
    if (!await d.exists()) return;
    final entries = d.listSync();
    for (final e in entries) {
      try {
        await e.delete(recursive: true);
      } catch (_) {}
    }
  }
}
