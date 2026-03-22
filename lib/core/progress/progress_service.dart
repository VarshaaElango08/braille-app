import 'progress_model.dart';
import 'progress_storage.dart';

class ProgressService {
  static Future<ProgressModel> getDashboard() async {
    return await ProgressStorage.load();
  }

  static Future<void> markModuleOpened(String moduleName) async {
    final data = await ProgressStorage.load();
    final updated = _updateStreak(
      data.copyWith(
        lastOpenedModule: moduleName,
      ),
    );
    await ProgressStorage.save(updated);
  }

  static Future<void> saveLearningPosition({
    required int index,
    required String topic,
  }) async {
    final data = await ProgressStorage.load();
    final updated = _updateStreak(
      data.copyWith(
        lastOpenedModule: "Learning",
        lastLearningIndex: index,
        lastTopic: topic,
      ),
    );
    await ProgressStorage.save(updated);
  }

  static Future<void> savePracticePosition({
    required int index,
    required String topic,
  }) async {
    final data = await ProgressStorage.load();
    final updated = _updateStreak(
      data.copyWith(
        lastOpenedModule: "Practice",
        lastPracticeIndex: index,
        lastTopic: topic,
      ),
    );
    await ProgressStorage.save(updated);
  }

  static Future<void> saveChallengePosition({
    required int index,
    required String topic,
  }) async {
    final data = await ProgressStorage.load();
    final updated = _updateStreak(
      data.copyWith(
        lastOpenedModule: "Challenge",
        lastChallengeIndex: index,
        lastTopic: topic,
      ),
    );
    await ProgressStorage.save(updated);
  }

  static Future<void> markLearningComplete({
    String topic = "General Science",
    int totalLessons = 10,
  }) async {
    final data = await ProgressStorage.load();

    final scores = Map<String, int>.from(data.topicScores);
    final attempts = Map<String, int>.from(data.topicAttempts);

    scores[topic] = (scores[topic] ?? 0) + 100;
    attempts[topic] = (attempts[topic] ?? 0) + 1;

    final updated = _updateStreak(
      data.copyWith(
        learningCompleted: data.learningCompleted + 1,
        learningTotal: totalLessons,
        lastOpenedModule: "Learning",
        lastTopic: topic,
        topicScores: scores,
        topicAttempts: attempts,
      ),
    );

    await ProgressStorage.save(updated);
  }

  static Future<void> addPracticeResult({
    required int correct,
    required int total,
    String topic = "General Science",
  }) async {
    final data = await ProgressStorage.load();

    final scores = Map<String, int>.from(data.topicScores);
    final attempts = Map<String, int>.from(data.topicAttempts);

    final percent = total == 0 ? 0 : ((correct / total) * 100).round();

    scores[topic] = (scores[topic] ?? 0) + percent;
    attempts[topic] = (attempts[topic] ?? 0) + 1;

    final updated = _updateStreak(
      data.copyWith(
        practiceCorrect: data.practiceCorrect + correct,
        practiceTotal: data.practiceTotal + total,
        lastOpenedModule: "Practice",
        lastTopic: topic,
        topicScores: scores,
        topicAttempts: attempts,
      ),
    );

    await ProgressStorage.save(updated);
  }

  static Future<void> addChallengeScore({
    required int score,
    String topic = "General Science",
  }) async {
    final data = await ProgressStorage.load();

    final scores = Map<String, int>.from(data.topicScores);
    final attempts = Map<String, int>.from(data.topicAttempts);

    scores[topic] = (scores[topic] ?? 0) + score;
    attempts[topic] = (attempts[topic] ?? 0) + 1;

    final updated = _updateStreak(
      data.copyWith(
        challengeAttempts: data.challengeAttempts + 1,
        bestChallengeScore:
        score > data.bestChallengeScore ? score : data.bestChallengeScore,
        lastOpenedModule: "Challenge",
        lastTopic: topic,
        topicScores: scores,
        topicAttempts: attempts,
      ),
    );

    await ProgressStorage.save(updated);
  }

  static Future<void> resetAll() async {
    await ProgressStorage.clear();
  }

  static String buildEncouragementMessage(ProgressModel model) {
    final accuracy = model.practiceAccuracyPercent;
    final challenge = model.bestChallengeScore;

    if (accuracy >= 80 && challenge >= 80) {
      return "Excellent work. You are performing very well.";
    }
    if (accuracy >= 60 || challenge >= 60) {
      return "Good progress. Keep practicing to improve further.";
    }
    if (model.learningCompleted > 0) {
      return "Nice start. Continue learning and practicing every day.";
    }
    return "Welcome. Start with learning module and build your progress step by step.";
  }

  static ProgressModel _updateStreak(ProgressModel model) {
    final today = _today();
    final last = model.lastUpdatedDate;

    if (last.isEmpty) {
      return model.copyWith(
        streak: 1,
        lastUpdatedDate: today,
      );
    }

    if (last == today) {
      return model.copyWith(lastUpdatedDate: today);
    }

    final diff = _daysBetween(last, today);

    if (diff == 1) {
      return model.copyWith(
        streak: model.streak + 1,
        lastUpdatedDate: today,
      );
    }

    return model.copyWith(
      streak: 1,
      lastUpdatedDate: today,
    );
  }

  static String _today() {
    final now = DateTime.now();
    return "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }

  static int _daysBetween(String oldDate, String newDate) {
    final a = DateTime.tryParse(oldDate);
    final b = DateTime.tryParse(newDate);
    if (a == null || b == null) return 0;
    return b.difference(a).inDays;
  }
}