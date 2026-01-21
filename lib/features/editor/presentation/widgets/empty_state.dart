import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.errorText});

  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Выберите фото'),
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
