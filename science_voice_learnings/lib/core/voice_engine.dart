import 'package:speech_to_text/speech_to_text.dart';

class VoiceEngine {
  final SpeechToText _stt = SpeechToText();

  bool _ready = false;
  bool _listening = false;

  bool get ready => _ready;
  bool get listening => _listening;

  Future<bool> init() async {
    try {
      _ready = await _stt.initialize(
        onError: (e) {},
        onStatus: (s) {},
      );
      return _ready;
    } catch (_) {
      _ready = false;
      return false;
    }
  }

  Future<void> startListening({
    required void Function(String words) onResult,
    String localeId = "en_US",
  }) async {
    if (!_ready) {
      final ok = await init();
      if (!ok) return;
    }

    _listening = true;

    await _stt.listen(
      localeId: localeId,
      listenMode: ListenMode.confirmation,
      partialResults: false,
      cancelOnError: true,
      onResult: (res) {
        final words = res.recognizedWords.trim();
        if (words.isNotEmpty) onResult(words);
      },
    );
  }

  Future<void> stopListening() async {
    _listening = false;
    try {
      await _stt.stop();
    } catch (_) {}
  }
}
