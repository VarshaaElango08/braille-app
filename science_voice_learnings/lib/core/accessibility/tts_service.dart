import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  // default voice settings (NORMAL)
  double _rate = 0.48;
  double _volume = 1.0;
  double _pitch = 1.0;
  String _language = "en-US";

  Future<void> init({
    String language = "en-US",
    double rate = 0.48,
    double volume = 1.0,
    double pitch = 1.0,
  }) async {
    _language = language;
    _rate = rate;
    _volume = volume;
    _pitch = pitch;

    await _tts.setLanguage(_language);
    await _tts.setSpeechRate(_rate);
    await _tts.setVolume(_volume);
    await _tts.setPitch(_pitch);

    // ✅ IMPORTANT: ensures speakBlocking works reliably
    await _tts.awaitSpeakCompletion(true);

    _ready = true;
  }

  Future<void> setRate(double rate) async {
    _rate = rate;
    if (_ready) await _tts.setSpeechRate(_rate);
  }

  Future<void> speak(String text, {double? rate}) async {
    if (!_ready) await init();
    if (rate != null) await _tts.setSpeechRate(rate);

    await _tts.speak(text);

    if (rate != null) await _tts.setSpeechRate(_rate);
  }

  /// ✅ Speak and WAIT until it completes (for blind navigation)
  Future<void> speakBlocking(String text, {double? rate}) async {
    if (!_ready) await init();

    if (rate != null) await _tts.setSpeechRate(rate);

    // since awaitSpeakCompletion(true) is enabled, this will block
    await _tts.speak(text);

    // Fallback wait (some devices still need completion handler)
    final completer = Completer<void>();
    _tts.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
    });
    _tts.setCancelHandler(() {
      if (!completer.isCompleted) completer.complete();
    });

    await completer.future;

    if (rate != null) await _tts.setSpeechRate(_rate);
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
