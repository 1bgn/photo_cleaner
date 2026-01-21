import 'package:dio/dio.dart';

class DioFactory {
  Dio create({
    required String baseUrl,
    ResponseType responseType = ResponseType.json,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 120),
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,

        // Важно: для /inpaint лучше bytes (картинка)
        responseType: responseType,
        headers: <String, dynamic>{
          'Accept': '*/*',
        },
        validateStatus: (_) => true,
        followRedirects: true,
      ),
    );

    // Логи — по желанию (можешь убрать)
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: false,
        error: true,
      ),
    );

    return dio;
  }
}
