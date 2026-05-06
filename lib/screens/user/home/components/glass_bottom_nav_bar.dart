import 'package:easy_localization/easy_localization.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/unread_count_provider.dart';


class GlassBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GlassBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  _GlassBottomNavBarState createState() => _GlassBottomNavBarState();
}

class _GlassBottomNavBarState extends State<GlassBottomNavBar> {
  bool _isDragging = false;
  double _dragX = 0;

  int _getMappedIndex(int realIndex) {
    if (realIndex == 0) return 0;
    if (realIndex == 1) return 1;
    if (realIndex == 3) return 2; // Cộng đồng
    if (realIndex == 4) return 3; // Tài khoản
    return -1; // Chatbot (realIndex == 2)
  }

  int _getRealIndex(int mappedIndex) {
    if (mappedIndex == 0) return 0;
    if (mappedIndex == 1) return 1;
    if (mappedIndex == 2) return 3;
    if (mappedIndex == 3) return 4;
    return 0; // Default
  }

  @override
  Widget build(BuildContext context) {
    int mappedIndex = _getMappedIndex(widget.currentIndex);
    bool isMainTab = mappedIndex != -1;

    // Đọc số tin nhắn chưa đọc
    // Sử dụng _ từ provider nếu import chưa sẵn, nhưng phải listen
    // Tạm chưa có context.watch nên phải thêm import
    final unreadCount = context.watch<UnreadCountProvider>().unreadCount;

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Main Navigation Bar (Pill shaped)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                blendMode: BlendMode.srcOver,
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth / 4;

                      // Vị trí con trỏ (Indicator)
                      double indicatorLeft = 0;
                      if (_isDragging) {
                        indicatorLeft = (_dragX - itemWidth / 2).clamp(
                          0.0,
                          constraints.maxWidth - itemWidth,
                        );
                      } else {
                        indicatorLeft = mappedIndex * itemWidth;
                      }

                      // Tab đang hiển thị UI hover
                      int visualMappedIndex = mappedIndex;
                      if (_isDragging) {
                        visualMappedIndex = (_dragX / itemWidth).floor().clamp(
                          0,
                          3,
                        );
                      }
                      int visualRealIndex = isMainTab || _isDragging
                          ? _getRealIndex(visualMappedIndex)
                          : widget.currentIndex;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanDown: (details) {
                          setState(() {
                            _isDragging = true;
                            _dragX = details.localPosition.dx;
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            _dragX = details.localPosition.dx;
                          });
                        },
                        onPanEnd: (details) {
                          int finalMapped = (_dragX / itemWidth).floor().clamp(
                            0,
                            3,
                          );
                          widget.onTap(_getRealIndex(finalMapped));
                          setState(() {
                            _isDragging = false;
                          });
                        },
                        onPanCancel: () {
                          setState(() {
                            _isDragging = false;
                          });
                        },
                        onTapUp: (details) {
                          if (_isDragging) return;
                          int finalMapped =
                              (details.localPosition.dx / itemWidth)
                                  .floor()
                                  .clamp(0, 3);
                          widget.onTap(_getRealIndex(finalMapped));
                        },
                        child: Stack(
                          children: [
                            // Kính lúp (Magnifying Indicator) trượt theo ngón tay
                            AnimatedPositioned(
                              duration: Duration(
                                milliseconds: _isDragging ? 50 : 300,
                              ),
                              curve: _isDragging
                                  ? Curves.linear
                                  : Curves.easeOutCubic,
                              left: indicatorLeft,
                              top: 0,
                              bottom: 0,
                              width: itemWidth,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isMainTab || _isDragging ? 1.0 : 0.0,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Vòng Lens phình to khi kéo
                                    AnimatedScale(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      scale: _isDragging ? 1.4 : 1.0,
                                      curve: Curves.easeOutBack,
                                      child: Container(
                                        height: 50,
                                        width: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              Colors.purpleAccent.withValues(alpha: 
                                                _isDragging ? 0.35 : 0.25,
                                              ),
                                              AppColors.primary.withValues(alpha: 
                                                _isDragging ? 0.20 : 0.10,
                                              ),
                                              Colors.transparent,
                                            ],
                                            stops: [0.1, 0.6, 1.0],
                                          ),
                                        ),
                                        child: _isDragging
                                            ? ClipOval(
                                                // Hiệu ứng 'screens.magnifyingGlass'.tr() mờ nền
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                    sigmaX: 5,
                                                    sigmaY: 5,
                                                  ),
                                                  child: Container(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.1),
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    // Viên gạch phát sáng (nằm đè lên vùng lens)
                                    AnimatedScale(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      scale: _isDragging ? 1.15 : 1.0,
                                      curve: Curves.easeOutBack,
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 
                                              1.0,
                                            ),
                                            width: _isDragging ? 2.0 : 1.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 
                                                    _isDragging ? 0.3 : 0.15,
                                                  ),
                                              blurRadius: _isDragging ? 12 : 8,
                                              spreadRadius: _isDragging ? 2 : 0,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Các Icon nằm ở trên cùng
                            Builder(
                              builder: (context) {
                                
                                return Row(
                                  children: [
                                    _buildNavItem(
                                      Icons.home_filled,
                                      'home_screen.home'.tr(),
                                      0,
                                      itemWidth,
                                      visualRealIndex,
                                    ),
                                    _buildNavItem(
                                      Icons.map_rounded,
                                      'home_screen.map'.tr(),
                                      1,
                                      itemWidth,
                                      visualRealIndex,
                                      assetIcon: 'assets/images/map.png',
                                    ),
                                    _buildNavItem(
                                      Icons.group_rounded,
                                      'home_screen.community'.tr(),
                                      3,
                                      itemWidth,
                                      visualRealIndex,
                                      badgeCount: unreadCount,
                                    ),
                                    _buildNavItem(
                                      Icons.person_rounded,
                                      'home_screen.account'.tr(),
                                      4,
                                      itemWidth,
                                      visualRealIndex,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          // Isolated Chatbot Button (Circle)
          ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              blendMode: BlendMode.srcOver,
              child: GestureDetector(
                onTap: () => widget.onTap(2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    color: widget.currentIndex == 2
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: widget.currentIndex == 2
                        ? [
                            BoxShadow(
                              color: Colors.purple.withValues(alpha: 0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                  ),
                  child: Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: widget.currentIndex == 2 ? 1.05 : 1.0,
                      child: Image.asset(
                        'assets/images/chat-bot.png',
                        height: 30,
                        width: 30,
                        color: widget.currentIndex == 2
                            ? AppColors.primary
                            : AppColors.textGrey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData defaultIcon,
    String label,
    int index,
    double width,
    int visualCurrentIndex, {
    String? assetIcon,
    int badgeCount = 0,
  }) {
    final isSelected = visualCurrentIndex == index;

    Widget iconWidget = assetIcon != null
        ? Image.asset(
            assetIcon,
            height: 24,
            width: 24,
            color: isSelected ? AppColors.primary : AppColors.textGrey,
          )
        : Icon(
            defaultIcon,
            color: isSelected ? AppColors.primary : AppColors.textGrey,
            size: 26,
          );

    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text(badgeCount > 99 ? '99+' : badgeCount.toString()),
        child: iconWidget,
      );
    }

    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(0, isSelected ? -2.0 : 0.0, 0),
            child: iconWidget,
          ),
          SizedBox(height: 2),
          DefaultTextStyle(
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textGrey,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 10,
              fontFamily: 'Inter',
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

