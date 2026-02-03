import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../editor_controller.dart';

class MaskSettingsSheet extends StatefulWidget {
  const MaskSettingsSheet({super.key, required this.controller});

  final EditorController controller;

  @override
  State<MaskSettingsSheet> createState() => _MaskSettingsSheetState();
}

class _MaskSettingsSheetState extends State<MaskSettingsSheet> {
  late double tempFeather;
  late double tempThreshold;
  late double tempSoftness;

  @override
  void initState() {
    super.initState();
    tempFeather = widget.controller.maskFeather.value;
    tempThreshold = widget.controller.maskThreshold.value;
    tempSoftness = widget.controller.maskSoftness.value;
  }

  @override
  Widget build(BuildContext context) {
    Widget sliderRow(
        String titleKey,
        double value,
        String label,
        double min,
        double max,
        int divisions,
        ValueChanged<double> onChanged,
        ) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${titleKey.tr()}: $label'),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              onChanged: onChanged,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          Text(
            'maskSettings'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          sliderRow(
            'maskFeather',
            tempFeather,
            tempFeather.toStringAsFixed(1),
            0.0,
            12.0,
            120,
                (v) => setState(() => tempFeather = v),
          ),
          sliderRow(
            'maskThreshold',
            tempThreshold,
            tempThreshold.toStringAsFixed(2),
            0.0,
            1.0,
            100,
                (v) => setState(() => tempThreshold = v),
          ),
          sliderRow(
            'maskSoftness',
            tempSoftness,
            tempSoftness.toStringAsFixed(2),
            0.0,
            0.5,
            50,
                (v) => setState(() => tempSoftness = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr()),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  widget.controller.applyMaskSettings(
                    feather: tempFeather,
                    threshold: tempThreshold,
                    softness: tempSoftness,
                  );
                  Navigator.pop(context, true);
                },
                child: Text('apply'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
