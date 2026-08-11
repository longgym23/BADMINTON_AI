import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/modules/chat/views/pages/chatbot_tab.dart';
import 'package:badminton_ai/modules/friends/views/pages/friends_main_screen.dart';
import 'package:badminton_ai/modules/home/views/pages/home_tab.dart';
import 'package:badminton_ai/modules/map/views/pages/map_tab.dart';
import 'package:badminton_ai/modules/profile/views/pages/profile_tab.dart';
import 'package:badminton_ai/modules/home/viewmodels/home_filter_bloc.dart';
import 'package:badminton_ai/modules/home/viewmodels/home_filter_event.dart';
import 'package:badminton_ai/modules/home/repositories/home_repository.dart';
import 'package:badminton_ai/modules/home/views/widgets/glass_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late List<Widget> _tabs;

  @override
  Widget build(BuildContext context) {
    _tabs = [
      BlocProvider(
        create: (context) => HomeFilterBloc(
          homeRepository: context.read<IHomeRepository>(),
        )..add(LoadAllCourts()),
        child: const HomeTab(),
      ),
      const MapTab(),
      ChatbotTab(onBack: () => setState(() => _currentIndex = 0)),
      const FriendsMainScreen(),
      const ProfileTab(),
    ];

    return VPage(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      useSafeArea: false,
      padding: EdgeInsets.zero,
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
        ],
      ),
    );
  }
}
