import 'package:flutter/material.dart';

import '../tokens/v_typography.dart';

/// Text primitive bound to [VTypography] tokens.
class VText extends StatelessWidget {
  const VText(
    this.text, {
    super.key,
    this.style = VTypography.bodyMd,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  const VText.headingLg(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : style = VTypography.headingLg;

  const VText.headingMd(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : style = VTypography.headingMd;

  const VText.headingSm(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : style = VTypography.headingSm;

  const VText.bodyLg(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : style = VTypography.bodyLg;

  const VText.bodySm(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : style = VTypography.bodySm;

  const VText.caption(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : style = VTypography.caption;

  final String text;
  final TextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: color != null ? style.copyWith(color: color) : style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
