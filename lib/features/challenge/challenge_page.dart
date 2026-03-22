import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/routes.dart';
import '../../core/constants.dart';
import '../../core/accessibility/tts_service.dart';
import '../../core/voice_engine.dart';
import '../../core/answer_parser.dart';
import '../../core/progress/progress_service.dart';
import '../../core/settings/app_settings.dart';
import '../../data/syllabus.dart';
import '../../models/concept.dart';
import '../../widgets/braille_cell.dart';

enum ChallengeVoiceAction {
  hearQuestion,
  voiceAnswer,
  next,
  goHome,
  stop,
  unknown
}

class ChallengePage extends StatefulWidget {
  const ChallengePage({super.key});

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  final TtsService tts = TtsService();
  final VoiceEngine voice = VoiceEngine();
  final Random rnd = Random();

  int index = 0;
  int score = 0;
  int timeLeft = 50;
  String heard = "-";
  bool tamilMode = false;
  bool _controlsExplained = false;

  Timer? timer;

  List<ScienceConcept>? options;
  int correctIndex = 0;

  ScienceConcept get item => syllabus[index];

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
    await voice.init();
    await ProgressService.markModuleOpened("Challenge");

    _makeQuestion();
    if (mounted) setState(() {});
    _startTimer();

    await _speakQuestion(intro: true);
  }

  Future<void> _playStartBeep() async {
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> _playDoneBeep() async {
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> _stopMicIfNeeded() async {
    if (voice.listening) {
      await voice.stopListening();
      if (mounted) setState(() {});
    }
  }

  void _startTimer() {
    timer?.cancel();
    timeLeft = 50;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => timeLeft--);
      if (timeLeft <= 0) {
        t.cancel();
        _endChallenge();
      }
    });
  }

  void _makeQuestion() {
    final it = item;
    final pool = [...syllabus]..removeWhere((e) => e.id == it.id);
    pool.shuffle(rnd);

    final o = <ScienceConcept>[it, ...pool.take(3)];
    o.shuffle(rnd);

    options = o;
    correctIndex = o.indexWhere((e) => e.id == it.id);
  }

  ChallengeVoiceAction _parseAction(String words) {
    final t = words.toLowerCase();

    if (t.contains("go home") ||
        t.contains("back to home") ||
        t == "home" ||
        t.contains("move to home")) {
      return ChallengeVoiceAction.goHome;
    }

    if (t.contains("hear") || t.contains("question")) {
      return ChallengeVoiceAction.hearQuestion;
    }
    if (t.contains("answer") || t.contains("voice") || t.contains("mic")) {
      return ChallengeVoiceAction.voiceAnswer;
    }
    if (t.contains("next")) return ChallengeVoiceAction.next;
    if (t.contains("stop") || t.contains("cancel")) {
      return ChallengeVoiceAction.stop;
    }
    return ChallengeVoiceAction.unknown;
  }

  Future<void> _goHome() async {
    final speechRate = await AppSettings.getSpeechRate();
    timer?.cancel();
    await ProgressService.markModuleOpened("Home");
    await tts.speak(
      _narrate("Going to Home page.", "ஹோம் பக்கத்திற்குச் செல்கிறேன்."),
      rate: speechRate,
    );
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
  }

  Future<void> _toggleMicForActions() async {
    if (voice.listening) {
      await voice.stopListening();
      if (mounted) setState(() {});
      return;
    }

    await _playStartBeep();

    await voice.startListening(onResult: (words) async {
      if (!mounted) return;
      setState(() => heard = words);
      await _stopMicIfNeeded();
      await _playDoneBeep();

      final act = _parseAction(words);
      switch (act) {
        case ChallengeVoiceAction.hearQuestion:
          await _speakQuestion();
          break;
        case ChallengeVoiceAction.voiceAnswer:
          await _voiceAnswer();
          break;
        case ChallengeVoiceAction.next:
          _nextQuestion();
          break;
        case ChallengeVoiceAction.goHome:
          await _goHome();
          break;
        case ChallengeVoiceAction.stop:
          await tts.stop();
          break;
        case ChallengeVoiceAction.unknown:
          final speechRate = await AppSettings.getSpeechRate();
          await tts.speak(
            _narrate("Command not recognized.", "கட்டளை புரியவில்லை."),
            rate: speechRate,
          );
          break;
      }
    });

    if (mounted) setState(() {});
  }

  Future<void> _speakQuestion({bool intro = false}) async {
    final speechRate = await AppSettings.getSpeechRate();
    tamilMode = await AppSettings.getTamilMode();

    final it = item;
    final o = options;
    if (o == null || o.length != 4) return;

    final progressPercent = (((index + 1) / syllabus.length) * 100).round();

    await ProgressService.saveChallengePosition(
      index: index,
      topic: it.category,
    );

    String msg;
    if (!_controlsExplained) {
      msg = _narrate(
        "${intro ? "Now we are in Challenge module. " : ""}"
            "Question ${index + 1}. "
            "Progress is $progressPercent percent. "
            "Identify the symbol quickly. "
            "This symbol holds dots ${it.dots.join(" ")}. "
            "Options. A ${o[0].name}. B ${o[1].name}. C ${o[2].name}. D ${o[3].name}. "
            "You can say hear question, voice answer, next, or go home.",
        "${intro ? "இப்போது நாங்கள் சேலஞ்ச் பகுதியில் இருக்கிறோம். " : ""}"
            "${index + 1} ஆம் கேள்வி. "
            "முன்னேற்றம் $progressPercent சதவீதம். "
            "இந்த சின்னத்தில் ${it.dots.join(" ")} புள்ளிகள் உள்ளன. "
            "விருப்பங்கள். A ${o[0].name}. B ${o[1].name}. C ${o[2].name}. D ${o[3].name}. "
            "hear question, voice answer, next அல்லது go home சொல்லலாம்.",
      );
      _controlsExplained = true;
    } else {
      msg = _narrate(
        "Question ${index + 1}. "
            "Progress is $progressPercent percent. "
            "Identify the symbol quickly. "
            "This symbol holds dots ${it.dots.join(" ")}. "
            "Options. A ${o[0].name}. B ${o[1].name}. C ${o[2].name}. D ${o[3].name}.",
        "${index + 1} ஆம் கேள்வி. "
            "முன்னேற்றம் $progressPercent சதவீதம். "
            "இந்த சின்னத்தில் ${it.dots.join(" ")} புள்ளிகள் உள்ளன. "
            "விருப்பங்கள். A ${o[0].name}. B ${o[1].name}. C ${o[2].name}. D ${o[3].name}.",
      );
    }

    await tts.speakBlocking(msg, rate: speechRate);
    await _playDoneBeep();
  }

  Future<void> _voiceAnswer() async {
    final speechRate = await AppSettings.getSpeechRate();
    await _playStartBeep();

    await voice.startListening(onResult: (words) async {
      if (!mounted) return;
      setState(() => heard = words);
      await _stopMicIfNeeded();
      await _playDoneBeep();

      final idx = AnswerParser.optionIndex(words);
      if (idx == null || idx < 0 || idx > 3) {
        await tts.speak(
          _narrate(
            "Say option A, B, C or D.",
            "option A, B, C அல்லது D என்று சொல்லுங்கள்.",
          ),
          rate: speechRate,
        );
        return;
      }
      await _checkAnswer(idx);
    });
  }

  Future<void> _checkAnswer(int chosen) async {
    final speechRate = await AppSettings.getSpeechRate();
    tamilMode = await AppSettings.getTamilMode();

    final o = options!;
    final isCorrect = chosen == correctIndex;

    if (isCorrect) {
      score += 1;
      await tts.speak(
        _narrate("Correct.", "சரி."),
        rate: speechRate,
      );
    } else {
      await tts.speak(
        _narrate(
          "Wrong. Correct is ${o[correctIndex].name}.",
          "தவறு. சரியான பதில் ${o[correctIndex].name}.",
        ),
        rate: speechRate,
      );
    }

    await Future.delayed(const Duration(milliseconds: 600));
    _nextQuestion();
  }

  void _nextQuestion() {
    if (!mounted) return;

    if (index < syllabus.length - 1) {
      setState(() {
        index++;
        heard = "-";
        _makeQuestion();
      });
      _startTimer();
      _speakQuestion();
    } else {
      _endChallenge();
    }
  }

  Future<void> _endChallenge() async {
    final speechRate = await AppSettings.getSpeechRate();
    tamilMode = await AppSettings.getTamilMode();

    timer?.cancel();

    final percent =
    syllabus.isEmpty ? 0 : ((score / syllabus.length) * 100).round();

    await ProgressService.addChallengeScore(
      score: percent,
      topic: item.category,
    );

    if (!mounted) return;
    await tts.speakBlocking(
      _narrate(
        "Challenge completed. Your score is $score out of ${syllabus.length}. Percentage is $percent.",
        "சேலஞ்ச் முடிந்தது. உங்கள் மதிப்பெண் ${syllabus.length} இல் $score. சதவீதம் $percent.",
      ),
      rate: speechRate,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    timer?.cancel();
    tts.stop();
    voice.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final it = item;
    final o = options;
    final progressValue = (index + 1) / syllabus.length;

    if (o == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Challenge"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _goHome,
          ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () => _speakQuestion(),
          ),
          IconButton(
            icon: Icon(voice.listening ? Icons.mic_off : Icons.mic),
            onPressed: _toggleMicForActions,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _pill("Time: $timeLeft")),
                const SizedBox(width: 10),
                Expanded(child: _pill("Score: $score")),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 14),
            const Text(
              "Identify this Braille symbol quickly!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            BrailleCell(dots: it.dots),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _speakQuestion(),
                  icon: const Icon(Icons.volume_up),
                  label: const Text("Hear Question"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _voiceAnswer,
                  icon: const Icon(Icons.mic),
                  label: const Text("Voice Answer"),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text("Heard: $heard"),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < o.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _checkAnswer(i),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      "${String.fromCharCode(65 + i)}. ${o[i].name}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}