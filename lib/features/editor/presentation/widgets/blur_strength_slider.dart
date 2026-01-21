import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../editor_controller.dart';

class BlurStrengthSlider extends StatelessWidget {
  const BlurStrengthSlider({super.key, required this.controller});
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return Watch((context,) {
      final blur = controller.blurAmount.value;

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Сила размытия: ${blur.toStringAsFixed(1)}'),
            Slider(
              value: blur,
              min: 0,
              max: 50,
              divisions: 500,
              label: blur.toStringAsFixed(1),
              onChanged: (v) => controller.blurAmount.value = v,
            ),
          ],
        ),
      );
    });
  }
}
