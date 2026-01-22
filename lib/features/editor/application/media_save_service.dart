abstract class MediaSaveService {
  /// Возвращает путь/идентификатор, если получится (можно null)
  Future<String?> savePngToGallery({
    required List<int> pngBytes,
    String? album,
    String? fileNameNoExt,
  });
}
