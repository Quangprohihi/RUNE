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
  });

  factory FocusSummary.fromClaimResult(Map<String, dynamic> json) {
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
}
