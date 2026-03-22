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

enum PracticeVoiceAction { hearQuestion, voiceAnswer, next, previous, repeat, stop, unknown }

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  final tts = TtsService();
  final voice = VoiceEngine();
  final rnd = Random();

  int index = 0;
  String heard = "-";

  List<ScienceConcept>? options; // ✅ NOT late
  int correctIndex = 0;

  ScienceConcept get item => syllabus[index];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await tts.init(rate: 0.50);
    await voice.init();

    _makeQuestion(); // ✅ makes options immediately
    if (mounted) setState(() {});
    await _speakQuestion(intro: true);
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

  PracticeVoiceAction _parseAction(String words) {
    final t = words.toLowerCase();
    if (t.contains("hear") || t.contains("question")) return PracticeVoiceAction.hearQuestion;
    if (t.contains("answer") || t.contains("mic") || t.contains("voice")) return PracticeVoiceAction.voiceAnswer;
    if (t.contains("next")) return PracticeVoiceAction.next;
    if (t.contains("previous") || t.contains("back")) return PracticeVoiceAction.previous;
    if (t.contains("repeat")) return PracticeVoiceAction.repeat;
    if (t.contains("stop") || t.contains("cancel")) return PracticeVoiceAction.stop;
    return PracticeVoiceAction.unknown;
  }

  Future<void> _toggleMicForActions() async {
    if (voice.listening) {
      await voice.stopListening();
      if (mounted) setState(() {});
      return;
    }

    await tts.speak("Listening. Say: hear question, voice answer, next, previous, or repeat.", rate: 0.52);

    await voice.startListening(onResult: (words) async {
      setState(() => heard = words);

      final act = _parseAction(words);
      switch (act) {
        case PracticeVoiceAction.hearQuestion:
        case PracticeVoiceAction.repeat:
          await _speakQuestion();
          break;

        case PracticeVoiceAction.voiceAnswer:
          await _voiceAnswer();
          break;

        case PracticeVoiceAction.next:
          _next();
          break;

        case PracticeVoiceAction.previous:
          _prev();
          break;

        case PracticeVoiceAction.stop:
          await tts.stop();
          await voice.stopListening();
          if (mounted) setState(() {});
          break;

        case PracticeVoiceAction.unknown:
          await tts.speak("Say: hear question, voice answer, next, previous, or repeat.", rate: 0.52);
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
        "${intro ? "Now we are in Practice module. " : ""}"
        "Topic: ${it.category}. "
        "Question ${index + 1} of ${syllabus.length}. "
        "Identify the symbol using braille dots. "
        "This symbol holds dots ${it.dots.join(" ")}. "
        "Theory: ${it.description}. "
        "Options are. Option A: ${o[0].name}. Option B: ${o[1].name}. Option C: ${o[2].name}. Option D: ${o[3].name}. "
        "Say option A, B, C, or D.";

    await tts.speakBlocking(msg, rate: 0.50);
  }

  Future<void> _voiceAnswer() async {
    final o = options;
    if (o == null) return;

    await tts.speak("Listening for your answer. Say option A, B, C or D.", rate: 0.52);

    await voice.startListening(onResult: (words) async {
      setState(() => heard = words);

      final idx = AnswerParser.optionIndex(words);
      if (idx == null || idx < 0 || idx > 3) {
        await tts.speak("Please say option A, B, C or D.", rate: 0.52);
        return;
      }

      await _checkAnswer(idx);
    });
  }

  Future<void> _checkAnswer(int chosen) async {
    final o = options!;
    final isCorrect = chosen == correctIndex;

    await ProgressService.recordPracticeAttempt(correct: isCorrect);

    if (isCorrect) {
      await tts.speak("Correct answer.", rate: 0.54);
    } else {
      await tts.speak("Wrong answer. Correct answer is ${o[correctIndex].name}.", rate: 0.54);
    }
  }

  void _next() {
    if (index < syllabus.length - 1) {
      setState(() {
        index++;
        heard = "-";
        _makeQuestion();
      });
      _speakQuestion();
    }
  }

  void _prev() {
    if (index > 0) {
      setState(() {
        index--;
        heard = "-";
        _makeQuestion();
      });
      _speakQuestion();
    }
  }

  @override
  void dispose() {
    tts.stop();
    voice.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final it = item;
    final o = options;

    // ✅ Loader until ready (prevents red screen)
    if (o == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Practice"),
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
            const Text("Identify this Braille symbol!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),

            BrailleCell(dots: it.dots),
            const SizedBox(height: 10),

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

            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _prev,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    child: const Text("Previous"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(onPressed: _next, child: const Text("Next")),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
