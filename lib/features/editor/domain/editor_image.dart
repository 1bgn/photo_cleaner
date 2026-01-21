// lib/features/editor/domain/editor_image.dart
import 'dart:typed_data';

class EditorImage {
  final Uint8List bytes;
  final String fileName;

  const EditorImage({
    required this.bytes,
    required this.fileName,
  });
}
