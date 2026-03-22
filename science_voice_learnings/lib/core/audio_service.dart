import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();

  static final AudioPlayer _player = AudioPlayer();

  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    _inited = true;

    // Keep player ready for low-latency short sounds
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  static Future<void> playSplash() async {
    await init();
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/splash_fantasy.mp3'));
    } catch (_) {}
  }

  static Future<void> playBeep() async {
    await init();
    try {
      // For beep, stop then play quickly
      await _player.stop();
      await _player.play(AssetSource('audio/beep.mp3'));
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  static Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
