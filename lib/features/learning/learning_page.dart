import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../core/constants.dart';
import '../../core/accessibility/tts_service.dart';
import '../../core/voice_engine.dart';
import '../../core/progress/progress_service.dart';
import '../../core/settings/app_settings.dart';

import '../../data/syllabus.dart';
import '../../models/concept.dart';

import '../../widgets/braille_cell.dart';

enum LearningVoiceAction {
  next,
  previous,
  repeat,
  speak,
  goHome,
  stop,
  unknown
}

class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  final TtsService tts = TtsService();
  final VoiceEngine voice = VoiceEngine();

  int index = 0;
  String heard = "-";
  bool ready = false;
  bool tamilMode = false;
  final Set<String> completedIds = {};
  bool _controlsExplained = false;

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
    final ok = await voice.init();

    await ProgressService.markModuleOpened("Learning");

    if (!mounted) return;
    setState(() => ready = ok);

    await _speakCurrent(intro: true);
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

  LearningVoiceAction _parseAction(String words) {
    final t = words.toLowerCase();

    if (t.contains("go home") ||
        t.contains("back to home") ||
        t == "home" ||
        t.contains("move to home")) {
      return LearningVoiceAction.goHome;
    }

    if (t.contains("next")) return LearningVoiceAction.next;
    if (t.contains("previous") || t.contains("back")) {
      return LearningVoiceAction.previous;
    }
    if (t.contains("repeat")) return LearningVoiceAction.repeat;
    if (t.contains("speak") || t.contains("read") || t.contains("hear")) {
      return LearningVoiceAction.speak;
    }
    if (t.contains("stop") || t.contains("cancel")) {
      return LearningVoiceAction.stop;
    }

    return LearningVoiceAction.unknown;
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

  Future<void> _toggleMicForLearning() async {
    if (!ready) return;

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
        case LearningVoiceAction.next:
          _next();
          break;

        case LearningVoiceAction.previous:
          _prev();
          break;

        case LearningVoiceAction.repeat:
        case LearningVoiceAction.speak:
          await _speakCurrent();
          break;

        case LearningVoiceAction.goHome:
          await _goHome();
          break;

        case LearningVoiceAction.stop:
          await tts.stop();
          break;

        case LearningVoiceAction.unknown:
          final speechRate = await AppSettings.getSpeechRate();
          await tts.speak(
            _narrate(
              "Command not recognized.",
              "கட்டளை புரியவில்லை.",
            ),
            rate: speechRate,
          );
          break;
      }
    });

    if (mounted) setState(() {});
  }

  String _dotsSpoken(List<int> dots) {
    return "dots ${dots.join(" ")}";
  }

  Future<void> _markCurrentAsCompleted() async {
    final id = item.id.toString();
    if (completedIds.contains(id)) return;

    completedIds.add(id);

    await ProgressService.markLearningComplete(
      topic: item.category,
      totalLessons: syllabus.length,
    );
  }

  Future<void> _speakCurrent({bool intro = false}) async {
    final speechRate = await AppSettings.getSpeechRate();
    tamilMode = await AppSettings.getTamilMode();

    final it = item;
    final progressPercent = (((index + 1) / syllabus.length) * 100).round();

    await ProgressService.saveLearningPosition(
      index: index,
      topic: it.category,
    );

    String msg;

    if (!_controlsExplained) {
      msg = _narrate(
        "${intro ? "Now we are in Learning module. " : ""}"
            "Topic: ${it.category}. "
            "Question ${index + 1} of ${syllabus.length}. "
            "Progress is $progressPercent percent. "
            "Symbol name: ${it.name}. "
            "This symbol holds ${_dotsSpoken(it.dots)}. "
            "Description: ${it.description}. "
            "You can say next, previous, repeat, or go home.",
        "${intro ? "இப்போது நாங்கள் லெர்னிங் பகுதியில் இருக்கிறோம். " : ""}"
            "தலைப்பு ${it.category}. "
            "${index + 1} ஆம் பொருள், மொத்தம் ${syllabus.length}. "
            "முன்னேற்றம் $progressPercent சதவீதம். "
            "சின்னத்தின் பெயர் ${it.name}. "
            "இந்த சின்னத்தில் ${_dotsSpoken(it.dots)} உள்ளது. "
            "விளக்கம் ${it.description}. "
            "next, previous, repeat அல்லது go home சொல்லலாம்.",
      );
      _controlsExplained = true;
    } else {
      msg = _narrate(
        "Topic: ${it.category}. "
            "Question ${index + 1} of ${syllabus.length}. "
            "Progress is $progressPercent percent. "
            "Symbol name: ${it.name}. "
            "This symbol holds ${_dotsSpoken(it.dots)}. "
            "Description: ${it.description}.",
        "தலைப்பு ${it.category}. "
            "${index + 1} ஆம் பொருள், மொத்தம் ${syllabus.length}. "
            "முன்னேற்றம் $progressPercent சதவீதம். "
            "சின்னத்தின் பெயர் ${it.name}. "
            "இந்த சின்னத்தில் ${_dotsSpoken(it.dots)} உள்ளது. "
            "விளக்கம் ${it.description}.",
      );
    }

    await tts.speakBlocking(msg, rate: speechRate);
    await _playDoneBeep();
    await _markCurrentAsCompleted();
  }

  void _next() {
    if (index >= syllabus.length - 1) {
      tts.speak(
        _narrate("This is the last symbol.", "இது கடைசி சின்னம்."),
        rate: 0.52,
      );
      return;
    }

    setState(() {
      index++;
      heard = "-";
    });

    _speakCurrent();
  }

  void _prev() {
    if (index <= 0) {
      tts.speak(
        _narrate("This is the first symbol.", "இது முதல் சின்னம்."),
        rate: 0.52,
      );
      return;
    }

    setState(() {
      index--;
      heard = "-";
    });

    _speakCurrent();
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
    final progressValue = (index + 1) / syllabus.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Learning"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _goHome,
          ),
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: _speakCurrent,
          ),
          IconButton(
            icon: Icon(voice.listening ? Icons.mic_off : Icons.mic),
            onPressed: ready ? _toggleMicForLearning : null,
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
                    it.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Topic: ${it.category}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Item ${index + 1} / ${syllabus.length}",
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 6),
                  Text("${(progressValue * 100).round()}% completed"),
                ],
              ),
            ),
            const SizedBox(height: 18),
            BrailleCell(dots: it.dots),
            const SizedBox(height: 14),
            Text(
              it.printSymbol,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
            Text(
              it.brailleChar,
              style: const TextStyle(fontSize: 34),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Description: ${it.description}\nDots: ${it.dots.join(", ")}",
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text("Heard: $heard"),
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
                    onPressed: _speakCurrent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("Repeat"),
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