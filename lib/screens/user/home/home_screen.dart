import 'package:badminton_ai/screens/user/chat/chatbot_tab.dart';
import 'package:badminton_ai/screens/user/highlights/highlights_tab.dart';
import 'package:badminton_ai/screens/user/home/home_tab.dart';
import 'package:badminton_ai/screens/user/map/map_tab.dart';
import 'package:badminton_ai/screens/user/profile/profile_tab.dart';
import 'package:badminton_ai/data/repositories/supabase_repository.dart';
import 'package:badminton_ai/blocs/home_filter/home_filter_bloc.dart';
import 'package:badminton_ai/blocs/home_filter/home_filter_event.dart';
import 'package:badminton_ai/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // We use late so we can use context in initState or build
  late List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    // Initialize tabs here so we have access to context reading
  }

  @override
  Widget build(BuildContext context) {
    _tabs = [
      BlocProvider(
        create: (context) =>
            HomeFilterBloc(repository: context.read<SupabaseRepository>())
              ..add(LoadAllCourts()),
        child: const HomeTab(),
      ), // 0: Trang chủ (Wrapped with Filter BLoC)
      const MapTab(), // 1: Bản đồ
      const ChatbotTab(), // 2: Chatbot (Nút giữa)
      const HighlightsTab(), // 3: Nổi bật
      const ProfileTab(), // 4: Tài khoản
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGrey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/map.png',
              height: 24,
              width: 24,
              color: AppColors.textGrey,
            ),
            activeIcon: Image.asset(
              'assets/images/map.png',
              height: 24,
              width: 24,
              color: AppColors.primary,
            ),
            label: 'Bản đồ',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/chat-bot.png',
              height: 24,
              width: 24,
              // Nếu icon chatbot có sẵn màu, bạn có thể bỏ dòng color đi
              // color: AppColors.textGrey,
            ),
            activeIcon: Image.asset(
              'assets/images/chat-bot.png',
              height: 24,
              width: 24,
              // Nếu icon chatbot có sẵn màu, bạn có thể bỏ dòng color đi
              // color: AppColors.primary,
            ),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Nổi bật'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
