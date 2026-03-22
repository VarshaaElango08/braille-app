import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../core/constants.dart';
import '../../core/accessibility/tts_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final tts = TtsService();

  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await tts.init(rate: 0.50); // ✅ normal speed, not too slow

    // speak fully, then move
    await tts.speakBlocking(
      "Welcome to Science Voice Learning App. "
          "This app is designed for blind learners. "
          "You can learn, practice, and challenge using voice.",
      rate: 0.48,
    );

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.hearing, size: 72, color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              "Science Voice Learning",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10),
            Text("Loading…", style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
