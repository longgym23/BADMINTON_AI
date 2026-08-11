import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/course_category.dart';
import '../repositories/course_repository.dart';

/// Presentation-facing ViewModel for the Course module — calls the
/// repository directly.
class CourseProvider extends ChangeNotifier {
  final ICourseRepository _courseRepository;

  CourseProvider({required ICourseRepository courseRepository})
      : _courseRepository = courseRepository;

  String? _userId;
  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      if (_userId != null) {
        loadWatchedCourses();
      } else {
        _watchedCourses = [];
        notifyListeners();
      }
    }
  }

  List<CourseCategory> _categories = [];
  List<CourseCategory> get categories => _categories;

  final Map<String, List<Course>> _coursesByCategory = {};
  List<Course> getCoursesFor(String categoryId) =>
      _coursesByCategory[categoryId] ?? [];

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
      _categories = await _courseRepository.getCategories();
    } catch (e) {
      debugPrint('Error loading categories: $e');
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
      _coursesByCategory[categoryId] =
          await _courseRepository.getCoursesByCategory(categoryId);
    } catch (e) {
      debugPrint('Error loading courses: $e');
    } finally {
      _isLoadingCourses = false;
      notifyListeners();
    }
  }

  Future<void> loadWatchedCourses() async {
    _isLoadingWatchedCourses = true;
    notifyListeners();

    try {
      _watchedCourses = await _courseRepository.getWatchedCourses();
    } catch (e) {
      debugPrint('Error loading watched courses: $e');
    } finally {
      _isLoadingWatchedCourses = false;
      notifyListeners();
    }
  }

  Future<void> markAsWatched(Course course) async {
    try {
      await _courseRepository.markCourseAsWatched(course);
      await loadWatchedCourses(); // Refresh list sau khi lưu
    } catch (e) {
      debugPrint('Error marking course as watched: $e');
    }
  }
}
