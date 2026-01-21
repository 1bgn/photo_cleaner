import 'dart:ui';

enum BrushMode { add, erase }

class BrushStroke {
  BrushStroke({
    required this.mode,
    required this.size,
  });

  final BrushMode mode;
  final double size;
  final List<Offset> points = [];
}
