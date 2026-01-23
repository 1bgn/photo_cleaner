class LocalGalleryItem {
  const LocalGalleryItem({
    required this.id,
    required this.path,
    required this.createdAtMillis,
  });

  final String id;
  final String path;
  final int createdAtMillis;
}
