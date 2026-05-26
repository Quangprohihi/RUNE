class AppConstants {
  const AppConstants._();

  static const int focusMinutes = 25;
  static const int breakMinutes = 5;
  static const int testFocusSeconds = 3;
  static const int tokensPerFocusMinute = 1;
  static const int rewardExpPerBlock = 50;
  static const int rewardTokensPerBlock = 20;
  static const int streakSoftDrop = 2;

  static const bool useTestFocusDuration = true;

  static int get focusDurationSeconds {
    return useTestFocusDuration ? testFocusSeconds : focusMinutes * 60;
  }

  static int get breakDurationSeconds {
    return useTestFocusDuration ? testFocusSeconds : breakMinutes * 60;
  }
}
