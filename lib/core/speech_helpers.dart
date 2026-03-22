String speakDots(List<int> dots) {
  if (dots.isEmpty) return "no dots";
  final words = dots.map((d) => d.toString()).join(" ");
  return "It holds dots $words.";
}

String speakOptions(List<String> options) {
  const letters = ["A", "B", "C", "D"];
  final parts = <String>[];
  for (int i = 0; i < options.length && i < 4; i++) {
    parts.add("Option ${letters[i]}. ${options[i]}.");
  }
  return parts.join(" ");
}
