class AnswerParser {
  static int? optionIndex(String words) {
    final t = words.toLowerCase().trim();

    if (t.contains("option a") || t == "a" || t.contains("choose a") || t.contains("select a")) return 0;
    if (t.contains("option b") || t == "b" || t.contains("choose b") || t.contains("select b")) return 1;
    if (t.contains("option c") || t == "c" || t.contains("choose c") || t.contains("select c")) return 2;
    if (t.contains("option d") || t == "d" || t.contains("choose d") || t.contains("select d")) return 3;

    if (t == "option a.") return 0;
    if (t == "option b.") return 1;
    if (t == "option c.") return 2;
    if (t == "option d.") return 3;

    return null;
  }
}
