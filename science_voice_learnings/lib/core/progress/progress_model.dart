class ProgressModel {
  final int streak;
  final int bestChallengeScore;

  final int learningCompleted;
  final int learningTotal;

  final int practiceAttempted;
  final int practiceCorrect;

  final int level;

  int get practiceAccuracyPercent {
    if (practiceAttempted == 0) return 0;
    return ((practiceCorrect / practiceAttempted) * 100).round();
  }

  ProgressModel({
    required this.streak,
    required this.bestChallengeScore,
    required this.learningCompleted,
    required this.learningTotal,
    required this.practiceAttempted,
    required this.practiceCorrect,
    required this.level,
  });
}
