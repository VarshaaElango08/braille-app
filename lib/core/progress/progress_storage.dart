import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'progress_model.dart';

class ProgressStorage {
  static const String _key = "science_voice_progress";

  static Future<void> save(ProgressModel model) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(model.toJson());
    await prefs.setString(_key, jsonString);
  }

  static Future<ProgressModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null || jsonString.isEmpty) {
      return ProgressModel.initial();
    }

    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return ProgressModel.fromJson(map);
    } catch (_) {
      return ProgressModel.initial();
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}