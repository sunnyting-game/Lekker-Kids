class WeekUtils {
  // Get ISO week number for a given date
  static int getWeekNumber(DateTime date) {
    // 找到這週的星期四
    final dayOfWeek = date.weekday; // 1=Monday, 7=Sunday
    final thursday = date.add(Duration(days: DateTime.thursday - dayOfWeek));
    
    // 找到該年第一週的星期四（1月4日所在週的星期四）
    final jan4 = DateTime(thursday.year, 1, 4);
    final firstThursday = jan4.add(Duration(days: DateTime.thursday - jan4.weekday));
    
    // 計算相差的天數並轉換為週數
    final daysDifference = thursday.difference(firstThursday).inDays;
    final weekNumber = (daysDifference / 7).floor() + 1;
    
    return weekNumber;
  }

  // Get the year for ISO week (can differ from calendar year)
  static int getWeekYear(DateTime date) {
    final dayOfWeek = date.weekday;
    final thursday = date.add(Duration(days: DateTime.thursday - dayOfWeek));
    return thursday.year;
  }

  // Get the first day (Monday) of a given week and year
  static DateTime getFirstDayOfWeek(int year, int weekNumber) {
    // 找到該年第一週的星期四（1月4日所在週的星期四）
    final jan4 = DateTime(year, 1, 4);
    final firstThursday = jan4.add(Duration(days: DateTime.thursday - jan4.weekday));
    
    // 找到第一週的星期一
    final firstMonday = firstThursday.subtract(const Duration(days: 3));
    
    // 加上週數得到目標週的星期一
    return firstMonday.add(Duration(days: (weekNumber - 1) * 7));
  }

  // Get dates for all weekdays (Mon-Fri) of a given week
  static Map<String, DateTime> getWeekDates(int year, int weekNumber) {
    final monday = getFirstDayOfWeek(year, weekNumber);
    
    return {
      'Monday': monday,
      'Tuesday': monday.add(const Duration(days: 1)),
      'Wednesday': monday.add(const Duration(days: 2)),
      'Thursday': monday.add(const Duration(days: 3)),
      'Friday': monday.add(const Duration(days: 4)),
    };
  }

  // Format date as "MMM D, YYYY" (e.g., "Dec 2, 2024")
  static String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Format date as YYYY-MM-DD
  static String formatDateISO(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get current week number
  static int getCurrentWeekNumber() {
    return getWeekNumber(DateTime.now());
  }

  // Get current week year
  static int getCurrentWeekYear() {
    return getWeekYear(DateTime.now());
  }

  // Get total number of weeks in a year
  static int getWeeksInYear(int year) {
    return getWeekNumber(DateTime(year, 12, 28));
  }

  // Navigate to next week (handles year boundary)
  static Map<String, int> getNextWeek(int year, int weekNumber) {
    final lastWeekOfYear = getWeeksInYear(year);
    
    if (weekNumber >= lastWeekOfYear) {
      return {'year': year + 1, 'weekNumber': 1};
    } else {
      return {'year': year, 'weekNumber': weekNumber + 1};
    }
  }

  // Navigate to previous week (handles year boundary)
  static Map<String, int> getPreviousWeek(int year, int weekNumber) {
    if (weekNumber <= 1) {
      final lastWeekOfPrevYear = getWeeksInYear(year - 1);
      return {'year': year - 1, 'weekNumber': lastWeekOfPrevYear};
    } else {
      return {'year': year, 'weekNumber': weekNumber - 1};
    }
  }
}