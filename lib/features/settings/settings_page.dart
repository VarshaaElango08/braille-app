import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../core/constants.dart';
import '../../core/accessibility/tts_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/progress/progress_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TtsService tts = TtsService();

  bool loading = true;
  bool voiceFeedback = true;
  bool vibrationEnabled = true;
  bool tamilMode = false;
  double speechRate = 0.50;

  String _narrate(String english, String tamil) {
    return tamilMode ? tamil : english;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storedSpeechRate = await AppSettings.getSpeechRate();
    final storedVoiceFeedback = await AppSettings.getVoiceFeedback();
    final storedVibration = await AppSettings.getVibrationEnabled();
    final storedTamilMode = await AppSettings.getTamilMode();

    tamilMode = storedTamilMode;

    await tts.init(rate: storedSpeechRate);
    await ProgressService.markModuleOpened("Settings");

    if (!mounted) return;
    setState(() {
      speechRate = storedSpeechRate;
      voiceFeedback = storedVoiceFeedback;
      vibrationEnabled = storedVibration;
      tamilMode = storedTamilMode;
      loading = false;
    });

    if (voiceFeedback) {
      await tts.speakBlocking(
        _narrate(
          "Now we are in Settings page. Here you can control speech speed, voice feedback, vibration, and Tamil mode. You can also go back home.",
          "இப்போது நாங்கள் செட்டிங்ஸ் பக்கத்தில் இருக்கிறோம். இங்கே நீங்கள் ஒலி வேகம், குரல் வழிகாட்டல், வைப்ரேஷன் மற்றும் தமிழ் முறையை கட்டுப்படுத்தலாம். நீங்கள் ஹோம் பக்கத்திற்கும் திரும்பலாம்.",
        ),
        rate: speechRate,
      );
    }
  }

  Future<void> _goHome() async {
    await ProgressService.markModuleOpened("Home");
    if (voiceFeedback) {
      await tts.speak(
        _narrate("Going to Home page.", "ஹோம் பக்கத்திற்குச் செல்கிறேன்."),
        rate: speechRate,
      );
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
  }

  Future<void> _updateSpeechRate(double value) async {
    setState(() => speechRate = value);
    await AppSettings.setSpeechRate(value);
    await tts.setRate(value);

    if (voiceFeedback) {
      await tts.speak(
        _narrate("Speech speed updated.", "ஒலி வேகம் புதுப்பிக்கப்பட்டது."),
        rate: speechRate,
      );
    }
  }

  Future<void> _updateVoiceFeedback(bool value) async {
    setState(() => voiceFeedback = value);
    await AppSettings.setVoiceFeedback(value);

    if (value) {
      await tts.speak(
        _narrate("Voice feedback enabled.", "குரல் வழிகாட்டல் இயக்கப்பட்டது."),
        rate: speechRate,
      );
    } else {
      await tts.stop();
    }
  }

  Future<void> _updateVibration(bool value) async {
    setState(() => vibrationEnabled = value);
    await AppSettings.setVibrationEnabled(value);

    if (voiceFeedback) {
      await tts.speak(
        _narrate(
          value ? "Vibration enabled." : "Vibration disabled.",
          value ? "வைப்ரேஷன் இயக்கப்பட்டது." : "வைப்ரேஷன் நிறுத்தப்பட்டது.",
        ),
        rate: speechRate,
      );
    }
  }

  Future<void> _updateTamilMode(bool value) async {
    setState(() => tamilMode = value);
    await AppSettings.setTamilMode(value);
    await tts.refreshLanguageFromSettings();

    if (voiceFeedback) {
      await tts.speak(
        value ? "தமிழ் குரல் இயக்கப்பட்டது." : "Tamil narration disabled.",
        rate: speechRate,
      );
    }
  }

  Future<void> _testNarration() async {
    await tts.speakBlocking(
      _narrate(
        "This is a narration test. Tamil mode is currently off.",
        "இது ஒரு குரல் சோதனை. தற்போது தமிழ் முறை செயல்பாட்டில் உள்ளது.",
      ),
      rate: speechRate,
    );
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _goHome,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Accessibility Settings",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  "Change the app experience based on learner comfort.",
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Speech Speed",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text("Current: ${speechRate.toStringAsFixed(2)}"),
                Slider(
                  value: speechRate,
                  min: 0.30,
                  max: 0.70,
                  divisions: 8,
                  label: speechRate.toStringAsFixed(2),
                  onChanged: (value) {
                    setState(() => speechRate = value);
                  },
                  onChangeEnd: _updateSpeechRate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _sectionCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    "Voice Feedback",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text("Speak guidance and actions aloud"),
                  value: voiceFeedback,
                  onChanged: _updateVoiceFeedback,
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    "Vibration",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text("Reserve for future haptic support"),
                  value: vibrationEnabled,
                  onChanged: _updateVibration,
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    "Tamil Mode",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text("Enable Tamil narration only for audio"),
                  value: tamilMode,
                  onChanged: _updateTamilMode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _testNarration,
            icon: const Icon(Icons.record_voice_over),
            label: const Text("Test Narration"),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _goHome,
            icon: const Icon(Icons.home),
            label: const Text("Go Home"),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Color(0x11000000),
          ),
        ],
      ),
      child: child,
    );
  }
}