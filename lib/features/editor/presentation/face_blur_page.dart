import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/di/di.dart';
import 'editor_controller.dart';
import 'widgets/action_fabs.dart';
import 'widgets/blur_strength_slider.dart';
import 'widgets/empty_state.dart';
import 'widgets/image_preview.dart';
import 'widgets/mask_settings_sheet.dart';

class BackgroundBlurPage extends StatefulWidget {
  const BackgroundBlurPage({super.key});

  @override
  State<BackgroundBlurPage> createState() => _BackgroundBlurPageState();
}

class _BackgroundBlurPageState extends State<BackgroundBlurPage> {
  late final BackgroundBlurController c;

  @override
  void initState() {
    super.initState();
    c = getIt<BackgroundBlurController>();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final hasImage = c.rawImage.value != null;
    if (!hasImage) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить результат'),
        content: const Text('Хотите сохранить обработанное изображение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      c.isProcessing.value = true;
      final file = await c.renderAndSaveToTempPng();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Сохранено: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    } finally {
      c.isProcessing.value = false;
    }
  }

  Future<void> _openMaskSettings() async {
    if (!mounted) return;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MaskSettingsSheet(controller: c),
    );

    if (applied == true) {
      // MaskSettingsSheet сам применяет настройки в controller.
      // Здесь ничего не делаем.
    }
  }

  @override
  Widget build(BuildContext context) {
    // watch() заставит перестроить только те места, где он вызван
    final raw = c.rawImage.watch(context);
    final isProcessing = c.isProcessing.watch(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Фон блюр (Selfie Seg)'),
        actions: [
          IconButton(
            tooltip: 'Настройки маски',
            onPressed: (raw == null) ? null : _openMaskSettings,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      floatingActionButton: ActionFabs(
        controller: c,
        onSave: _onSave,
      ),
      body: Watch(
         (context) {
          return Center(
            child: (raw == null)
                ? EmptyState(errorText: c.errorMessage.watch(context))
                : SafeArea(
              child: Column(
                children: [
                  BlurStrengthSlider(controller: c),
                  Expanded(child: ImagePreview(controller: c)),
                  Watch.builder(
                    builder: (context) {
                      final m = c.mask.value;
                      final err = c.errorMessage.value;

                      return Column(
                        children: [
                          if (m != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('Маска: ${m.width}x${m.height}'),
                            ),
                          if (err != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                err,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
