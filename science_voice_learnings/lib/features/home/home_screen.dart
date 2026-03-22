import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../core/constants.dart';
import '../../core/accessibility/tts_service.dart';
import '../../core/voice_engine.dart';
import '../../core/voice_commands.dart';
import '../../core/progress/progress_service.dart';
import '../../core/progress/progress_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final tts = TtsService();
  final voice = VoiceEngine();

  bool ready = false;
  ProgressModel? dashboard;

  @override
  void initState() {
    super.initState();
    _initAll();
    _loadDashboard();
  }

  Future<void> _initAll() async {
    await tts.init(rate: 0.50);
    final ok = await voice.init();
    if (!mounted) return;
    setState(() => ready = ok);

    await tts.speakBlocking(
      "Now we are in Home page. "
          "There are three modules. "
          "M one for Learning. "
          "M two for Practice. "
          "M three for Challenge. "
          "Tap the microphone and say: move to learning, move to practice, or move to challenge.",
      rate: 0.48,
    );
  }

  Future<void> _loadDashboard() async {
    final dash = await ProgressService.getDashboard();
    if (!mounted) return;
    setState(() => dashboard = dash);
  }

  Future<void> _toggleMic() async {
    if (!ready) return;

    if (voice.listening) {
      await voice.stopListening();
      if (!mounted) return;
      setState(() {});
      return;
    }

    await tts.speak("Listening.", rate: 0.50);

    await voice.startListening(onResult: (words) async {
      final action = VoiceCommands.parse(words);

      if (!mounted) return;

      switch (action) {
        case VoiceAction.toLearning:
          await tts.speak("Now we are in Learning module.", rate: 0.50);
          Navigator.pushNamed(context, AppRoutes.learning).then((_) => _loadDashboard());
          break;

        case VoiceAction.toPractice:
          await tts.speak("Now we are in Practice module.", rate: 0.50);
          Navigator.pushNamed(context, AppRoutes.practice).then((_) => _loadDashboard());
          break;

        case VoiceAction.toChallenge:
          await tts.speak("Now we are in Challenge module.", rate: 0.50);
          Navigator.pushNamed(context, AppRoutes.challenge).then((_) => _loadDashboard());
          break;

        case VoiceAction.stop:
          await tts.stop();
          await voice.stopListening();
          setState(() {});
          break;

        case VoiceAction.unknown:
          await tts.speak("Say: move to learning, move to practice, or move to challenge.", rate: 0.50);
          break;
      }
    });

    if (!mounted) return;
    setState(() {});
  }

  Widget _progressCard() {
    final d = dashboard;
    if (d == null) {
      return const Card(
        child: ListTile(title: Text("Progress"), subtitle: Text("Loading...")),
      );
    }

    return Card(
      child: ListTile(
        title: const Text("Progress"),
        subtitle: Text(
          "Level: ${d.level}\n"
              "Learning: ${d.learningCompleted}/${d.learningTotal}\n"
              "Practice accuracy: ${d.practiceAccuracyPercent}%\n"
              "Best challenge score: ${d.bestChallengeScore}\n"
              "Streak: ${d.streak} day(s)",
        ),
      ),
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
    final micOn = voice.listening;

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
          const SizedBox(height: 14),
          _cardButton(
            icon: Icons.menu_book,
            title: "Learn Braille",
            subtitle: "Master scientific braille symbols",
            onTap: () => Navigator.pushNamed(context, AppRoutes.learning).then((_) => _loadDashboard()),
          ),
          const SizedBox(height: 12),
          _cardButton(
            icon: Icons.track_changes,
            title: "Practice",
            subtitle: "Test your braille knowledge",
            onTap: () => Navigator.pushNamed(context, AppRoutes.practice).then((_) => _loadDashboard()),
          ),
          const SizedBox(height: 12),
          _cardButton(
            icon: Icons.emoji_events,
            title: "Challenge",
            subtitle: "Timed braille challenges",
            onTap: () => Navigator.pushNamed(context, AppRoutes.challenge).then((_) => _loadDashboard()),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x11000000))],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45)
          ],
        ),
      ),
    );
  }
}
