import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/modules/course/viewmodels/course_provider.dart';
import 'package:badminton_ai/modules/course/models/course.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/modules/course/views/pages/course_player_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class CourseListTab extends StatefulWidget {
  final String categoryId;

  const CourseListTab({super.key, required this.categoryId});

  @override
  State<CourseListTab> createState() => _CourseListTabState();
}

class _CourseListTabState extends State<CourseListTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCoursesByCategory(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingCourses &&
            provider.getCoursesFor(widget.categoryId).isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final courses = provider.getCoursesFor(widget.categoryId);

        if (courses.isEmpty) {
          return Center(child: Text('screens.thereAreNoCoursesForThis'.tr()));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return _buildCourseCard(context, course);
          },
        );
      },
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: VColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CoursePlayerScreen(course: course),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  course.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.video_library,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: VColors.brandPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.duration,
                          style: const TextStyle(
                            color: VColors.brandPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
