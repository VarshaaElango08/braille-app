import 'package:flutter/material.dart';
import '../core/constants.dart';

class BrailleCell extends StatelessWidget {
  final List<int> dots; // 1..6

  const BrailleCell({super.key, required this.dots});

  bool _filled(int n) => dots.contains(n);

  @override
  Widget build(BuildContext context) {
    Widget dot(int n) {
      return Column(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: _filled(n) ? AppColors.primary : const Color(0xFFE5E7EF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 6),
          Text("$n", style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Color(0x11000000))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(children: [dot(1), const SizedBox(height: 10), dot(2), const SizedBox(height: 10), dot(3)]),
          const SizedBox(width: 14),
          Column(children: [dot(4), const SizedBox(height: 10), dot(5), const SizedBox(height: 10), dot(6)]),
        ],
      ),
    );
  }
}
