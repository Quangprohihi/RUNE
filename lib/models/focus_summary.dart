import 'pet.dart';
import 'wallet.dart';

class FocusSummary {
  const FocusSummary({
    required this.label,
    required this.plannedMinutes,
    required this.rewardTokens,
    required this.rewardExp,
    required this.category,
    required this.pomodoroCount,
    required this.wallet,
    required this.pet,
    required this.currentStreak,
    required this.todayFocusMinutes,
    required this.dailyGoalMinutes,
    required this.companionCode,
    required this.companionName,
    required this.skillName,
    required this.skillDescription,
    required this.baseRewardTokens,
    required this.bonusTokens,
    required this.baseRewardExp,
    required this.bonusExp,
    required this.energySaved,
  });

  factory FocusSummary.fromClaimResult(
    Map<String, dynamic> json, {
    required int todayFocusMinutes,
    required int dailyGoalMinutes,
  }) {
    final session = json['session'] as Map<String, dynamic>? ?? const {};
    final streak = json['streak'] as Map<String, dynamic>? ?? const {};
    return FocusSummary(
      label: session['label'] as String? ?? 'Focus',
      plannedMinutes: session['plannedMinutes'] as int? ?? 0,
      rewardTokens: json['rewardTokens'] as int? ?? 0,
      rewardExp: json['rewardExp'] as int? ?? 0,
      category: json['category'] as String? ?? 'Focus',
      pomodoroCount: json['pomodoroCount'] as int? ?? 1,
      wallet: Wallet.fromJson(
        json['wallet'] as Map<String, dynamic>? ?? const {},
      ),
      pet: Pet.fromJson(json['pet'] as Map<String, dynamic>? ?? const {}),
      currentStreak: streak['currentStreak'] as int? ?? 0,
      todayFocusMinutes: todayFocusMinutes,
      dailyGoalMinutes: dailyGoalMinutes,
      companionCode: json['companionCode'] as String? ?? 'kiki',
      companionName: json['companionName'] as String? ?? 'Kiki',
      skillName: json['skillName'] as String? ?? 'Fast Learner',
      skillDescription: json['skillDescription'] as String? ?? '+5% EXP',
      baseRewardTokens: json['baseRewardTokens'] as int? ?? 0,
      bonusTokens: json['bonusTokens'] as int? ?? 0,
      baseRewardExp: json['baseRewardExp'] as int? ?? 0,
      bonusExp: json['bonusExp'] as int? ?? 0,
      energySaved: json['energySaved'] as int? ?? 0,
    );
  }

  final String label;
  final int plannedMinutes;
  final int rewardTokens;
  final int rewardExp;
  final String category;
  final int pomodoroCount;
  final Wallet wallet;
  final Pet pet;
  final int currentStreak;

  final int todayFocusMinutes;
  final int dailyGoalMinutes;
  final String companionCode;
  final String companionName;
  final String skillName;
  final String skillDescription;
  final int baseRewardTokens;
  final int bonusTokens;
  final int baseRewardExp;
  final int bonusExp;
  final int energySaved;

  bool get hasCompanionBonus =>
      bonusTokens > 0 || bonusExp > 0 || energySaved > 0;

  double get dailyGoalProgress =>
      (todayFocusMinutes / dailyGoalMinutes).clamp(0, 1).toDouble();

  int get dailyGoalRemainingMinutes =>
      (dailyGoalMinutes - todayFocusMinutes).clamp(0, dailyGoalMinutes).toInt();

  bool get dailyGoalCompleted => todayFocusMinutes >= dailyGoalMinutes;
}
