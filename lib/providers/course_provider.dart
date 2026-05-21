import 'package:flutter/material.dart';
import 'package:badminton_ai/domain/entities/course.dart';
import 'package:badminton_ai/domain/entities/course_category.dart';
import 'package:badminton_ai/domain/usecases/course/get_categories_usecase.dart';
import 'package:badminton_ai/domain/usecases/course/get_courses_by_category_usecase.dart';
import 'package:badminton_ai/domain/usecases/course/get_watched_courses_usecase.dart';
import 'package:badminton_ai/domain/usecases/course/mark_course_as_watched_usecase.dart';

class CourseProvider extends ChangeNotifier {
  final GetCategoriesUseCase _getCategoriesUseCase;
  final GetCoursesByCategoryUseCase _getCoursesByCategoryUseCase;
  final GetWatchedCoursesUseCase _getWatchedCoursesUseCase;
  final MarkCourseAsWatchedUseCase _markCourseAsWatchedUseCase;

  CourseProvider({
    required GetCategoriesUseCase getCategoriesUseCase,
    required GetCoursesByCategoryUseCase getCoursesByCategoryUseCase,
    required GetWatchedCoursesUseCase getWatchedCoursesUseCase,
    required MarkCourseAsWatchedUseCase markCourseAsWatchedUseCase,
  }) : _getCategoriesUseCase = getCategoriesUseCase,
       _getCoursesByCategoryUseCase = getCoursesByCategoryUseCase,
       _getWatchedCoursesUseCase = getWatchedCoursesUseCase,
       _markCourseAsWatchedUseCase = markCourseAsWatchedUseCase;

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

  Map<String, List<Course>> _coursesByCategory = {};
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
      _categories = await _getCategoriesUseCase();
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
      _coursesByCategory[categoryId] = await _getCoursesByCategoryUseCase(
        categoryId,
      );
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
      _watchedCourses = await _getWatchedCoursesUseCase();
    } catch (e) {
      print('Error loading watched courses: $e');
    } finally {
      _isLoadingWatchedCourses = false;
      notifyListeners();
    }
  }

  Future<void> markAsWatched(Course course) async {
    try {
      await _markCourseAsWatchedUseCase(course);
      await loadWatchedCourses(); // Refresh list sau khi lưu
    } catch (e) {
      print('Error marking course as watched: $e');
    }
  }
}
