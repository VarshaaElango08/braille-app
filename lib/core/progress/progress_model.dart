class ProgressModel {
  final int learningCompleted;
  final int learningTotal;

  final int practiceCorrect;
  final int practiceTotal;

  final int challengeAttempts;
  final int bestChallengeScore;

  final int streak;
  final String lastOpenedModule;
  final String lastUpdatedDate;

  final Map<String, int> topicScores;
  final Map<String, int> topicAttempts;

  final int lastLearningIndex;
  final int lastPracticeIndex;
  final int lastChallengeIndex;
  final String lastTopic;

  const ProgressModel({
    required this.learningCompleted,
    required this.learningTotal,
    required this.practiceCorrect,
    required this.practiceTotal,
    required this.challengeAttempts,
    required this.bestChallengeScore,
    required this.streak,
    required this.lastOpenedModule,
    required this.lastUpdatedDate,
    required this.topicScores,
    required this.topicAttempts,
    required this.lastLearningIndex,
    required this.lastPracticeIndex,
    required this.lastChallengeIndex,
    required this.lastTopic,
  });

  factory ProgressModel.initial() {
    return const ProgressModel(
      learningCompleted: 0,
      learningTotal: 10,
      practiceCorrect: 0,
      practiceTotal: 0,
      challengeAttempts: 0,
      bestChallengeScore: 0,
      streak: 0,
      lastOpenedModule: "",
      lastUpdatedDate: "",
      topicScores: {},
      topicAttempts: {},
      lastLearningIndex: 0,
      lastPracticeIndex: 0,
      lastChallengeIndex: 0,
      lastTopic: "",
    );
  }

  ProgressModel copyWith({
    int? learningCompleted,
    int? learningTotal,
    int? practiceCorrect,
    int? practiceTotal,
    int? challengeAttempts,
    int? bestChallengeScore,
    int? streak,
    String? lastOpenedModule,
    String? lastUpdatedDate,
    Map<String, int>? topicScores,
    Map<String, int>? topicAttempts,
    int? lastLearningIndex,
    int? lastPracticeIndex,
    int? lastChallengeIndex,
    String? lastTopic,
  }) {
    return ProgressModel(
      learningCompleted: learningCompleted ?? this.learningCompleted,
      learningTotal: learningTotal ?? this.learningTotal,
      practiceCorrect: practiceCorrect ?? this.practiceCorrect,
      practiceTotal: practiceTotal ?? this.practiceTotal,
      challengeAttempts: challengeAttempts ?? this.challengeAttempts,
      bestChallengeScore: bestChallengeScore ?? this.bestChallengeScore,
      streak: streak ?? this.streak,
      lastOpenedModule: lastOpenedModule ?? this.lastOpenedModule,
      lastUpdatedDate: lastUpdatedDate ?? this.lastUpdatedDate,
      topicScores: topicScores ?? this.topicScores,
      topicAttempts: topicAttempts ?? this.topicAttempts,
      lastLearningIndex: lastLearningIndex ?? this.lastLearningIndex,
      lastPracticeIndex: lastPracticeIndex ?? this.lastPracticeIndex,
      lastChallengeIndex: lastChallengeIndex ?? this.lastChallengeIndex,
      lastTopic: lastTopic ?? this.lastTopic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "learningCompleted": learningCompleted,
      "learningTotal": learningTotal,
      "practiceCorrect": practiceCorrect,
      "practiceTotal": practiceTotal,
      "challengeAttempts": challengeAttempts,
      "bestChallengeScore": bestChallengeScore,
      "streak": streak,
      "lastOpenedModule": lastOpenedModule,
      "lastUpdatedDate": lastUpdatedDate,
      "topicScores": topicScores,
      "topicAttempts": topicAttempts,
      "lastLearningIndex": lastLearningIndex,
      "lastPracticeIndex": lastPracticeIndex,
      "lastChallengeIndex": lastChallengeIndex,
      "lastTopic": lastTopic,
    };
  }

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      learningCompleted: json["learningCompleted"] ?? 0,
      learningTotal: json["learningTotal"] ?? 10,
      practiceCorrect: json["practiceCorrect"] ?? 0,
      practiceTotal: json["practiceTotal"] ?? 0,
      challengeAttempts: json["challengeAttempts"] ?? 0,
      bestChallengeScore: json["bestChallengeScore"] ?? 0,
      streak: json["streak"] ?? 0,
      lastOpenedModule: json["lastOpenedModule"] ?? "",
      lastUpdatedDate: json["lastUpdatedDate"] ?? "",
      topicScores: Map<String, int>.from(json["topicScores"] ?? {}),
      topicAttempts: Map<String, int>.from(json["topicAttempts"] ?? {}),
      lastLearningIndex: json["lastLearningIndex"] ?? 0,
      lastPracticeIndex: json["lastPracticeIndex"] ?? 0,
      lastChallengeIndex: json["lastChallengeIndex"] ?? 0,
      lastTopic: json["lastTopic"] ?? "",
    );
  }

  int get practiceAccuracyPercent {
    if (practiceTotal == 0) return 0;
    return ((practiceCorrect / practiceTotal) * 100).round();
  }

  int get learningPercent {
    if (learningTotal == 0) return 0;
    return ((learningCompleted / learningTotal) * 100).round();
  }

  String get level {
    final score =
    ((learningPercent + practiceAccuracyPercent + bestChallengeScore) / 3)
        .round();

    if (score >= 85) return "Advanced";
    if (score >= 60) return "Intermediate";
    if (score >= 35) return "Beginner";
    return "Starter";
  }

  String get strongestTopic {
    if (topicScores.isEmpty) return "Not enough data";

    String best = topicScores.keys.first;
    double bestAvg = _avgFor(best);

    for (final key in topicScores.keys) {
      final avg = _avgFor(key);
      if (avg > bestAvg) {
        best = key;
        bestAvg = avg;
      }
    }
    return best;
  }

  String get weakestTopic {
    if (topicScores.isEmpty) return "Not enough data";

    String weak = topicScores.keys.first;
    double weakAvg = _avgFor(weak);

    for (final key in topicScores.keys) {
      final avg = _avgFor(key);
      if (avg < weakAvg) {
        weak = key;
        weakAvg = avg;
      }
    }
    return weak;
  }

  double _avgFor(String topic) {
    final totalScore = topicScores[topic] ?? 0;
    final attempts = topicAttempts[topic] ?? 0;
    if (attempts == 0) return 0;
    return totalScore / attempts;
  }
}