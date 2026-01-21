import 'dart:typed_data';

abstract interface class AutoMaskPort {
  Future<Uint8List> replaceBackgroundAutoMask({
    required Uint8List original,
    required String prompt,
  });
}