import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:badminton_ai/data/models/course_model.dart';
import 'package:badminton_ai/domain/entities/course.dart';
import 'package:badminton_ai/domain/entities/course_category.dart';
import 'package:badminton_ai/domain/repositories/course_repository.dart';

class CourseRepositoryImpl implements ICourseRepository {
  final SupabaseClient supabase;

  CourseRepositoryImpl({required this.supabase});

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
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('watched_courses_$userId');
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        return decoded
            .map((e) => CourseModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
            .reversed
            .toList();
      }
    } catch (e) {
      print('Error loading watched courses: $e');
    }
    return [];
  }

  @override
  Future<void> markCourseAsWatched(Course course) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Course> courses = [];
      final raw = prefs.getString('watched_courses_$userId');
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        courses = decoded
            .map((e) => CourseModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      
      courses.removeWhere((c) => c.id == course.id);
      courses.add(course);
      
      // Limit to last 50 watched courses to save space
      if (courses.length > 50) {
        courses = courses.sublist(courses.length - 50);
      }
      
      final jsonList = courses.map((c) => (c as CourseModel).toJson()).toList();
      await prefs.setString('watched_courses_$userId', jsonEncode(jsonList));
    } catch (e) {
      print('Error saving watched course: $e');
    }
  }
}
