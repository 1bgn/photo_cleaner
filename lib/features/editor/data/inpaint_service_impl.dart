import 'dart:convert';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:photo_cleaner/features/editor/domain/repository/media_repository.dart';

import '../application/inpaint_service.dart';

@LazySingleton(as: InpaintService)
class InpaintServiceImpl implements InpaintService {
  InpaintServiceImpl(this.mediaRepository);

  final MediaRepository mediaRepository;

  @override
  Future<Uint8List> inpaint({
    required Uint8List imageBytes,
    required Uint8List maskBytes,
  }) async {
    return mediaRepository.inpaint(
        imageBytes: imageBytes, maskBytes: maskBytes);
  }
}
