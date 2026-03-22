import 'dart:math';

/// Builds exactly 4 options always.
/// - First tries same category
/// - If not enough, fills from entire pool
class QuizOptions {
  static ({List<String> options, int correctIndex}) buildFourOptions({
    required String correctText,
    required String correctId,
    required String category,
    required List<_Pickable> pool,
  }) {
    final rand = Random();

    final used = <String>{};
    final wrong = <String>[];

    // 1) same category wrongs
    final sameCat = pool
        .where((e) => e.category == category && e.id != correctId)
        .toList()
      ..shuffle(rand);

    for (final e in sameCat) {
      if (wrong.length >= 3) break;
      if (e.text == correctText) continue;
      if (used.add(e.text)) wrong.add(e.text);
    }

    // 2) fill remaining wrongs from full pool
    if (wrong.length < 3) {
      final others = pool.where((e) => e.id != correctId).toList()..shuffle(rand);
      for (final e in others) {
        if (wrong.length >= 3) break;
        if (e.text == correctText) continue;
        if (used.add(e.text)) wrong.add(e.text);
      }
    }

    // 3) if syllabus is tiny (not your case), pad with safe placeholders
    while (wrong.length < 3) {
      wrong.add("Unknown");
    }

    final options = <String>[correctText, ...wrong]..shuffle(rand);
    final correctIndex = options.indexOf(correctText);

    return (options: options, correctIndex: correctIndex);
  }
}

/// internal view of your concept for option generation
class _Pickable {
  final String id;
  final String category;
  final String text;

  const _Pickable({required this.id, required this.category, required this.text});
}

/// Convert any list into pickables
List<_Pickable> toPickables<T>({
  required List<T> list,
  required String Function(T) id,
  required String Function(T) category,
  required String Function(T) text,
}) {
  return list
      .map((e) => _Pickable(id: id(e), category: category(e), text: text(e)))
      .toList();
}
