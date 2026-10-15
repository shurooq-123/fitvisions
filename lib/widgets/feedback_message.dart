import 'package:flutter/material.dart';

class FeedbackMessage extends StatelessWidget {
  const FeedbackMessage(this.data, {super.key});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final raw = data['rating'];
    final rating =
        (raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0).clamp(0, 5);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
          color: Color(0xFFF4F4F4),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
              bottomLeft: Radius.circular(5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.chat_bubble_outline, color: Color(0xFF51227D)),
          const SizedBox(width: 10),
          Expanded(
              child: Text('${data['email'] ?? 'User'}',
                  style: const TextStyle(fontWeight: FontWeight.bold)))
        ]),
        const SizedBox(height: 10),
        Semantics(
            label: '$rating out of 5 stars',
            child: Row(
                children: List.generate(
                    5,
                    (i) => Icon(i < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber, size: 24)))),
        const SizedBox(height: 12),
        Text('${data['message'] ?? ''}',
            style: const TextStyle(fontSize: 15, height: 1.5)),
      ]),
    );
  }
}
