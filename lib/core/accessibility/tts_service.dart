import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../settings/app_settings.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  double _rate = 0.48;
  double _volume = 1.0;
  double _pitch = 1.0;
  String _language = "en-US";

  Future<void> init({
    String? language,
    double? rate,
    double? volume,
    double? pitch,
  }) async {
    final tamilMode = await AppSettings.getTamilMode();
    final savedRate = await AppSettings.getSpeechRate();

    _rate = rate ?? savedRate;
    _volume = volume ?? 1.0;
    _pitch = pitch ?? 1.0;

    await _tts.awaitSpeakCompletion(true);
    await _tts.setVolume(_volume);
    await _tts.setPitch(_pitch);
    await _tts.setSpeechRate(_rate);

    if (language != null) {
      await _forceLanguage(language);
    } else {
      await _applyLanguageFromSettings(tamilMode: tamilMode);
    }

    _ready = true;
  }

  Future<void> _applyLanguageFromSettings({bool? tamilMode}) async {
    final isTamil = tamilMode ?? await AppSettings.getTamilMode();
    if (isTamil) {
      await _setTamilLanguage();
    } else {
      await _setEnglishLanguage();
    }
  }

  Future<void> refreshLanguageFromSettings() async {
    await _applyLanguageFromSettings();
  }

  Future<void> _setTamilLanguage() async {
    // Try multiple Tamil codes because different phones support different values
    const tamilCandidates = [
      "ta-IN",
      "ta",
    ];

    for (final lang in tamilCandidates) {
      final success = await _trySetLanguage(lang);
      if (success) {
        _language = lang;
        return;
      }
    }

    // fallback
    _language = "en-US";
    await _tts.setLanguage(_language);
  }

  Future<void> _setEnglishLanguage() async {
    const englishCandidates = [
      "en-IN",
      "en-US",
      "en-GB",
      "en",
    ];

    for (final lang in englishCandidates) {
      final success = await _trySetLanguage(lang);
      if (success) {
        _language = lang;
        return;
      }
    }

    _language = "en-US";
    await _tts.setLanguage(_language);
  }

  Future<void> _forceLanguage(String language) async {
    final success = await _trySetLanguage(language);
    if (success) {
      _language = language;
      return;
    }

    if (language.startsWith("ta")) {
      await _setTamilLanguage();
    } else {
      await _setEnglishLanguage();
    }
  }

  Future<bool> _trySetLanguage(String language) async {
    try {
      final result = await _tts.setLanguage(language);

      // flutter_tts may return 1/0/bool/null depending on platform
      if (result == null) return true;
      if (result is bool) return result;
      if (result is int) return result == 1;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> currentLanguage() async {
    return _language;
  }

  Future<void> setRate(double rate) async {
    _rate = rate;
    if (_ready) {
      await _tts.setSpeechRate(_rate);
    }
  }

  Future<void> speak(String text, {double? rate}) async {
    if (!_ready) await init();

    await refreshLanguageFromSettings();

    if (rate != null) {
      await _tts.setSpeechRate(rate);
    }

    await _tts.speak(text);

    if (rate != null) {
      await _tts.setSpeechRate(_rate);
    }
  }

  Future<void> speakBlocking(String text, {double? rate}) async {
    if (!_ready) await init();

    await refreshLanguageFromSettings();

    if (rate != null) {
      await _tts.setSpeechRate(rate);
    }

    final completer = Completer<void>();

    _tts.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
    });

    _tts.setCancelHandler(() {
      if (!completer.isCompleted) completer.complete();
    });

    await _tts.speak(text);
    await completer.future;

    if (rate != null) {
      await _tts.setSpeechRate(_rate);
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}