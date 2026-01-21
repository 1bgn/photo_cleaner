// image_picker_port.dart
import 'dart:typed_data';

abstract interface class ImagePickerPort {
  Future<Uint8List?> pickImageBytes();
}
