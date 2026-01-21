// lib/features/editor/domain/imagen_auto_mask_repository.dart
import 'editor_image.dart';
import 'editor_result.dart';

abstract class ImagenAutoMaskRepository {
  Future<EditorResult> replaceBackgroundAutoMask({
    required EditorImage input,
    required String prompt,
  });
}
