import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../core/constants.dart';
import '../../core/accessibility/tts_service.dart';
import '../../core/progress/progress_model.dart';
import '../../core/progress/progress_service.dart';
import '../../core/settings/app_settings.dart';

class ProgressDashboardPage extends StatefulWidget {
  const ProgressDashboardPage({super.key});

  @override
  State<ProgressDashboardPage> createState() => _ProgressDashboardPageState();
}

class _ProgressDashboardPageState extends State<ProgressDashboardPage> {
  final TtsService tts = TtsService();

  ProgressModel? progress;
  bool loading = true;
  bool tamilMode = false;

  String _narrate(String english, String tamil) {
    return tamilMode ? tamil : english;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    tamilMode = await AppSettings.getTamilMode();
    final speechRate = await AppSettings.getSpeechRate();

    await tts.init(rate: speechRate);
    await ProgressService.markModuleOpened("Dashboard");
    await _loadData();
    await _speakSummary();
  }

  Future<void> _loadData() async {
    final data = await ProgressService.getDashboard();

    if (!mounted) return;
    setState(() {
      progress = data;
      loading = false;
    });
  }

  Future<void> _goHome() async {
    final speechRate = await AppSettings.getSpeechRate();
    tamilMode = await AppSettings.getTamilMode();

    await ProgressService.markModuleOpened("Home");
    await tts.speak(
      _narrate("Going to Home page.", "ஹோம் பக்கத்திற்குச் செல்கிறேன்."),
      rate: speechRate,
    );
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
  }

  Future<void> _speakSummary() async {
    final speechRate = await AppSettings.getSpeechRate();
    tamilMode = await AppSettings.getTamilMode();

    final data = await ProgressService.getDashboard();
    final encouragement = ProgressService.buildEncouragementMessage(data);

    final summary = _narrate(
      "Now we are in Progress Dashboard. "
          "Your level is ${data.level}. "
          "You completed ${data.learningCompleted} out of ${data.learningTotal} learning items. "
          "Your practice accuracy is ${data.practiceAccuracyPercent} percent. "
          "Your best challenge score is ${data.bestChallengeScore}. "
          "Your learning streak is ${data.streak} day or days. "
          "Your strongest topic is ${data.strongestTopic}. "
          "Your weakest topic is ${data.weakestTopic}. "
          "Last opened module is ${data.lastOpenedModule}. "
          "Last topic is ${data.lastTopic.isEmpty ? "not available" : data.lastTopic}. "
          "You can say go home to return to home page. "
          "$encouragement",
      "இப்போது நாங்கள் புரோக்ரஸ் டாஷ்போர்டில் இருக்கிறோம். "
          "உங்கள் நிலை ${data.level}. "
          "நீங்கள் ${data.learningTotal} இல் ${data.learningCompleted} கற்றல் பகுதிகளை முடித்துள்ளீர்கள். "
          "உங்கள் பிராக்டிஸ் துல்லியம் ${data.practiceAccuracyPercent} சதவீதம். "
          "உங்கள் சிறந்த சேலஞ்ச் மதிப்பெண் ${data.bestChallengeScore}. "
          "உங்கள் கற்றல் ஸ்ட்ரீக் ${data.streak} நாள். "
          "உங்கள் சிறந்த தலைப்பு ${data.strongestTopic}. "
          "மேலும் பயிற்சி தேவைப்படும் தலைப்பு ${data.weakestTopic}. "
          "கடைசியாக திறந்த பகுதி ${data.lastOpenedModule}. "
          "கடைசி தலைப்பு ${data.lastTopic.isEmpty ? "தகவல் இல்லை" : data.lastTopic}. "
          "ஹோம் பக்கத்திற்குத் திரும்ப go home சொல்லலாம். "
          "$encouragement",
    );

    await tts.speakBlocking(summary, rate: speechRate);
  }

  Future<void> _resetProgress() async {
    final speechRate = await AppSettings.getSpeechRate();
    tamilMode = await AppSettings.getTamilMode();

    await ProgressService.resetAll();
    await _loadData();
    await tts.speak(
      _narrate("All progress has been reset.", "அனைத்து முன்னேற்றமும் மீட்டமைக்கப்பட்டது."),
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
    final d = progress;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Progress Dashboard"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _goHome,
          ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: loading ? null : _speakSummary,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: loading || d == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _topSummaryCard(d),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.favorite, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ProgressService.buildEncouragementMessage(d),
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: "Learning",
                  value: "${d.learningCompleted}/${d.learningTotal}",
                  subtitle: "${d.learningPercent}%",
                  icon: Icons.menu_book,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  title: "Practice",
                  value: "${d.practiceAccuracyPercent}%",
                  subtitle: "Accuracy",
                  icon: Icons.track_changes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: "Challenge",
                  value: "${d.bestChallengeScore}",
                  subtitle: "Best score",
                  icon: Icons.emoji_events,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  title: "Streak",
                  value: "${d.streak}",
                  subtitle: "Days",
                  icon: Icons.local_fire_department,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionTitle("Performance Analysis"),
          const SizedBox(height: 10),
          _infoTile(
            title: "Current Level",
            value: d.level,
            icon: Icons.workspace_premium,
          ),
          _infoTile(
            title: "Strongest Topic",
            value: d.strongestTopic,
            icon: Icons.trending_up,
          ),
          _infoTile(
            title: "Needs Improvement",
            value: d.weakestTopic,
            icon: Icons.trending_down,
          ),
          _infoTile(
            title: "Last Opened Module",
            value: d.lastOpenedModule.isEmpty ? "No data yet" : d.lastOpenedModule,
            icon: Icons.history,
          ),
          _infoTile(
            title: "Last Topic",
            value: d.lastTopic.isEmpty ? "No data yet" : d.lastTopic,
            icon: Icons.topic,
          ),
          _infoTile(
            title: "Resume Learning From",
            value: "Item ${d.lastLearningIndex + 1}",
            icon: Icons.play_arrow,
          ),
          _infoTile(
            title: "Resume Practice From",
            value: "Question ${d.lastPracticeIndex + 1}",
            icon: Icons.quiz,
          ),
          _infoTile(
            title: "Resume Challenge From",
            value: "Question ${d.lastChallengeIndex + 1}",
            icon: Icons.flag,
          ),
          const SizedBox(height: 16),
          _sectionTitle("Detailed Progress"),
          const SizedBox(height: 10),
          _progressBlock(
            label: "Learning Completion",
            percent: d.learningPercent,
          ),
          const SizedBox(height: 12),
          _progressBlock(
            label: "Practice Accuracy",
            percent: d.practiceAccuracyPercent,
          ),
          const SizedBox(height: 12),
          _progressBlock(
            label: "Challenge Best Score",
            percent: d.bestChallengeScore.clamp(0, 100),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _speakSummary,
            icon: const Icon(Icons.record_voice_over),
            label: const Text("Speak Dashboard Summary"),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _resetProgress,
            icon: const Icon(Icons.delete_outline),
            label: const Text("Reset Progress"),
          ),
        ],
      ),
    );
  }

  Widget _topSummaryCard(ProgressModel d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Color(0x11000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Learning Dashboard",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            "Level: ${d.level}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You have completed ${d.learningCompleted} learning items, "
                "practice accuracy is ${d.practiceAccuracyPercent} percent, "
                "and your best challenge score is ${d.bestChallengeScore}.",
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _infoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBlock({
    required String label,
    required int percent,
  }) {
    final safePercent = percent.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: safePercent / 100,
            minHeight: 10,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 8),
          Text("$safePercent%"),
        ],
      ),
    );
  }
}