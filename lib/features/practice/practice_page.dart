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

enum PracticeVoiceAction {
  hearQuestion,
  voiceAnswer,
  next,
  previous,
  repeat,
  goHome,
  stop,
  unknown
}

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  final TtsService tts = TtsService();
  final VoiceEngine voice = VoiceEngine();
  final Random rnd = Random();

  int index = 0;
  String heard = "-";
  int answeredCount = 0;
  int correctCount = 0;
  bool tamilMode = false;
  bool _controlsExplained = false;

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
    await ProgressService.markModuleOpened("Practice");

    _makeQuestion();
    if (mounted) setState(() {});
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

    if (t.contains("go home") ||
        t.contains("back to home") ||
        t == "home" ||
        t.contains("move to home")) {
      return PracticeVoiceAction.goHome;
    }

    if (t.contains("hear") || t.contains("question")) {
      return PracticeVoiceAction.hearQuestion;
    }
    if (t.contains("answer") || t.contains("mic") || t.contains("voice")) {
      return PracticeVoiceAction.voiceAnswer;
    }
    if (t.contains("next")) return PracticeVoiceAction.next;
    if (t.contains("previous") || t.contains("back")) {
      return PracticeVoiceAction.previous;
    }
    if (t.contains("repeat")) return PracticeVoiceAction.repeat;
    if (t.contains("stop") || t.contains("cancel")) {
      return PracticeVoiceAction.stop;
    }
    return PracticeVoiceAction.unknown;
  }

  Future<void> _goHome() async {
    final speechRate = await AppSettings.getSpeechRate();
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

        case PracticeVoiceAction.goHome:
          await _goHome();
          break;

        case PracticeVoiceAction.stop:
          await tts.stop();
          break;

        case PracticeVoiceAction.unknown:
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

    await ProgressService.savePracticePosition(
      index: index,
      topic: it.category,
    );

    String msg;
    if (!_controlsExplained) {
      msg = _narrate(
        "${intro ? "Now we are in Practice module. " : ""}"
            "Topic: ${it.category}. "
            "Question ${index + 1} of ${syllabus.length}. "
            "Progress is $progressPercent percent. "
            "Identify the symbol using braille dots. "
            "This symbol holds dots ${it.dots.join(" ")}. "
            "Theory: ${it.description}. "
            "Options are. Option A: ${o[0].name}. Option B: ${o[1].name}. Option C: ${o[2].name}. Option D: ${o[3].name}. "
            "You can say hear question, voice answer, next, previous, repeat, or go home.",
        "${intro ? "இப்போது நாங்கள் பிராக்டிஸ் பகுதியில் இருக்கிறோம். " : ""}"
            "தலைப்பு ${it.category}. "
            "${index + 1} ஆம் கேள்வி, மொத்தம் ${syllabus.length}. "
            "முன்னேற்றம் $progressPercent சதவீதம். "
            "இந்த சின்னத்தில் ${it.dots.join(" ")} புள்ளிகள் உள்ளன. "
            "விளக்கம் ${it.description}. "
            "விருப்பங்கள். A ${o[0].name}. B ${o[1].name}. C ${o[2].name}. D ${o[3].name}. "
            "hear question, voice answer, next, previous, repeat அல்லது go home சொல்லலாம்.",
      );
      _controlsExplained = true;
    } else {
      msg = _narrate(
        "Topic: ${it.category}. "
            "Question ${index + 1} of ${syllabus.length}. "
            "Progress is $progressPercent percent. "
            "Identify the symbol using braille dots. "
            "This symbol holds dots ${it.dots.join(" ")}. "
            "Theory: ${it.description}. "
            "Options are. Option A: ${o[0].name}. Option B: ${o[1].name}. Option C: ${o[2].name}. Option D: ${o[3].name}.",
        "தலைப்பு ${it.category}. "
            "${index + 1} ஆம் கேள்வி, மொத்தம் ${syllabus.length}. "
            "முன்னேற்றம் $progressPercent சதவீதம். "
            "இந்த சின்னத்தில் ${it.dots.join(" ")} புள்ளிகள் உள்ளன. "
            "விளக்கம் ${it.description}. "
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
            "Please say option A, B, C or D.",
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

    answeredCount += 1;
    if (isCorrect) {
      correctCount += 1;
    }

    await ProgressService.addPracticeResult(
      correct: isCorrect ? 1 : 0,
      total: 1,
      topic: item.category,
    );

    if (isCorrect) {
      await tts.speak(
        _narrate("Correct answer.", "சரியான பதில்."),
        rate: speechRate,
      );
    } else {
      await tts.speak(
        _narrate(
          "Wrong answer. Correct answer is ${o[correctIndex].name}.",
          "தவறான பதில். சரியான பதில் ${o[correctIndex].name}.",
        ),
        rate: speechRate,
      );
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
    } else {
      tts.speak(
        _narrate(
          "This is the last practice question.",
          "இது கடைசி பிராக்டிஸ் கேள்வி.",
        ),
        rate: 0.52,
      );
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
    } else {
      tts.speak(
        _narrate(
          "This is the first practice question.",
          "இது முதல் பிராக்டிஸ் கேள்வி.",
        ),
        rate: 0.52,
      );
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
    final progressValue = (index + 1) / syllabus.length;
    final accuracy =
    answeredCount == 0 ? 0 : ((correctCount / answeredCount) * 100).round();

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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Topic: ${it.category}",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text("Question ${index + 1} / ${syllabus.length}"),
                  const SizedBox(height: 6),
                  Text("Accuracy: $accuracy%"),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Identify this Braille symbol!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("Previous"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _next,
                    child: const Text("Next"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}