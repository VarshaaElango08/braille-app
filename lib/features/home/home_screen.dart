import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../core/constants.dart';
import '../../core/accessibility/tts_service.dart';
import '../../core/voice_engine.dart';
import '../../core/voice_commands.dart';
import '../../core/progress/progress_service.dart';
import '../../core/progress/progress_model.dart';
import '../../core/settings/app_settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TtsService tts = TtsService();
  final VoiceEngine voice = VoiceEngine();

  bool ready = false;
  bool tamilMode = false;
  ProgressModel? dashboard;

  @override
  void initState() {
    super.initState();
    _initAll();
    _loadDashboard();
  }

  String _narrate(String english, String tamil) {
    return tamilMode ? tamil : english;
  }

  Future<void> _initAll() async {
    tamilMode = await AppSettings.getTamilMode();
    final speechRate = await AppSettings.getSpeechRate();

    await tts.init(rate: speechRate);
    final ok = await voice.init();

    if (!mounted) return;
    setState(() => ready = ok);

    await tts.speakBlocking(
      _narrate(
        "Now we are in Home page. There are five main options. Learning, Practice, Challenge, Progress Dashboard, and Settings. Tap the microphone and say move to learning, move to practice, move to challenge, open dashboard, or open settings.",
        "இப்போது நாங்கள் ஹோம் பக்கத்தில் இருக்கிறோம். இங்கே ஐந்து முக்கிய பகுதிகள் உள்ளன. லெர்னிங், பிராக்டிஸ், சேலஞ்ச், புரோக்ரஸ் டாஷ்போர்டு மற்றும் செட்டிங்ஸ். மைக்ரோஃபோனை அழுத்தி learning, practice, challenge, dashboard அல்லது settings என்று சொல்லலாம்.",
      ),
      rate: speechRate,
    );
  }

  Future<void> _loadDashboard() async {
    final dash = await ProgressService.getDashboard();
    if (!mounted) return;
    setState(() => dashboard = dash);
  }

  Future<void> _stopMicIfNeeded() async {
    if (voice.listening) {
      await voice.stopListening();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _toggleMic() async {
    if (!ready) return;

    if (voice.listening) {
      await voice.stopListening();
      if (!mounted) return;
      setState(() {});
      return;
    }

    final speechRate = await AppSettings.getSpeechRate();
    tamilMode = await AppSettings.getTamilMode();

    await tts.speak(
      _narrate("Listening.", "கேட்கிறேன்."),
      rate: speechRate,
    );

    await voice.startListening(onResult: (words) async {
      final action = VoiceCommands.parse(words);

      if (!mounted) return;
      await _stopMicIfNeeded();

      switch (action) {
        case VoiceAction.toLearning:
          await ProgressService.markModuleOpened("Learning");
          await tts.speak(
            _narrate(
              "Now we are in Learning module.",
              "இப்போது லெர்னிங் பகுதியில் இருக்கிறோம்.",
            ),
            rate: speechRate,
          );
          if (!mounted) return;
          Navigator.pushNamed(context, AppRoutes.learning).then((_) => _loadDashboard());
          break;

        case VoiceAction.toPractice:
          await ProgressService.markModuleOpened("Practice");
          await tts.speak(
            _narrate(
              "Now we are in Practice module.",
              "இப்போது பிராக்டிஸ் பகுதியில் இருக்கிறோம்.",
            ),
            rate: speechRate,
          );
          if (!mounted) return;
          Navigator.pushNamed(context, AppRoutes.practice).then((_) => _loadDashboard());
          break;

        case VoiceAction.toChallenge:
          await ProgressService.markModuleOpened("Challenge");
          await tts.speak(
            _narrate(
              "Now we are in Challenge module.",
              "இப்போது சேலஞ்ச் பகுதியில் இருக்கிறோம்.",
            ),
            rate: speechRate,
          );
          if (!mounted) return;
          Navigator.pushNamed(context, AppRoutes.challenge).then((_) => _loadDashboard());
          break;

        case VoiceAction.toDashboard:
          await ProgressService.markModuleOpened("Dashboard");
          await tts.speak(
            _narrate(
              "Opening your progress dashboard.",
              "உங்கள் புரோக்ரஸ் டாஷ்போர்டை திறக்கிறேன்.",
            ),
            rate: speechRate,
          );
          if (!mounted) return;
          Navigator.pushNamed(context, AppRoutes.dashboard).then((_) => _loadDashboard());
          break;

        case VoiceAction.toSettings:
          await ProgressService.markModuleOpened("Settings");
          await tts.speak(
            _narrate(
              "Opening settings page.",
              "செட்டிங்ஸ் பக்கத்தை திறக்கிறேன்.",
            ),
            rate: speechRate,
          );
          if (!mounted) return;
          Navigator.pushNamed(context, AppRoutes.settings).then((_) => _loadDashboard());
          break;

        case VoiceAction.stop:
          await tts.stop();
          break;

        case VoiceAction.unknown:
          await tts.speak(
            _narrate(
              "Say move to learning, move to practice, move to challenge, open dashboard, or open settings.",
              "லெர்னிங், பிராக்டிஸ், சேலஞ்ச், டாஷ்போர்டு அல்லது செட்டிங்ஸ் என்று சொல்லுங்கள்.",
            ),
            rate: speechRate,
          );
          break;
      }
    });

    if (!mounted) return;
    setState(() {});
  }

  Widget _progressCard() {
    final d = dashboard;

    if (d == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(blurRadius: 12, color: Color(0x12000000)),
          ],
        ),
        child: const Text("Loading progress..."),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.10),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: Color(0x14000000),
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Your Progress",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  d.level,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  icon: Icons.menu_book,
                  title: "Learning",
                  value: "${d.learningCompleted}/${d.learningTotal}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  icon: Icons.track_changes,
                  title: "Practice",
                  value: "${d.practiceAccuracyPercent}%",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  icon: Icons.emoji_events,
                  title: "Challenge",
                  value: "${d.bestChallengeScore}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  icon: Icons.local_fire_department,
                  title: "Streak",
                  value: "${d.streak}",
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _labelRow("Strongest Topic", d.strongestTopic),
          const SizedBox(height: 6),
          _labelRow("Needs Improvement", d.weakestTopic),
        ],
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _labelRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    tts.stop();
    voice.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool micOn = voice.listening;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(AppText.appName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: ready ? _toggleMic : null,
            icon: Icon(micOn ? Icons.mic_off : Icons.mic),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _progressCard(),
          const SizedBox(height: 16),
          _cardButton(
            icon: Icons.menu_book,
            title: "Learn Braille",
            subtitle: "Master scientific braille symbols",
            onTap: () async {
              await ProgressService.markModuleOpened("Learning");
              if (!mounted) return;
              Navigator.pushNamed(context, AppRoutes.learning).then((_) => _loadDashboard());
            },
          ),
          const SizedBox(height: 12),
          _cardButton(
            icon: Icons.track_changes,
            title: "Practice",
            subtitle: "Test your braille knowledge",
            onTap: () async {
              await ProgressService.markModuleOpened("Practice");
              if (!mounted) return;
              Navigator.pushNamed(context, AppRoutes.practice).then((_) => _loadDashboard());
            },
          ),
          const SizedBox(height: 12),
          _cardButton(
            icon: Icons.emoji_events,
            title: "Challenge",
            subtitle: "Timed braille challenges",
            onTap: () async {
              await ProgressService.markModuleOpened("Challenge");
              if (!mounted) return;
              Navigator.pushNamed(context, AppRoutes.challenge).then((_) => _loadDashboard());
            },
          ),
          const SizedBox(height: 12),
          _cardButton(
            icon: Icons.dashboard,
            title: "Progress Dashboard",
            subtitle: "View your learning progress",
            onTap: () async {
              await ProgressService.markModuleOpened("Dashboard");
              if (!mounted) return;
              Navigator.pushNamed(context, AppRoutes.dashboard).then((_) => _loadDashboard());
            },
          ),
          const SizedBox(height: 12),
          _cardButton(
            icon: Icons.settings,
            title: "Settings",
            subtitle: "Control speech speed and accessibility options",
            onTap: () async {
              await ProgressService.markModuleOpened("Settings");
              if (!mounted) return;
              Navigator.pushNamed(context, AppRoutes.settings).then((_) => _loadDashboard());
            },
          ),
        ],
      ),
    );
  }

  Widget _cardButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: Color(0x11000000),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../core/constants.dart';
import '../../core/accessibility/tts_service.dart';
import '../../core/voice_engine.dart';
import '../../core/voice_commands.dart';
import '../../core/progress/progress_service.dart';
import '../../core/progress/progress_model.dart';
import '../../core/settings/app_settings.dart';
import '../../core/accessibility/audio_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TtsService tts = TtsService();
  final VoiceEngine voice = VoiceEngine();

  bool ready = false;
  bool tamilMode = false;
  ProgressModel? dashboard;

  @override
  void initState() {
    super.initState();
    _initAll();
    _loadDashboard();
  }

  String _narrate(String english, String tamil) {
    return tamilMode ? tamil : english;
  }

  Future<void> _initAll() async {
    tamilMode = await AppSettings.getTamilMode();
    final speechRate = await AppSettings.getSpeechRate();

    await tts.init(rate: speechRate);
    final ok = await voice.init();

    if (!mounted) return;
    setState(() => ready = ok);

    await tts.speakBlocking(
      _narrate(
        "Now we are in Home page. There are five main options. Learning, Practice, Challenge, Progress Dashboard, and Settings. Tap the microphone and say move to learning, move to practice, move to challenge, open dashboard, or open settings.",
        "இப்போது நாங்கள் ஹோம் பக்கத்தில் இருக்கிறோம். இங்கே ஐந்து முக்கிய பகுதிகள் உள்ளன. லெர்னிங், பிராக்டிஸ், சேலஞ்ச், புரோக்ரஸ் டாஷ்போர்டு மற்றும் செட்டிங்ஸ். மைக்ரோஃபோனை அழுத்தி learning, practice, challenge, dashboard அல்லது settings என்று சொல்லலாம்.",
      ),
      rate: speechRate,
    );
  }

  Future<void> _loadDashboard() async {
    final dash = await ProgressService.getDashboard();
    if (!mounted) return;
    setState(() => dashboard = dash);
  }

  Future<void> _stopMicIfNeeded() async {
    if (voice.listening) {
      await voice.stopListening();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _toggleMic() async {
    if (!ready) return;

    if (voice.listening) {
      await voice.stopListening();
      await AudioService.playDoneBeep(vibrate: true);
      if (!mounted) return;
      setState(() {});
      return;
    }

    final speechRate = await AppSettings.getSpeechRate();
    tamilMode = await AppSettings.getTamilMode();

    await AudioService.playStartBeep(vibrate: true);

    await tts.speak(
      _narrate("Listening.", "கேட்கிறேன்."),
      rate: speechRate,
    );

    await voice.startListening(onResult: (words) async {
      final action = VoiceCommands.parse(words);

      if (!mounted) return;

      await _stopMicIfNeeded();
      await AudioService.playDoneBeep(vibrate: true);

      switch (action) {
        case VoiceAction.toLearning:
          await ProgressService.markModuleOpened("Learning");
          await tts.speak(
            _narrate(
              "Now we are in Learning module.",
              "இப்போது லெர்னிங் பகுதியில் இருக்கிறோம்.",
            ),
            rate: speechRate,
          );
          if (!mounted) return;
          Navigator.pushNamed(context, AppRoutes.learning)
              .then((_) => _loadDashboard());
          break;

        case VoiceAction.toPractice:
          await ProgressService.markModuleOpened("Practice");
          await tts.speak(
            _narrate(
              "Now we are in Practice module.",
              "இப்போது பிராக்டிஸ் பகுதியில் இருக்கிறோம்.",
            ),
            rate: speechRate,
          );
          if (!mounted) return;
          Navigator.pushNamed(context, AppRoutes.practice)
              .then((_) => _loadDashboard());
          break;

        case VoiceAction.toChallenge:
          await ProgressService.markModuleOpened("Challenge");
          await tts.speak(
            _narrate(
              "Now we are in Challenge module.",
              "இப்போது சேலஞ்ச் பகுதியில் இருக்கிறோம்.",
            ),
            rate: speechRate,
          );
          if (!mounted) return;
          Navigator.pushNamed(context, AppRoutes.challenge)
              .then((_) => _loadDashboard());
          break;

        case VoiceAction.toDashboard:
          await ProgressService.markModuleOpened("Dashboard");
          await tts.speak(
            _narrate(
              "Opening your progress dashboard.",
              "உங்கள் புரோக்ரஸ் டாஷ்போர்டை திறக்கிறேன்.",
            ),
            rate: speechRate,
          );
          if (!mounted) return;
          Navigator.pushNamed(context, AppRoutes.dashboard)
              .then((_) => _loadDashboard());
          break;

        case VoiceAction.toSettings:
          await ProgressService.markModuleOpened("Settings");
          await tts.speak(
            _narrate(
              "Opening settings page.",
              "செட்டிங்ஸ் பக்கத்தை திறக்கிறேன்.",
            ),
            rate: speechRate,
          );
          if (!mounted) return;
          Navigator.pushNamed(context, AppRoutes.settings)
              .then((_) => _loadDashboard());
          break;

        case VoiceAction.stop:
          await tts.stop();
          break;

        case VoiceAction.unknown:
          await tts.speak(
            _narrate(
              "Say move to learning, move to practice, move to challenge, open dashboard, or open settings.",
              "லெர்னிங், பிராக்டிஸ், சேலஞ்ச், டாஷ்போர்டு அல்லது செட்டிங்ஸ் என்று சொல்லுங்கள்.",
            ),
            rate: speechRate,
          );
          break;
      }
    });

    if (!mounted) return;
    setState(() {});
  }

  Widget _progressCard() {
    final d = dashboard;

    if (d == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(blurRadius: 12, color: Color(0x12000000)),
          ],
        ),
        child: const Text("Loading progress..."),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.10),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: Color(0x14000000),
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Your Progress",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  d.level,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  icon: Icons.menu_book,
                  title: "Learning",
                  value: "${d.learningCompleted}/${d.learningTotal}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  icon: Icons.track_changes,
                  title: "Practice",
                  value: "${d.practiceAccuracyPercent}%",
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  icon: Icons.emoji_events,
                  title: "Challenge",
                  value: "${d.bestChallengeScore}",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  icon: Icons.local_fire_department,
                  title: "Streak",
                  value: "${d.streak}",
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _labelRow("Strongest Topic", d.strongestTopic),
          const SizedBox(height: 6),
          _labelRow("Needs Improvement", d.weakestTopic),
        ],
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _labelRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    tts.stop();
    voice.stopListening();
    AudioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool micOn = voice.listening;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(AppText.appName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: ready ? _toggleMic : null,
            icon: Icon(micOn ? Icons.mic_off : Icons.mic),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _progressCard(),
          const SizedBox(height: 16),
          _cardButton(
            icon: Icons.menu_book,
            title: "Learn Braille",
            subtitle: "Master scientific braille symbols",
            onTap: () async {
              await ProgressService.markModuleOpened("Learning");
              if (!mounted) return;
              Navigator.pushNamed(context, AppRoutes.learning)
                  .then((_) => _loadDashboard());
            },
          ),
          const SizedBox(height: 12),
          _cardButton(
            icon: Icons.track_changes,
            title: "Practice",
            subtitle: "Test your braille knowledge",
            onTap: () async {
              await ProgressService.markModuleOpened("Practice");
              if (!mounted) return;
              Navigator.pushNamed(context, AppRoutes.practice)
                  .then((_) => _loadDashboard());
            },
          ),
          const SizedBox(height: 12),
          _cardButton(
            icon: Icons.emoji_events,
            title: "Challenge",
            subtitle: "Timed braille challenges",
            onTap: () async {
              await ProgressService.markModuleOpened("Challenge");
              if (!mounted) return;
              Navigator.pushNamed(context, AppRoutes.challenge)
                  .then((_) => _loadDashboard());
            },
          ),
          const SizedBox(height: 12),
          _cardButton(
            icon: Icons.dashboard,
            title: "Progress Dashboard",
            subtitle: "View your learning progress",
            onTap: () async {
              await ProgressService.markModuleOpened("Dashboard");
              if (!mounted) return;
              Navigator.pushNamed(context, AppRoutes.dashboard)
                  .then((_) => _loadDashboard());
            },
          ),
          const SizedBox(height: 12),
          _cardButton(
            icon: Icons.settings,
            title: "Settings",
            subtitle: "Control speech speed and accessibility options",
            onTap: () async {
              await ProgressService.markModuleOpened("Settings");
              if (!mounted) return;
              Navigator.pushNamed(context, AppRoutes.settings)
                  .then((_) => _loadDashboard());
            },
          ),
        ],
      ),
    );
  }

  Widget _cardButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: Color(0x11000000),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black45,
            ),
          ],
        ),
      ),
    );
  }
}
