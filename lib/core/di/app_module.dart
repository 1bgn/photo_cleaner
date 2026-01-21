import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';


import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

import '../network/dio_factory.dart';
import '../network/retrofit_clients.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  ImagePicker get imagePicker => ImagePicker();


  @factoryMethod
  SelfieSegmenter provideSelfieSegmenter() {
    return SelfieSegmenter(
      mode: SegmenterMode.single,
      enableRawSizeMask: true,
    );
  }
  @lazySingleton
  DioFactory get dioFactory => DioFactory();

  @lazySingleton
  CleanerInpaintClient cleanerInpaintClient(DioFactory factory) {
    final dio = factory.create(
      baseUrl: 'https://b7am-cleaner.hf.space',
      responseType: ResponseType.bytes,
      receiveTimeout: const Duration(seconds: 180),
    );
    return CleanerInpaintClient(dio);
  }
}
