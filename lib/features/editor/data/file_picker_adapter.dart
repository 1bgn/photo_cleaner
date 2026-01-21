// file_picker_adapter.dart
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import '../domain/image_picker_port.dart';

@LazySingleton(as: ImagePickerPort)
class FilePickerAdapter implements ImagePickerPort {
  @override
  Future<Uint8List?> pickImageBytes() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    return image?.readAsBytes();
  }
}
