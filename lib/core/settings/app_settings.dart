import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _speechRateKey = "speech_rate";
  static const String _voiceFeedbackKey = "voice_feedback";
  static const String _vibrationKey = "vibration_enabled";
  static const String _tamilModeKey = "tamil_mode";

  static Future<void> setSpeechRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRateKey, value);
  }

  static Future<double> getSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_speechRateKey) ?? 0.50;
  }

  static Future<void> setVoiceFeedback(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceFeedbackKey, value);
  }

  static Future<bool> getVoiceFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_voiceFeedbackKey) ?? true;
  }

  static Future<void> setVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, value);
  }

  static Future<bool> getVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationKey) ?? true;
  }

  static Future<void> setTamilMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tamilModeKey, value);
  }

  static Future<bool> getTamilMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tamilModeKey) ?? false;
  }
}