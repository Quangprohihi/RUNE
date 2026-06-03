class AnalyticsSummary {
  const AnalyticsSummary({
    required this.totalFocusMinutes,
    required this.sessionsToday,
    required this.pomodorosToday,
    required this.pomodorosThisWeek,
    required this.currentStreak,
    required this.bestStreak,
    required this.focusByDay,
    required this.categoryBreakdown,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalFocusMinutes: json['totalFocusMinutes'] as int? ?? 0,
      sessionsToday: json['sessionsToday'] as int? ?? 0,
      pomodorosToday: json['pomodorosToday'] as int? ?? 0,
      pomodorosThisWeek: json['pomodorosThisWeek'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      focusByDay: (json['focusByDay'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(FocusDayStat.fromJson)
          .toList(),
      categoryBreakdown:
          (json['categoryBreakdown'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>()
              .map(CategoryFocusStat.fromJson)
              .toList(),
    );
  }

  factory AnalyticsSummary.empty() {
    return const AnalyticsSummary(
      totalFocusMinutes: 0,
      sessionsToday: 0,
      pomodorosToday: 0,
      pomodorosThisWeek: 0,
      currentStreak: 0,
      bestStreak: 0,
      focusByDay: [],
      categoryBreakdown: [],
    );
  }

  final int totalFocusMinutes;
  final int sessionsToday;
  final int pomodorosToday;
  final int pomodorosThisWeek;
  final int currentStreak;
  final int bestStreak;
  final List<FocusDayStat> focusByDay;
  final List<CategoryFocusStat> categoryBreakdown;

  int get weeklyFocusMinutes {
    return focusByDay.fold(0, (sum, day) => sum + day.minutes);
  }

  double get averageMinutesPerDay {
    if (focusByDay.isEmpty) return 0;
    return weeklyFocusMinutes / focusByDay.length;
  }

  FocusDayStat? get mostActiveDay {
    if (focusByDay.isEmpty) return null;
    return focusByDay.reduce(
      (best, day) => day.minutes > best.minutes ? day : best,
    );
  }

  String get weekRangeLabel {
    if (focusByDay.isEmpty) return 'This week';
    final first = focusByDay.first.date;
    final last = focusByDay.last.date;
    return '${_monthName(first.month)} ${first.day} - ${_monthName(last.month)} ${last.day}';
  }

  static String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '';
    return names[month - 1];
  }
}

class FocusDayStat {
  const FocusDayStat({required this.date, required this.minutes});

  factory FocusDayStat.fromJson(Map<String, dynamic> json) {
    return FocusDayStat(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      minutes: json['minutes'] as int? ?? 0,
    );
  }

  final DateTime date;
  final int minutes;
}

class CategoryFocusStat {
  const CategoryFocusStat({required this.category, required this.minutes});

  factory CategoryFocusStat.fromJson(Map<String, dynamic> json) {
    return CategoryFocusStat(
      category: json['category'] as String? ?? 'Focus',
      minutes: json['minutes'] as int? ?? 0,
    );
  }

  final String category;
  final int minutes;
}
