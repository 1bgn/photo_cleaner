import 'package:injectable/injectable.dart';
import '../../features/editor/data/firebase_ai_auto_mask_adapter.dart';

import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  ImagePicker get imagePicker => ImagePicker();

  /// Важно: сегментер лучше как factory, чтобы каждый контроллер
  /// владел своим инстансом и корректно вызывал close().
  @factoryMethod
  SelfieSegmenter provideSelfieSegmenter() {
    return SelfieSegmenter(
      mode: SegmenterMode.single,
      enableRawSizeMask: true,
    );
  }
}
