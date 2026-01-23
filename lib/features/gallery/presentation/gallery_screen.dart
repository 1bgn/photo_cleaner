import 'dart:io';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/di/di.dart';
import '../domain/local_gallery_item.dart';
import 'gallery_controller.dart';
import 'viewer_screen.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final loading = c.isLoading.watch(context);
      final items = c.items.watch(context);
      final err = c.error.watch(context);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Локальная галерея'),
          actions: [
            IconButton(
              tooltip: 'Очистить',
              onPressed: items.isEmpty
                  ? null
                  : () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Очистить галерею'),
                    content: const Text('Удалить все сохранённые изображения?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
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
            if (loading) const LinearProgressIndicator(),
            if (err != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(err, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Пока пусто'))
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
            title: const Text('Удалить'),
            content: const Text('Удалить изображение из локальной галереи?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
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
