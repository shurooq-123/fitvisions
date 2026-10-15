import '../widgets/prototype_ui.dart';
import 'package:flutter/material.dart';
import '../services/app_data_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const brown = Color(0xFF574543);

  final feedbackController = TextEditingController();
  int rating = 5;
  bool loading = false;

  Future<void> submitFeedback() async {
    final message = feedbackController.text.trim();

    if (message.isEmpty) {
      showMessage('Please write your feedback');
      return;
    }

    try {
      setState(() => loading = true);

      await AppDataService.sendFeedback(message, rating: rating);

      if (!mounted) return;

      feedbackController.clear();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Feedback Sent'),
            content: const Text('Thank you, your feedback has been sent.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/history');
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: brown),
    );
  }

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
      title: 'Feedback',
      child: Column(children: [
        PrototypePanel(
            child: Column(children: [
          const SizedBox(height: 24),
          const FittedBox(
              child:
                  Text('Rate Your Experience', style: TextStyle(fontSize: 27))),
          const SizedBox(height: 8),
          Row(
              children: List.generate(
                  5,
                  (i) => Expanded(
                      child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => setState(() => rating = i + 1),
                          icon: Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 38))))),
          const SizedBox(height: 22),
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('Write the feedback:',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 6),
          TextField(
              controller: feedbackController,
              maxLines: 7,
              maxLength: 4000,
              decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFE8EBF3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero))),
        ])),
        const SizedBox(height: 14),
        PrototypeButton(loading ? 'Sending...' : 'Submit',
            onPressed: loading ? null : submitFeedback),
        const SizedBox(height: 10),
        const Text('Your feedback helps us improve\nthe app !!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
      ]));
}
