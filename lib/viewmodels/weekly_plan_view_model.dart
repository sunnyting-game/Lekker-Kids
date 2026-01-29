import 'package:flutter/material.dart';
import '../services/weekly_plan_service.dart';
import '../models/weekly_plan.dart';
import '../utils/week_utils.dart';

class WeeklyPlanViewModel extends ChangeNotifier {
  final WeeklyPlanService _weeklyPlanService;
  
  late int _currentYear;
  late int _currentWeekNumber;
  late Map<String, DateTime> _weekDates;

  WeeklyPlanViewModel({WeeklyPlanService? weeklyPlanService}) 
      : _weeklyPlanService = weeklyPlanService ?? WeeklyPlanService() {
    _currentYear = WeekUtils.getCurrentWeekYear();
    _currentWeekNumber = WeekUtils.getCurrentWeekNumber();
    _updateWeekDates();
  }

  int get currentYear => _currentYear;
  int get currentWeekNumber => _currentWeekNumber;
  Map<String, DateTime> get weekDates => _weekDates;

  List<String> get weekDays => [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  void _updateWeekDates() {
    _weekDates = WeekUtils.getWeekDates(_currentYear, _currentWeekNumber);
    notifyListeners();
  }

  void goToPreviousWeek() {
    final prev = WeekUtils.getPreviousWeek(_currentYear, _currentWeekNumber);
    _currentYear = prev['year']!;
    _currentWeekNumber = prev['weekNumber']!;
    _updateWeekDates();
  }

  void goToNextWeek() {
    final next = WeekUtils.getNextWeek(_currentYear, _currentWeekNumber);
    _currentYear = next['year']!;
    _currentWeekNumber = next['weekNumber']!;
    _updateWeekDates();
  }

  Stream<Map<String, List<WeeklyPlan>>> getWeeklyPlansStream() {
    return _weeklyPlanService
        .getWeeklyPlansStream(_currentYear, _currentWeekNumber)
        .map((plans) {
      final Map<String, List<WeeklyPlan>> plansByDay = {
        'Monday': [],
        'Tuesday': [],
        'Wednesday': [],
        'Thursday': [],
        'Friday': [],
      };

      for (var plan in plans) {
        if (plansByDay.containsKey(plan.dayOfWeek)) {
          plansByDay[plan.dayOfWeek]!.add(plan);
        }
      }
      return plansByDay;
    });
  }

  Future<void> addWeeklyPlan({
    required String title,
    required String description,
    required String dayOfWeek,
  }) async {
    final actualDate = _weekDates[dayOfWeek]!;
    await _weeklyPlanService.addWeeklyPlan(
      title: title,
      description: description,
      year: _currentYear,
      weekNumber: _currentWeekNumber,
      dayOfWeek: dayOfWeek,
      actualDate: WeekUtils.formatDateISO(actualDate),
    );
  }
}
