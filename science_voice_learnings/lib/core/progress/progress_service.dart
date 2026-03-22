import 'package:shared_preferences/shared_preferences.dart';
import '../../data/syllabus.dart';
import 'progress_model.dart';

class ProgressService {
  static const _kBestChallenge = "best_challenge_score_v1";
  static const _kStreak = "streak_count_v1";
  static const _kLastDate = "last_active_date_v1";

  static const _kLearningSet = "learning_completed_set_v1";
  static const _kPracticeAttempted = "practice_attempted_v1";
  static const _kPracticeCorrect = "practice_correct_v1";

  static String _today() {
    final n = DateTime.now();
    return "${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}";
  }

  static DateTime? _parse(String s) {
    try {
      final p = s.split("-");
      return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    } catch (_) {
      return null;
    }
  }

  static bool _isYesterday(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return db.difference(da).inDays == 1;
  }

  static Future<int> updateDailyStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today();
    final last = prefs.getString(_kLastDate);
    int streak = prefs.getInt(_kStreak) ?? 0;

    if (last == null) {
      streak = 1;
    } else if (last == today) {
      // already counted
    } else {
      final ld = _parse(last);
      final td = _parse(today);
      if (ld != null && td != null && _isYesterday(ld, td)) {
        streak += 1;
      } else {
        streak = 1;
      }
    }

    await prefs.setString(_kLastDate, today);
    await prefs.setInt(_kStreak, streak);
    return streak;
  }

  static Future<void> markLearningCompleted(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final set = prefs.getStringList(_kLearningSet) ?? [];
    if (!set.contains(itemId)) {
      set.add(itemId);
      await prefs.setStringList(_kLearningSet, set);
    }
    await updateDailyStreak();
  }

  /// ✅ your page calls markItemCompleted -> provide alias
  static Future<void> markItemCompleted(String itemId) async {
    await markLearningCompleted(itemId);
  }

  static Future<int> getLearningCompletedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kLearningSet) ?? []).length;
  }

  static Future<void> recordPracticeAttempt({required bool correct}) async {
    final prefs = await SharedPreferences.getInstance();
    final a = (prefs.getInt(_kPracticeAttempted) ?? 0) + 1;
    final c = (prefs.getInt(_kPracticeCorrect) ?? 0) + (correct ? 1 : 0);
    await prefs.setInt(_kPracticeAttempted, a);
    await prefs.setInt(_kPracticeCorrect, c);
    await updateDailyStreak();
  }

  static Future<int> getPracticeAttempted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kPracticeAttempted) ?? 0;
  }

  static Future<int> getPracticeCorrect() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kPracticeCorrect) ?? 0;
  }

  static Future<int> getBestChallengeScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kBestChallenge) ?? 0;
  }

  static Future<void> updateBestChallengeScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_kBestChallenge) ?? 0;
    if (score > best) await prefs.setInt(_kBestChallenge, score);
    await updateDailyStreak();
  }

  static int computeLevel({
    required int learningCompleted,
    required int practiceCorrect,
    required int bestChallengeScore,
  }) {
    final points = (learningCompleted * 2) + practiceCorrect + (bestChallengeScore * 2);
    final level = 1 + (points ~/ 5);
    return level.clamp(1, 999);
  }

  static Future<ProgressModel> getDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt(_kStreak) ?? 0;
    final best = await getBestChallengeScore();

    final learningCompleted = await getLearningCompletedCount();
    final learningTotal = syllabus.length;

    final practiceAttempted = await getPracticeAttempted();
    final practiceCorrect = await getPracticeCorrect();

    final level = computeLevel(
      learningCompleted: learningCompleted,
      practiceCorrect: practiceCorrect,
      bestChallengeScore: best,
    );

    return ProgressModel(
      streak: streak,
      bestChallengeScore: best,
      learningCompleted: learningCompleted,
      learningTotal: learningTotal,
      practiceAttempted: practiceAttempted,
      practiceCorrect: practiceCorrect,
      level: level,
    );
  }
}
