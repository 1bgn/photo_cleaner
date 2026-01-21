import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/di/di.dart';
import 'editor_controller.dart';
import 'widgets/action_fabs.dart';
import 'widgets/blur_strength_slider.dart';
import 'widgets/empty_state.dart';
import 'widgets/image_preview.dart';
import 'widgets/mask_settings_sheet.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController c;

  @override
  void initState() {
    super.initState();
    c = getIt<EditorController>();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (c.rawImage.value == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить результат'),
        content: const Text('Сохранить изображение в Галерею?'),
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
      final savedPath = await c.saveFinalImageToGallery();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Сохранено: ${savedPath ?? "успешно"}')),
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

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MaskSettingsSheet(controller: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final raw = c.rawImage.watch(context);
      final err = c.errorMessage.watch(context);
      final busy = c.isProcessing.watch(context);
      final selection = c.selectionMode.watch(context);

      return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: 'Настройки маски',
              onPressed: (raw == null || busy) ? null : _openMaskSettings,
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        floatingActionButton: ActionFabs(
          controller: c,
          onSave: _onSave,
        ),
        body: Center(
          child: (raw == null)
              ? EmptyState(errorText: err)
              : SafeArea(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Режим выделения объектов'),
                  value: selection,
                  onChanged: busy ? null : (v) => c.toggleSelectionMode(v),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: FilledButton.icon(
                    onPressed: (busy || c.alphaMaskImage.value == null)
                        ? null
                        : c.removeBackgroundLocally,
                    icon: const Icon(Icons.layers_clear),
                    label: const Text('Удалить весь фон (локально)'),
                  ),
                ),
                BlurStrengthSlider(controller: c),
                Expanded(child: ImagePreview(controller: c)),
                if (err != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      err,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
