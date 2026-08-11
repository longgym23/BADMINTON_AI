import 'package:flutter/material.dart';
import '../tokens/v_spacing.dart';

/// Layout spacing primitive — use instead of raw [SizedBox].
class VGap extends StatelessWidget {
  final double size;

  const VGap(this.size, {super.key});

  static const VGap xs = VGap(VSpacing.xs);
  static const VGap sm = VGap(VSpacing.sm);
  static const VGap md = VGap(VSpacing.md);
  static const VGap lg = VGap(VSpacing.lg);
  static const VGap xl = VGap(VSpacing.xl);

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}
