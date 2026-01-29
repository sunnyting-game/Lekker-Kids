import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/daily_status.dart';
import '../models/today_display_status.dart';
import '../services/student_service.dart';
import '../repositories/student_repository.dart';

/// ViewModel for the ClassroomTab
/// Manages state and business logic for the classroom student list
/// 
/// This ViewModel subscribes to a SINGLE Firestore stream and exposes
/// all display data, eliminating N+1 query issues.
class ClassroomViewModel extends ChangeNotifier {
  final StudentService _studentService;
  final StudentRepository _repository;
  final String currentTeacherId;

  // Stream subscription for cleanup
  StreamSubscription<List<UserModel>>? _studentsSubscription;

  ClassroomViewModel({
    required StudentService studentService,
    required StudentRepository repository,
    required this.currentTeacherId,
  })  : _studentService = studentService,
        _repository = repository {
    _initializeStream();
  }

  // ============================================
  // Student List State
  // ============================================
  List<UserModel> _students = [];
  bool _isLoading = true;
  String? _error;

  List<UserModel> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get today's date in YYYY-MM-DD format
  String get currentDate => _studentService.getTodayDate();

  // ============================================
  // Initialization
  // ============================================
  void _initializeStream() {
    // Subscribe to single stream with ALL display data
    _studentsSubscription = _studentService
        .getStudentsWithDisplayDataStream()
        .listen(
      (studentList) {
        // Apply staleness check then classroom-specific sorting
        final processedStudents = _handleStaleness(studentList);
        _students = _sortForClassroom(processedStudents);
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = 'Failed to load students: $error';
        notifyListeners();
      },
    );
  }

  /// Handle stale status data
  /// If todayDate doesn't match currentDate, reset status to NotArrived
  List<UserModel> _handleStaleness(List<UserModel> students) {
    return students.map((student) {
      if (student.todayDate != currentDate) {
        return student.copyWith(
          clearTodayStatus: true,
          todayDisplayStatus: TodayDisplayStatus.empty(),
        );
      }
      return student;
    }).toList();
  }

  /// Classroom-specific sorting:
  /// 1. CheckedIn students on top
  /// 2. Secondary sort by name A-Z within same status group
  /// (Different from attendance tab which shows NotArrived first)
  List<UserModel> _sortForClassroom(List<UserModel> students) {
    students.sort((a, b) {
      // Primary sort: CheckedIn (present) students first
      final priorityA = _getClassroomPriority(a);
      final priorityB = _getClassroomPriority(b);
      
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      
      // Secondary sort: alphabetical by name
      final nameA = (a.name ?? a.username).toLowerCase();
      final nameB = (b.name ?? b.username).toLowerCase();
      return nameA.compareTo(nameB);
    });
    return students;
  }

  /// Get sort priority for classroom view:
  /// - CheckedIn = 0 (top)
  /// - CheckedOut = 1
  /// - NotArrived = 2
  /// - Absent = 3 (bottom)
  int _getClassroomPriority(UserModel student) {
    if (student.isPresent) return 0;      // CheckedIn first
    if (student.isCheckedOut) return 1;   // CheckedOut second
    if (student.isAbsent) return 3;       // Absent last
    return 2;                              // NotArrived third
  }

  // ============================================
  // Status Toggle Actions
  // ============================================

  /// Toggle meal status for a student
  Future<void> toggleMealStatus(UserModel student) async {
    try {
      final currentStatus = student.todayDisplayStatus?.mealStatus ?? false;
      await _repository.toggleMealStatus(student.uid, currentDate, currentStatus);
    } catch (e) {
      _error = 'Failed to update meal status: $e';
      notifyListeners();
    }
  }

  /// Toggle toilet status for a student
  Future<void> toggleToiletStatus(UserModel student) async {
    try {
      final currentStatus = student.todayDisplayStatus?.toiletStatus ?? false;
      await _repository.toggleToiletStatus(student.uid, currentDate, currentStatus);
    } catch (e) {
      _error = 'Failed to update toilet status: $e';
      notifyListeners();
    }
  }

  /// Toggle sleep status for a student
  Future<void> toggleSleepStatus(UserModel student) async {
    try {
      final currentStatus = student.todayDisplayStatus?.sleepStatus ?? false;
      await _repository.toggleSleepStatus(student.uid, currentDate, currentStatus);
    } catch (e) {
      _error = 'Failed to update sleep status: $e';
      notifyListeners();
    }
  }

  // ============================================
  // Photo Gallery
  // ============================================

  /// Fetch full daily status with photo URLs for gallery popup
  /// This is an on-demand fetch, not a stream (to avoid N+1)
  Future<DailyStatus?> fetchDailyStatusForPhotos(String studentId) async {
    try {
      return await _studentService.getDailyStatus(studentId, currentDate);
    } catch (e) {
      _error = 'Failed to load photos: $e';
      notifyListeners();
      return null;
    }
  }

  // ============================================
  // Error Handling
  // ============================================

  /// Clear error message after displaying
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================
  // Cleanup
  // ============================================
  @override
  void dispose() {
    _studentsSubscription?.cancel();
    super.dispose();
  }
}
