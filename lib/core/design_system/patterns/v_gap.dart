import 'package:flutter/material.dart';
import '../tokens/v_spacing.dart';

/// Layout spacing primitive — use instead of raw [SizedBox].
class VGap extends StatelessWidget {
  final double size;

  const VGap(this.size, {super.key});

  const VGap.xs({super.key}) : size = VSpacing.xs;
  const VGap.sm({super.key}) : size = VSpacing.sm;
  const VGap.md({super.key}) : size = VSpacing.md;
  const VGap.lg({super.key}) : size = VSpacing.lg;
  const VGap.xl({super.key}) : size = VSpacing.xl;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}
