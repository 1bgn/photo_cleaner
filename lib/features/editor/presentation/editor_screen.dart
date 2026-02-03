import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/di/di.dart';
import '../../gallery/presentation/gallery_screen.dart';
import '../../monetization/presentation/main_paywall_sheet.dart';
import '../../monetization/presentation/monetization_controller.dart';
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

    // paywall for iOS
    if (Platform.isIOS) {
      final m = getIt<MonetizationController>();
      await m.init();

      if (!m.hasPremium.value) {
        await MainPaywallSheet.show(context);
        await m.refreshStatus();
        if (!m.hasPremium.value) return;
      }
    }

    final choice = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('save'.tr()),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 1),
            child: ListTile(
              leading: const Icon(Icons.folder),
              title: Text('toTheLocalGallery'.tr()),
              subtitle: Text('savedInsideApp'.tr()),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 2),
            child: ListTile(
              leading: const Icon(Icons.photo),
              title: Text('toDeviceGallery'.tr()),
              subtitle: Text('photosOrGallery'.tr()),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 3),
            child: ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('openLocalGallery'.tr()),
            ),
          ),
          const Divider(height: 1),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('cancel'.tr()),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (choice == null || choice == 0) return;

    if (choice == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GalleryScreen()),
      );
      return;
    }

    if (c.isProcessing.value) return;

    try {
      c.isProcessing.value = true;

      if (choice == 1) {
        await c.saveToLocalGallery(asDisplayed: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('savedToLocalGallery'.tr())),
        );
        return;
      }

      if (choice == 2) {
        final savedPath = await c.saveFinalImageToGallery();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${"saved".tr()}: ${savedPath ?? "successfully".tr()}',
            ),
          ),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${"saveError".tr()}: $e')),
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
              key: const Key("1"),
              tooltip: 'localGallery'.tr(),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GalleryScreen()),
                );
              },
              icon: const Icon(Icons.photo_library_outlined),
            ),
            IconButton(
              tooltip: 'maskSettings'.tr(),
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
                  title: Text('objectSelectionMode'.tr()),
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
                    label: Text('removeAllBackgroundLocal'.tr()),
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
