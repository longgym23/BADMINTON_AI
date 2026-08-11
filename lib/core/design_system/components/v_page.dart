import 'package:flutter/material.dart';
import '../tokens/v_colors.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';

/// Standardized screen scaffold primitive bound to KLOO surfaces.
class VPage extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? primaryAction;
  final List<Widget>? actions;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool useSafeArea;

  const VPage({
    super.key,
    this.title,
    this.subtitle,
    this.primaryAction,
    this.actions,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.onRefresh,
    this.padding = const EdgeInsets.all(VSpacing.lg),
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding,
      child: body,
    );

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: VColors.brandPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: content,
        ),
      );
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    PreferredSizeWidget? effectiveAppBar = appBar;
    if (effectiveAppBar == null && title != null) {
      effectiveAppBar = AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title!, style: VTypography.headingLg),
            if (subtitle != null)
              Text(
                subtitle!,
                style: VTypography.bodySm.copyWith(color: VColors.textSubdued),
              ),
          ],
        ),
        backgroundColor: VColors.surface,
        foregroundColor: VColors.textPrimary,
        elevation: 0.5,
        actions: [
          if (actions != null) ...actions!,
          if (primaryAction != null)
            Padding(
              padding: const EdgeInsets.only(right: VSpacing.md),
              child: primaryAction!,
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? VColors.background,
      appBar: effectiveAppBar,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
    );
  }
}
