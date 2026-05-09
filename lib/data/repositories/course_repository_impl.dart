import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:badminton_ai/data/models/course_model.dart';
import 'package:badminton_ai/domain/entities/course.dart';
import 'package:badminton_ai/domain/entities/course_category.dart';
import 'package:badminton_ai/domain/repositories/course_repository.dart';

class CourseRepositoryImpl implements ICourseRepository {
  final SupabaseClient supabase;

  CourseRepositoryImpl({required this.supabase});

  // Lưu lịch sử xem trong bộ nhớ (có thể nâng cấp lên API sau)
  final List<Course> _watchedCourses = [];

  @override
  Future<List<CourseCategory>> getCategories() async {
    final response = await supabase
        .from('course_categories')
        .select()
        .order('created_at', ascending: true);

    var categories = (response as List).map((json) => CourseCategory(
      id: json['id'].toString(),
      name: json['title'] ?? '',
      iconUrl: json['thumbnail_url'],
    )).toList();

    // Auto-seed Pickleball category if it doesn't exist
    if (!categories.any((c) => c.name.toLowerCase() == 'pickleball')) {
      try {
        await supabase.from('course_categories').insert({
          'title': 'Pickleball',
        });
        
        // Refresh categories after insert
        final refreshResponse = await supabase
            .from('course_categories')
            .select()
            .order('created_at', ascending: true);
            
        return (refreshResponse as List).map((json) => CourseCategory(
          id: json['id'].toString(),
          name: json['title'] ?? '',
          iconUrl: json['thumbnail_url'],
        )).toList();
      } catch (e) {
        print('Error inserting Pickleball category: $e');
      }
    }

    return categories;
  }

  @override
  Future<List<Course>> getCoursesByCategory(String categoryId) async {
    final response = await supabase
        .from('courses')
        .select()
        .eq('category_id', categoryId)
        .order('created_at', ascending: true);

    return (response as List).map((json) => CourseModel.fromJson(json)).toList();
  }

  @override
  Future<List<Course>> getWatchedCourses() async {
    return _watchedCourses.reversed.toList();
  }

  @override
  Future<void> markCourseAsWatched(Course course) async {
    _watchedCourses.removeWhere((c) => c.id == course.id);
    _watchedCourses.add(course);
  }
}
