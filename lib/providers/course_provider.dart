import 'package:flutter/material.dart';
import 'package:badminton_ai/domain/entities/course.dart';
import 'package:badminton_ai/domain/entities/course_category.dart';
import 'package:badminton_ai/domain/repositories/course_repository.dart';

class CourseProvider extends ChangeNotifier {
  final ICourseRepository courseRepository;

  CourseProvider({required this.courseRepository});

  List<CourseCategory> _categories = [];
  List<CourseCategory> get categories => _categories;

  Map<String, List<Course>> _coursesByCategory = {};
  List<Course> getCoursesFor(String categoryId) => _coursesByCategory[categoryId] ?? [];

  List<Course> _watchedCourses = [];
  List<Course> get watchedCourses => _watchedCourses;

  bool _isLoadingCategories = false;
  bool get isLoadingCategories => _isLoadingCategories;

  bool _isLoadingCourses = false;
  bool get isLoadingCourses => _isLoadingCourses;

  bool _isLoadingWatchedCourses = false;
  bool get isLoadingWatchedCourses => _isLoadingWatchedCourses;

  Future<void> loadCategories() async {
    _isLoadingCategories = true;
    notifyListeners();

    try {
      _categories = await courseRepository.getCategories();
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> loadCoursesByCategory(String categoryId) async {
    if (_coursesByCategory.containsKey(categoryId)) return;

    _isLoadingCourses = true;
    notifyListeners();

    try {
      _coursesByCategory[categoryId] = await courseRepository.getCoursesByCategory(categoryId);
    } catch (e) {
      print('Error loading courses: $e');
    } finally {
      _isLoadingCourses = false;
      notifyListeners();
    }
  }

  Future<void> loadWatchedCourses() async {
    _isLoadingWatchedCourses = true;
    notifyListeners();

    try {
      _watchedCourses = await courseRepository.getWatchedCourses();
    } catch (e) {
      print('Error loading watched courses: $e');
    } finally {
      _isLoadingWatchedCourses = false;
      notifyListeners();
    }
  }

  Future<void> markAsWatched(Course course) async {
    try {
      await courseRepository.markCourseAsWatched(course);
      await loadWatchedCourses(); // Refresh list sau khi lưu
    } catch (e) {
      print('Error marking course as watched: $e');
    }
  }
}
