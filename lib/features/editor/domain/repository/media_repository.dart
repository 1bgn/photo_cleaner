

import 'dart:typed_data';

abstract interface class MediaRepository {
   Future<Uint8List> inpaint({
     required Uint8List imageBytes,
     required Uint8List maskBytes,
   });
 }