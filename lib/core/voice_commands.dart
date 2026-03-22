enum VoiceAction {
  toLearning,
  toPractice,
  toChallenge,
  toDashboard,
  toSettings,
  stop,
  unknown,
}

class VoiceCommands {
  static VoiceAction parse(String words) {
    final t = words.toLowerCase();

    if (t.contains("learning") ||
        t.contains("m1") ||
        t.contains("m one") ||
        t.contains("module one")) {
      return VoiceAction.toLearning;
    }

    if (t.contains("practice") ||
        t.contains("m2") ||
        t.contains("m two") ||
        t.contains("module two")) {
      return VoiceAction.toPractice;
    }

    if (t.contains("challenge") ||
        t.contains("m3") ||
        t.contains("m three") ||
        t.contains("module three")) {
      return VoiceAction.toChallenge;
    }

    if (t.contains("dashboard") ||
        t.contains("progress") ||
        t.contains("my progress") ||
        t.contains("how am i doing")) {
      return VoiceAction.toDashboard;
    }

    if (t.contains("settings") ||
        t.contains("open settings") ||
        t.contains("accessibility settings")) {
      return VoiceAction.toSettings;
    }

    if (t.contains("stop") || t.contains("cancel")) {
      return VoiceAction.stop;
    }

    return VoiceAction.unknown;
  }
}