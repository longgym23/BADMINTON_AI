import 'package:badminton_ai/screens/user/chat/chatbot_tab.dart';
import 'package:badminton_ai/screens/user/friends/friends_main_screen.dart';
import 'package:badminton_ai/screens/user/home/home_tab.dart';
import 'package:badminton_ai/screens/user/map/map_tab.dart';
import 'package:badminton_ai/screens/user/profile/profile_tab.dart';
import 'package:badminton_ai/blocs/home_filter/home_filter_bloc.dart';
import 'package:badminton_ai/blocs/home_filter/home_filter_event.dart';
import 'package:badminton_ai/domain/usecases/home_filter/get_court_locations_stream_usecase.dart';
import 'package:badminton_ai/domain/usecases/home_filter/get_events_stream_usecase.dart';
import 'package:badminton_ai/domain/usecases/home_filter/get_fallback_courts_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badminton_ai/screens/user/home/components/glass_bottom_nav_bar.dart';

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
        create: (context) => HomeFilterBloc(
          getCourtLocationsStreamUseCase: context
              .read<GetCourtLocationsStreamUseCase>(),
          getFallbackCourtsUseCase: context.read<GetFallbackCourtsUseCase>(),
          getEventsStreamUseCase: context.read<GetEventsStreamUseCase>(),
        )..add(LoadAllCourts()),
        child: const HomeTab(),
      ), // 0: Trang chủ (Wrapped with Filter BLoC)
      const MapTab(), // 1: Bản đồ
      // Fix màn đen: truyền onBack để quay về tab 0 thay vì Navigator.pop
      ChatbotTab(onBack: () => setState(() => _currentIndex = 0)), // 2: Chatbot
      const FriendsMainScreen(), // 3: Cộng đồng & Bạn bè
      const ProfileTab(), // 4: Tài khoản
    ];

    return Scaffold(
      extendBody: true, // Allow body to stretch behind the navigation bar
      resizeToAvoidBottomInset:
          false, // Cho phép bàn phím đè lên BottomNavBar thay vì đẩy nó lên
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _tabs),
          GlassBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          // const NetworkBanner(),
        ],
      ),
    );
  }
}
