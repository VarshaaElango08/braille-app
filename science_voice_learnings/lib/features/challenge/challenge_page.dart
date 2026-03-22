import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/accessibility/tts_service.dart';
import '../../core/voice_engine.dart';
import '../../core/answer_parser.dart';
import '../../core/progress/progress_service.dart';
import '../../data/syllabus.dart';
import '../../models/concept.dart';
import '../../widgets/braille_cell.dart';

enum ChallengeVoiceAction { hearQuestion, voiceAnswer, next, stop, unknown }

class ChallengePage extends StatefulWidget {
  const ChallengePage({super.key});

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  final tts = TtsService();
  final voice = VoiceEngine();
  final rnd = Random();

  int index = 0;
  int score = 0;
  int timeLeft = 50;

  Timer? timer;

  List<ScienceConcept>? options; // ✅ NOT late
  int correctIndex = 0;
  String heard = "-";

  ScienceConcept get item => syllabus[index];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await tts.init(rate: 0.52);
    await voice.init();

    _makeQuestion();
    if (mounted) setState(() {});
    _startTimer();

    await _speakQuestion(intro: true);
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
    if (t.contains("hear") || t.contains("question")) return ChallengeVoiceAction.hearQuestion;
    if (t.contains("answer") || t.contains("voice") || t.contains("mic")) return ChallengeVoiceAction.voiceAnswer;
    if (t.contains("next")) return ChallengeVoiceAction.next;
    if (t.contains("stop") || t.contains("cancel")) return ChallengeVoiceAction.stop;
    return ChallengeVoiceAction.unknown;
  }

  Future<void> _toggleMicForActions() async {
    if (voice.listening) {
      await voice.stopListening();
      if (mounted) setState(() {});
      return;
    }

    await tts.speak("Listening. Say: hear question, voice answer, next, or stop.", rate: 0.54);

    await voice.startListening(onResult: (words) async {
      setState(() => heard = words);

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
        case ChallengeVoiceAction.stop:
          await tts.stop();
          await voice.stopListening();
          if (mounted) setState(() {});
          break;
        case ChallengeVoiceAction.unknown:
          await tts.speak("Say: hear question, voice answer, next, or stop.", rate: 0.54);
          break;
      }
    });

    if (mounted) setState(() {});
  }

  Future<void> _speakQuestion({bool intro = false}) async {
    final it = item;
    final o = options;
    if (o == null || o.length != 4) return;

    final msg =
        "${intro ? "Now we are in Challenge module. " : ""}"
        "Question ${index + 1}. Identify the symbol quickly. "
        "This symbol holds dots ${it.dots.join(" ")}. "
        "Options. A ${o[0].name}. B ${o[1].name}. C ${o[2].name}. D ${o[3].name}. "
        "Say option A, B, C or D.";

    await tts.speak(msg, rate: 0.54);
  }

  Future<void> _voiceAnswer() async {
    final o = options;
    if (o == null) return;

    await tts.speak("Listening for your answer.", rate: 0.54);

    await voice.startListening(onResult: (words) async {
      setState(() => heard = words);

      final idx = AnswerParser.optionIndex(words);
      if (idx == null || idx < 0 || idx > 3) {
        await tts.speak("Say option A, B, C or D.", rate: 0.54);
        return;
      }
      await _checkAnswer(idx);
    });
  }

  Future<void> _checkAnswer(int chosen) async {
    final o = options!;
    final isCorrect = chosen == correctIndex;

    if (isCorrect) {
      score += 1;
      await tts.speak("Correct.", rate: 0.56);
    } else {
      await tts.speak("Wrong. Correct is ${o[correctIndex].name}.", rate: 0.56);
    }

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
    timer?.cancel();
    await ProgressService.updateBestChallengeScore(score);

    if (!mounted) return;
    await tts.speakBlocking("Challenge completed. Your score is $score.", rate: 0.52);
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

    if (o == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Challenge"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.volume_up), onPressed: () => _speakQuestion()),
          IconButton(icon: Icon(voice.listening ? Icons.mic_off : Icons.mic), onPressed: _toggleMicForActions),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _pill("Time: $timeLeft"),
                const SizedBox(width: 10),
                _pill("Score: $score"),
              ],
            ),
            const SizedBox(height: 14),
            const Text("Identify this Braille symbol quickly!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
