import 'package:flutter/material.dart';
import 'package:badminton_ai/utils/app_colors.dart';

class CustomGradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final double elevation;
  final IconThemeData? iconTheme;
  final bool automaticallyImplyLeading;
  final double? titleSpacing;

  const CustomGradientAppBar({
    Key? key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.bottom,
    this.elevation = 0.0,
    this.iconTheme,
    this.automaticallyImplyLeading = true,
    this.titleSpacing, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      bottom: bottom,
      elevation: elevation,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: titleSpacing,
      backgroundColor: Colors.transparent, // Trong suốt để thấy Gradient bên dưới
      foregroundColor: Colors.white, // Text nổi lên sẽ mang màu trắng
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: iconTheme ?? const IconThemeData(color: Colors.white),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [ AppColors.brandOrangeDark,
                    AppColors.brandOrangeLight,],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
