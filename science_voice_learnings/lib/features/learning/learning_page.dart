import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/accessibility/tts_service.dart';
import '../../core/voice_engine.dart';
import '../../core/progress/progress_service.dart';

import '../../data/syllabus.dart';
import '../../models/concept.dart';

import '../../widgets/braille_cell.dart';

enum LearningVoiceAction { next, previous, repeat, speak, stop, unknown }

class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  final tts = TtsService();
  final voice = VoiceEngine();

  int index = 0;
  String heard = "-";
  bool ready = false;

  ScienceConcept get item => syllabus[index];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // ✅ Normal speed (not too slow)
    await tts.init(rate: 0.50);
    final ok = await voice.init();

    if (!mounted) return;
    setState(() => ready = ok);

    // ✅ Speak intro + first item fully
    await _speakCurrent(intro: true);

    // ✅ mark streak once user enters learning module
    await ProgressService.updateDailyStreak();
  }

  LearningVoiceAction _parseAction(String words) {
    final t = words.toLowerCase();

    if (t.contains("next")) return LearningVoiceAction.next;
    if (t.contains("previous") || t.contains("back")) return LearningVoiceAction.previous;
    if (t.contains("repeat")) return LearningVoiceAction.repeat;
    if (t.contains("speak") || t.contains("read") || t.contains("hear")) return LearningVoiceAction.speak;
    if (t.contains("stop") || t.contains("cancel")) return LearningVoiceAction.stop;

    return LearningVoiceAction.unknown;
  }

  Future<void> _toggleMicForLearning() async {
    if (!ready) return;

    if (voice.listening) {
      await voice.stopListening();
      if (mounted) setState(() {});
      return;
    }

    await tts.speak(
      "Listening. Say next, previous, repeat, speak, or stop.",
      rate: 0.52,
    );

    await voice.startListening(onResult: (words) async {
      setState(() => heard = words);

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

        case LearningVoiceAction.stop:
          await tts.stop();
          await voice.stopListening();
          if (mounted) setState(() {});
          break;

        case LearningVoiceAction.unknown:
          await tts.speak("Say next, previous, repeat, speak, or stop.", rate: 0.52);
          break;
      }
    });

    if (mounted) setState(() {});
  }

  String _dotsSpoken(List<int> dots) {
    // Speak dots as: "dots 2 4 5 6"
    return "dots ${dots.join(" ")}";
  }

  Future<void> _speakCurrent({bool intro = false}) async {
    final it = item;

    final msg =
        "${intro ? "Now we are in Learning module. " : ""}"
        "Topic: ${it.category}. "
        "Question ${index + 1} of ${syllabus.length}. "
        "Symbol name: ${it.name}. "
        "This symbol holds ${_dotsSpoken(it.dots)}. "
        "Description: ${it.description}. "
        "Say next or previous to navigate. Or say repeat.";

    // ✅ Wait till completes (important for blind users)
    await tts.speakBlocking(msg, rate: 0.50);

    // ✅ Mark completed so progress updates
    await ProgressService.markLearningCompleted(it.id);
  }

  void _next() {
    if (index >= syllabus.length - 1) {
      tts.speak("This is the last symbol.", rate: 0.52);
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
      tts.speak("This is the first symbol.", rate: 0.52);
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Learning"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
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
            // ✅ Top card - shows topic + progress
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
                  Text(it.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text("Topic: ${it.category}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text("Item ${index + 1} / ${syllabus.length}", style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ✅ Braille display (not empty)
            BrailleCell(dots: it.dots),

            const SizedBox(height: 14),

            // ✅ Show print symbol + braille char
            Text(
              it.printSymbol,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
            Text(
              it.brailleChar,
              style: const TextStyle(fontSize: 34),
            ),

            const SizedBox(height: 12),

            // ✅ Description block
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

            // ✅ Heard words
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

            // ✅ Bottom navigation buttons
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
