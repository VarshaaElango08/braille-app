import 'package:flutter/material.dart';

class VoiceHint extends StatelessWidget {
  final String text;
  const VoiceHint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.record_voice_over),
        title: Text(text),
      ),
    );
  }
}
