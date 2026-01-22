import 'dart:typed_data';

import 'dart:typed_data';

abstract class InpaintService {
  Future<Uint8List> inpaint({
    required Uint8List imageBytes,
    required Uint8List maskBytes,
  });
}
