// pick_image_uc.dart
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import '../../domain/image_picker_port.dart';

@injectable
class PickImageUc {
  PickImageUc(this._picker);

  final ImagePickerPort _picker;

  Future<Uint8List?> call() => _picker.pickImageBytes();
}
