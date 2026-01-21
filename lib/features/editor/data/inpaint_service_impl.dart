import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/network/retrofit_clients.dart';
import '../domain/inpaint_service.dart';

@LazySingleton(as: InpaintService)
class InpaintServiceImpl implements InpaintService {
  InpaintServiceImpl(this._client);

  final CleanerInpaintClient _client;

  @override
  Future<Uint8List> inpaint({
    required Uint8List imageBytes,
    required Uint8List maskBytes,
  }) async {
    try {
      final resp = await _client.inpaint(
        MultipartFile.fromBytes(imageBytes, filename: 'image.png'),
        MultipartFile.fromBytes(maskBytes, filename: 'mask.png'),
      );

      final code = resp.response.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        // Попробуем вытащить текст ошибки, даже если responseType.bytes
        final data = resp.data;
        final asText = _tryDecodeUtf8(data);
        throw Exception('HTTP $code ${resp.response.statusMessage ?? ""} ${asText ?? ""}');
      }

      return Uint8List.fromList(resp.data);
    } on DioException catch (e) {
      // если validateStatus не true — тут окажешься на 500
      final code = e.response?.statusCode;
      final data = e.response?.data;
      String? text;
      if (data is List<int>) text = _tryDecodeUtf8(data);
      if (data is String) text = data;
      throw Exception('DioException HTTP $code ${text ?? ""}');
    }
  }

  String? _tryDecodeUtf8(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }
}
