import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../editor_controller.dart';

class ActionFabs extends StatelessWidget {
  const ActionFabs({
    super.key,
    required this.controller,
    required this.onSave,
  });

  final EditorController controller;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Watch.builder(
      builder: (_) {
        final hasImage = controller.rawImage.value != null;
        final isProcessing = controller.isProcessing.value;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (hasImage)
              FloatingActionButton.small(
                heroTag: 'fab_save',
                onPressed: isProcessing ? null : onSave,
                backgroundColor: Colors.green,
                child: const Icon(Icons.save, size: 20),
              ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'fab_pic',

              onPressed: isProcessing ? null : controller.pickAndProcessImage,
              backgroundColor: isProcessing ? Colors.grey : Colors.blue,
              child: isProcessing
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Icon(Icons.photo),
            ),
          ],
        );
      },
    );
  }
}
