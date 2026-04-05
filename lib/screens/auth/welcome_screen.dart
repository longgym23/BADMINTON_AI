import 'package:flutter/material.dart';
import 'package:badminton_ai/screens/auth/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  Widget _safeImage(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF8), // Màu nền hơi ngả ấm
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [_buildPage1(), _buildPage2(), _buildPage3()],
            ),
          ),
          _buildBottomArea(),
        ],
      ),
    );
  }

  Widget _buildBottomArea() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 24,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIndicatorRow(),
            const SizedBox(height: 24),
            if (_currentPage == 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSkipButton(),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8722A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Tiếp tục',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              _buildNextButtonFullWidth(
                _currentPage == 0 ? 'Tiếp tục' : 'Bắt đầu ngay',
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PAGE 1: Tìm kiếm sân quanh bạn
  // ==========================================
  Widget _buildPage1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image & Top Bar
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.48,
            child: Stack(
              children: [
                ClipPath(
                  clipper: _SlantClipper1(),
                  child: _safeImage(
                    'assets/images/Modern indoor badminton court in warm tones.png', // Court image
                    height: MediaQuery.of(context).size.height * 0.45,
                    fallbackColor: const Color(
                      0xFF4CAF50,
                    ).withValues(alpha: 0.5),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'KLOO',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'lexend',
                            color: Color(0xFFE8722A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Floating cards
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.15,
                  left: 32,
                  child: _buildFloatingImage(
                    'assets/images/destination-map.gif',
                    size: 70,
                  ),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.05,
                  right: 48,
                  child: _buildFloatingImage(
                    'assets/images/worldwide.gif',
                    size: 70,
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
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(text: 'Tìm kiếm sân\n'),
                      TextSpan(
                        text: 'quanh bạn',
                        style: TextStyle(
                          color: Color(0xFFE8722A),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFE8722A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dễ dàng tìm thấy các sân cầu lông đạt chuẩn thi đấu qua bản đồ trực quan hoặc danh sách chọn lọc.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B6B6B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildFeatureChip(Icons.map_outlined, 'Bản đồ'),
                    _buildFeatureChip(Icons.list_alt_rounded, 'Danh sách'),
                    _buildFeatureChip(Icons.near_me_outlined, 'Gần nhất'),
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

  // ==========================================
  // PAGE 2: Đặt sân cực nhanh
  // ==========================================
  Widget _buildPage2() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: const Text(
                'KLOO',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8722A),
                ),
              ),
            ),
          ),
          // Main Image Area
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3ED),
                    shape: BoxShape.circle,
                  ),
                  height: MediaQuery.of(context).size.height * 0.40,
                  width: MediaQuery.of(context).size.height * 0.40,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: _safeImage(
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
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(text: 'Đặt sân '),
                      TextSpan(
                        text: 'cực\nnhanh',
                        style: TextStyle(color: Color(0xFFE8722A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B6B6B),
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'Cập nhật lịch thi đấu theo thời gian thực và thanh toán trực tuyến bảo mật chỉ trong ',
                      ),
                      TextSpan(
                        text: '30 giây.',
                        style: TextStyle(
                          color: Color(0xFFE8722A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  // ==========================================
  // PAGE 3: Giao lưu cùng Cộng đồng
  // ==========================================
  Widget _buildPage3() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image & Top Bar
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              children: [
                _safeImage(
                  'assets/images/Mask Group.png', // Racket image
                  // fit: BoxFit.fitWidth,
                  // fallbackColor: const Color(0xFF795548).withValues(alpha: 0.5),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, top: 8),
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
                // Badge vàng "CỘNG ĐỒNG MẠNH MẼ" nằm ở đáy, đè lên viền chéo
                Positioned(
                  bottom: 16,
                  left: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_alt, color: Colors.black87, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'CỘNG ĐỒNG MẠNH MẼ',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
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
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2D2D2D),
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(text: 'Giao lưu cùng\n'),
                      TextSpan(
                        text: 'Cộng đồng',
                        style: TextStyle(color: Color(0xFFE8722A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: const Text(
                    'Kết nối với các người chơi và cộng đồng thể thao mạnh mẽ, lành mạnh. Khám phá nhiều trận đấu đỉnh cao và hàng ngàn cao thủ cùng chung đam mê đầy nhiệt huyết',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B6B6B),
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2EC),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              color: Color(0xFFFF5722),
                              size: 30,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Giải đấu hàng\ntuần',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D2D2D),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFE8E3),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.hub_outlined,
                              color: Color(0xFF7A655A),
                              size: 30,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Câu lạc bộ địa\nphương',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D2D2D),
                                height: 1.4,
                              ),
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

  // ==========================================
  // SHARED WIDGETS
  // ==========================================
  Widget _buildFloatingIcon(IconData icon, Color color, {double size = 56}) {
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
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }

  Widget _buildFloatingImage(String imagePath, {double size = 56}) {
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

  Widget _buildSkipButton() {
    return Container(
      // decoration: BoxDecoration(
      //   color: const Color(0xFFF5F5F5),
      //   borderRadius: BorderRadius.circular(20),
      // ),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: _goToLogin,
        child: const Text(
          'Bỏ qua',
          style: TextStyle(
            color: Color.fromARGB(255, 8, 8, 8),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
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

  Widget _buildIndicatorRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isActive ? 32 : 12,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE8722A) : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildNextButtonFullWidth(String text) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8722A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Custom Clippers for angled Images
// ---------------------------------------------------------

class _SlantClipper1 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // Page 1: Left is lower, Right is higher
    Path path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
