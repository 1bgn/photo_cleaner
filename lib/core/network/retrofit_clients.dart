import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'retrofit_clients.g.dart';

@RestApi(baseUrl: 'https://b7am-cleaner.hf.space')
abstract class CleanerInpaintClient {
  factory CleanerInpaintClient(Dio dio, {String baseUrl}) = _CleanerInpaintClient;

  @MultiPart()
  @POST('/inpaint')
  Future<HttpResponse<List<int>>> inpaint(
      @Part(name: 'image') MultipartFile image,
      @Part(name: 'mask') MultipartFile mask,
      );
}
