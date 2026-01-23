import 'dart:io';

import 'package:flutter/material.dart';

import '../domain/local_gallery_item.dart';

class ViewerScreen extends StatelessWidget {
  const ViewerScreen({super.key, required this.item});

  final LocalGalleryItem item;

  @override
  Widget build(BuildContext context) {
    final file = File(item.path);

    return Scaffold(
      appBar: AppBar(title: const Text('Просмотр')),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(file),
        ),
      ),
    );
  }
}
