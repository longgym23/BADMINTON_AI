import 'package:flutter/material.dart';

import '../patterns/v_gap.dart';
import '../tokens/v_colors.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';

/// Surface card primitive bound to KLOO design tokens.
class VCard extends StatelessWidget {
  final String? title;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Border? border;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const VCard({
    super.key,
    this.title,
    this.action,
    required this.child,
    this.padding = const EdgeInsets.all(VSpacing.lg),
    this.margin,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? VRadius.borderLg;
    final effectiveBorder = border ?? Border.all(color: VColors.borderDefault);
    final effectiveBg = backgroundColor ?? VColors.surfaceCard;

    Widget cardChild = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: effectiveBorder,
        boxShadow: boxShadow,
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || action != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null)
                  Text(title!, style: VTypography.headingMd),
                if (action != null) action!,
              ],
            ),
          if (title != null || action != null) const VGap.md(),
          child,
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius is BorderRadius ? effectiveRadius : VRadius.borderLg,
        child: cardChild,
      );
    }

    return cardChild;
  }
}
