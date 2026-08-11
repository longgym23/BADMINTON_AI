import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';

Widget safeWelcomeImage(
  String path, {
  double? height,
  BoxFit fit = BoxFit.cover,
  Color fallbackColor = VColors.borderSubdued,
}) {
  return Image.asset(
    path,
    height: height,
    width: double.infinity,
    fit: fit,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        height: height,
        width: double.infinity,
        color: fallbackColor,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, color: VColors.surface, size: 40),
              const VGap.sm(),
              Text(
                'Image Placeholder',
                style: TextStyle(color: VColors.surface, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget buildWelcomeFloatingImage(String imagePath, {double size = 56}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: VColors.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Center(
      child: Image.asset(
        imagePath,
        width: size * 0.6,
        height: size * 0.6,
        fit: BoxFit.contain,
      ),
    ),
  );
}

Widget buildWelcomeFeatureChip(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: VColors.welcomeAccentSubdued,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: VColors.brandPrimary, size: 18),
        const VGap(8),
        Text(
          label,
          style: VTypography.headingSm.copyWith(color: VColors.textPrimary, fontSize: 13),
        ),
      ],
    ),
  );
}

class WelcomePage1 extends StatelessWidget {
  const WelcomePage1({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.48,
            child: Stack(
              children: [
                ClipPath(
                  clipper: _SlantClipper1(),
                  child: safeWelcomeImage(
                    'assets/images/Modern indoor badminton court in warm tones.png',
                    height: MediaQuery.of(context).size.height * 0.45,
                    fallbackColor: VColors.statusSuccess.withValues(alpha: 0.5),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'KLOO',
                      style: VTypography.headingLg.copyWith(
                        fontSize: 26,
                        fontFamily: 'lexend',
                        color: VColors.brandPrimary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.15,
                  left: 32,
                  child: buildWelcomeFloatingImage('assets/images/destination-map.gif', size: 70),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.05,
                  right: 48,
                  child: buildWelcomeFloatingImage('assets/images/worldwide.gif', size: 70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: VBlockStack(
              gap: VSpacing.md,
              children: [
                RichText(
                  text: TextSpan(
                    style: VTypography.displayLg.copyWith(
                      fontSize: 32,
                      color: VColors.textPrimary,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(text: 'screens.searchYardN'.tr()),
                      TextSpan(
                        text: 'screens.aroundYou'.tr(),
                        style: const TextStyle(
                          color: VColors.brandPrimary,
                          decoration: TextDecoration.underline,
                          decorationColor: VColors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'screens.easilyFindCompetitionStanda'.tr(),
                  style: VTypography.bodyLg.copyWith(color: VColors.textSecondary, height: 1.5),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    buildWelcomeFeatureChip(Icons.map_outlined, 'screens.map'.tr()),
                    buildWelcomeFeatureChip(Icons.list_alt_rounded, 'screens.list'.tr()),
                    buildWelcomeFeatureChip(Icons.near_me_outlined, 'screens.nearest'.tr()),
                  ],
                ),
                const VGap.lg(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomePage2 extends StatelessWidget {
  const WelcomePage2({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'KLOO',
                style: VTypography.headingLg.copyWith(fontSize: 24, color: VColors.brandPrimary),
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(color: VColors.welcomeAccentSubdued, shape: BoxShape.circle),
                  height: MediaQuery.of(context).size.height * 0.40,
                  width: MediaQuery.of(context).size.height * 0.40,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: safeWelcomeImage(
                      'assets/images/Hero Illustration Area_margin.png',
                      fit: BoxFit.contain,
                      fallbackColor: VColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: VBlockStack(
              gap: VSpacing.md,
              children: [
                RichText(
                  text: TextSpan(
                    style: VTypography.displayLg.copyWith(fontSize: 34, color: VColors.textPrimary, height: 1.2),
                    children: [
                      TextSpan(text: 'screens.setThePitch'.tr()),
                      TextSpan(text: 'screens.extremelyNfast'.tr(), style: const TextStyle(color: VColors.brandPrimary)),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: VTypography.bodyLg.copyWith(color: VColors.textSecondary, height: 1.5),
                    children: [
                      TextSpan(text: 'screens.realTimeMatchScheduleUpdat'.tr()),
                      TextSpan(text: 'screens.30Seconds'.tr(), style: const TextStyle(color: VColors.brandPrimary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const VGap.lg(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomePage3 extends StatelessWidget {
  const WelcomePage3({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              children: [
                safeWelcomeImage('assets/images/Mask Group.png'),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, top: 8),
                    child: Text(
                      'KLOO',
                      style: VTypography.headingLg.copyWith(fontSize: 26, fontFamily: 'lexend', color: VColors.brandPrimary),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_alt, color: Colors.black87, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          'screens.sTRONGCOMMUNITY'.tr(),
                          style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: VBlockStack(
              gap: VSpacing.md,
              children: [
                RichText(
                  text: TextSpan(
                    style: VTypography.displayLg.copyWith(fontSize: 34, color: VColors.textPrimary, height: 1.2),
                    children: [
                      TextSpan(text: 'screens.communicateWithN'.tr()),
                      TextSpan(text: 'screens.community'.tr(), style: const TextStyle(color: VColors.brandPrimary)),
                    ],
                  ),
                ),
                Text(
                  'screens.connectWithStrongHealthyP'.tr(),
                  style: VTypography.bodyLg.copyWith(color: VColors.textSecondary, height: 1.6, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(color: VColors.welcomeAccentSubdued, borderRadius: BorderRadius.circular(24)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.emoji_events_outlined, color: VColors.statusWarning, size: 30),
                            const VGap.md(),
                            Text(
                              'screens.weeklyNweeklyTournament'.tr(),
                              style: VTypography.headingSm.copyWith(color: VColors.textPrimary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(color: VColors.welcomeCardSecondary, borderRadius: BorderRadius.circular(24)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.hub_outlined, color: Color(0xFF7A655A), size: 30),
                            const VGap.md(),
                            Text(
                              'screens.localNclub'.tr(),
                              style: VTypography.headingSm.copyWith(color: VColors.textPrimary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const VGap.lg(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlantClipper1 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 80);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
