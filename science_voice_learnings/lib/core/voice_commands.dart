enum VoiceAction { toLearning, toPractice, toChallenge, stop, unknown }

class VoiceCommands {
  static VoiceAction parse(String words) {
    final t = words.toLowerCase();

    if (t.contains("learning") || t.contains("m1") || t.contains("m one") || t.contains("module one")) {
      return VoiceAction.toLearning;
    }
    if (t.contains("practice") || t.contains("m2") || t.contains("m two") || t.contains("module two")) {
      return VoiceAction.toPractice;
    }
    if (t.contains("challenge") || t.contains("m3") || t.contains("m three") || t.contains("module three")) {
      return VoiceAction.toChallenge;
    }
    if (t.contains("stop") || t.contains("cancel")) return VoiceAction.stop;

    return VoiceAction.unknown;
  }
}
