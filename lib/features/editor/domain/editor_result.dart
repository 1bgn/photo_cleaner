// lib/features/editor/domain/editor_result.dart
import 'dart:typed_data';

class EditorResult {
  final Uint8List bytes;
  final String mime; // e.g. image/png

  const EditorResult({
    required this.bytes,
    required this.mime,
  });
}
