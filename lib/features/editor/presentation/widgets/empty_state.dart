import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.errorText});

  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
         Text('chosePhoto').tr(),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
