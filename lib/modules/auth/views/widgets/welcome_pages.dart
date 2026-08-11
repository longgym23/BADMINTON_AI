import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';

Widget safeWelcomeImage(
  String path, {
  double? height,
  BoxFit fit = BoxFit.cover,
  Color fallbackColor = const Color(0xFFE0E0E0),
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
              Icon(Icons.image, color: Colors.white, size: 40),
              SizedBox(height: 8),
              Text(
                'Image Placeholder',
                style: TextStyle(color: Colors.white, fontSize: 12),
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
      color: Colors.white,
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
      color: const Color(0xFFFFF3ED),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFE8722A), size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
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
                    fallbackColor: const Color(0xFF4CAF50).withValues(alpha: 0.5),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: const Text(
                      'KLOO',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'lexend',
                        color: Color(0xFFE8722A),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(text: 'screens.searchYardN'.tr()),
                      TextSpan(
                        text: 'screens.aroundYou'.tr(),
                        style: const TextStyle(
                          color: Color(0xFFE8722A),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFE8722A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'screens.easilyFindCompetitionStanda'.tr(),
                  style: const TextStyle(fontSize: 15, color: Color(0xFF6B6B6B), height: 1.5),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    buildWelcomeFeatureChip(Icons.map_outlined, 'screens.map'.tr()),
                    buildWelcomeFeatureChip(Icons.list_alt_rounded, 'screens.list'.tr()),
                    buildWelcomeFeatureChip(Icons.near_me_outlined, 'screens.nearest'.tr()),
                  ],
                ),
                const SizedBox(height: 24),
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
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'KLOO',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE8722A)),
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
                  decoration: const BoxDecoration(color: Color(0xFFFFF3ED), shape: BoxShape.circle),
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
                      fallbackColor: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D), height: 1.2),
                    children: [
                      TextSpan(text: 'screens.setThePitch'.tr()),
                      TextSpan(text: 'screens.extremelyNfast'.tr(), style: const TextStyle(color: Color(0xFFE8722A))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, color: Color(0xFF6B6B6B), height: 1.5),
                    children: [
                      TextSpan(text: 'screens.realTimeMatchScheduleUpdat'.tr()),
                      TextSpan(text: 'screens.30Seconds'.tr(), style: const TextStyle(color: Color(0xFFE8722A), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                  child: const Padding(
                    padding: EdgeInsets.only(left: 24, top: 8),
                    child: Text(
                      'KLOO',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'lexend', color: Color(0xFFE8722A)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF2D2D2D), height: 1.2),
                    children: [
                      TextSpan(text: 'screens.communicateWithN'.tr()),
                      TextSpan(text: 'screens.community'.tr(), style: const TextStyle(color: Color(0xFFE8722A))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'screens.connectWithStrongHealthyP'.tr(),
                  style: const TextStyle(fontSize: 15, color: Color(0xFF6B6B6B), height: 1.6, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(color: const Color(0xFFFFF2EC), borderRadius: BorderRadius.circular(24)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.emoji_events_outlined, color: Color(0xFFFF5722), size: 30),
                            const SizedBox(height: 16),
                            Text(
                              'screens.weeklyNweeklyTournament'.tr(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2D2D2D), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(color: const Color(0xFFEFE8E3), borderRadius: BorderRadius.circular(24)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.hub_outlined, color: Color(0xFF7A655A), size: 30),
                            const SizedBox(height: 16),
                            Text(
                              'screens.localNclub'.tr(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2D2D2D), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
