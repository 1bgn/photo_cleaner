import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:injectable/injectable.dart';
import 'package:signals/signals.dart';

import '../domain/models/local_gallery_item.dart';
import '../domain/local_gallery_service.dart';

@injectable
class GalleryController {
  GalleryController(this._service);

  final LocalGalleryService _service;
  final bannerAd = signal<BannerAd?>(null);

  final items = signal<List<LocalGalleryItem>>(<LocalGalleryItem>[]);
  final isLoading = signal<bool>(false);
  final error = signal<String?>(null);

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;
      items.value = await _service.list();
    } catch (e) {
      error.value = '$e';
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> initBanner()async{
    BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
            bannerAd.value = ad as BannerAd;
        },
        onAdFailedToLoad: (ad, error) {
          print('Ошибка загрузки: ${error.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  Future<void> deleteItem(LocalGalleryItem item) async {
    try {
      await _service.delete(item.id);
      await load();
    } catch (e) {
      error.value = '$e';
    }
  }

  Future<void> clearAll() async {
    try {
      await _service.clear();
      await load();
    } catch (e) {
      error.value = '$e';
    }
  }
}
