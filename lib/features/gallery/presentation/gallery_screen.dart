import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:photo_cleaner/core/event_keys/event_keys.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/di/di.dart';
import '../domain/models/local_gallery_item.dart';
import 'gallery_controller.dart';
import 'viewer_screen.dart';
import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late final GalleryController c;

  @override
  void initState() {
    super.initState();
    c = getIt<GalleryController>();
    c.load();
    c.initBanner();
    AppMetrica.reportEvent(EventKeys.openGalleryEvent);
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final loading = c.isLoading.watch(context);
      final items = c.items.watch(context);
      final err = c.error.watch(context);

      return Scaffold(
        appBar: AppBar(
          title: Text('localGallery'.tr()),
          actions: [
            IconButton(
              tooltip: 'clear'.tr(),
              onPressed: items.isEmpty
                  ? null
                  : () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('clearGallery'.tr()),
                    content: Text('deleteAllSavedImages'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('cancel'.tr()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('delete'.tr()),
                      ),
                    ],
                  ),
                );
                if (ok == true) await c.clearAll();
              },
              icon: const Icon(Icons.delete_sweep),
            ),
          ],
        ),
        body: Column(
          children: [
            if (c.bannerAd.value != null)
              SizedBox(
                height: c.bannerAd.value!.size.height.toDouble(),
                width: c.bannerAd.value!.size.width.toDouble(),
                child: AdWidget(ad: c.bannerAd.value!),
              ),
            if (loading) const LinearProgressIndicator(),
            if (err != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(err, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text('hereIsEmpty'.tr()))
                  : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _Thumb(
                  item: items[i],
                  onOpen: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ViewerScreen(item: items[i])),
                    );
                    await c.load();
                  },
                  onDelete: () => c.deleteItem(items[i]),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.item,
    required this.onOpen,
    required this.onDelete,
  });

  final LocalGalleryItem item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final file = File(item.path);

    return InkWell(
      onTap: onOpen,
      onLongPress: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('delete'.tr()),
            content: Text('deleteFromLocalGallery'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('delete'.tr()),
              ),
            ],
          ),
        );
        if (ok == true) onDelete();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0x22000000),
            child: Center(child: Icon(Icons.broken_image)),
          ),
        ),
      ),
    );
  }
}
