import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/modules/course/viewmodels/course_provider.dart';
import 'package:badminton_ai/modules/course/models/course.dart';
import 'package:badminton_ai/modules/course/views/pages/course_player_screen.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_gradient_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';

class WatchedCoursesScreen extends StatefulWidget {
  const WatchedCoursesScreen({super.key});

  @override
  State<WatchedCoursesScreen> createState() => _WatchedCoursesScreenState();
}

class _WatchedCoursesScreenState extends State<WatchedCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadWatchedCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text(
          'screens.recentlyViewed'.tr(),
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Consumer<CourseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingWatchedCourses) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = provider.watchedCourses;

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'screens.youHavenTViewedAnyCourses'.tr(),
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return _buildWatchedCourseCard(context, course);
            },
          );
        },
      ),
    );
  }

  Widget _buildWatchedCourseCard(BuildContext context, Course course) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoursePlayerScreen(course: course),
            ),
          );
        },
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 120,
              height: 80,
              child: Image.network(
                course.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.video_library, color: Colors.grey),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.duration,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
