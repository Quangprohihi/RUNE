class AppConstants {
  const AppConstants._();

  static const int focusMinutes = 25;
  static const int breakMinutes = 5;
  static const int testFocusSeconds = 10;
  static const int tokensPerFocusMinute = 1;
  static const int rewardExpPerBlock = 50;
  static const int rewardTokensPerBlock = 20;
  static const int streakSoftDrop = 2;
  static const int dailyGoalMinutes = 60;

  // Set to true ONLY for local testing — makes every focus/break run for
  // `testFocusSeconds` (10s) instead of the real minutes. Must stay false for
  // real users / demos.
  static const bool useTestFocusDuration = false;

  static int get focusDurationSeconds {
    return useTestFocusDuration ? testFocusSeconds : focusMinutes * 60;
  }

  static int get breakDurationSeconds {
    return useTestFocusDuration ? testFocusSeconds : breakMinutes * 60;
  }
}
