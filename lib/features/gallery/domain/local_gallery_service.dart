import 'dart:typed_data';
import 'models/local_gallery_item.dart';

abstract class LocalGalleryService {
  Future<LocalGalleryItem> savePng(Uint8List pngBytes);
  Future<List<LocalGalleryItem>> list();
  Future<void> delete(String id);
  Future<void> clear();
}
