class ScienceConcept {
  final String domain;
  final String category;
  final String name;
  final String printSymbol;
  final String brailleChar;
  final List<int> dots;
  final String description;
  final List<String> answers;

  const ScienceConcept({
    required this.domain,
    required this.category,
    required this.name,
    required this.printSymbol,
    required this.brailleChar,
    required this.dots,
    required this.description,
    required this.answers,
  });

  String get id =>
      "${domain}_${category}_${name}_${brailleChar}".replaceAll(" ", "_");
}
