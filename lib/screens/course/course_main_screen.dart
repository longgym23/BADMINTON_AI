import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/providers/course_provider.dart';
import 'package:badminton_ai/screens/course/course_list_tab.dart';
import 'package:badminton_ai/screens/course/watched_courses_screen.dart';
import 'package:badminton_ai/widgets/custom_gradient_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';

class CourseMainScreen extends StatefulWidget {
  const CourseMainScreen({super.key});

  @override
  State<CourseMainScreen> createState() => _CourseMainScreenState();
}

class _CourseMainScreenState extends State<CourseMainScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CourseProvider>();
      provider.loadCategories().then((_) {
        if (mounted && provider.categories.isNotEmpty) {
          setState(() {
            _tabController = TabController(
              length: provider.categories.length,
              vsync: this,
            );
          });
        }
      });
      provider.loadWatchedCourses();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingCategories && provider.categories.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.categories.isEmpty) {
          return Scaffold(
            appBar: CustomGradientAppBar(
              title: Text(
                'screens.sportsCourse'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              leading: const BackButton(color: Colors.white),
            ),
            body: Center(
              child: Text('screens.thereAreNoCourseCategories'.tr()),
            ),
          );
        }

        return Scaffold(
          appBar: CustomGradientAppBar(
            title: Text(
              'screens.sportsCourse'.tr(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            leading: const BackButton(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                tooltip: 'screens.courseViewed'.tr(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WatchedCoursesScreen(),
                    ),
                  );
                },
              ),
            ],
            bottom: _tabController == null
                ? null
                : TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    dividerColor: Colors.transparent,
                    tabs: provider.categories
                        .map((c) => Tab(text: c.name))
                        .toList(),
                  ),
          ),
          body: _tabController == null
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: provider.categories.map((c) {
                    return CourseListTab(categoryId: c.id);
                  }).toList(),
                ),
        );
      },
    );
  }
}
