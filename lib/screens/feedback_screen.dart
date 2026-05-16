import 'package:flutter/material.dart';
import '../services/app_data_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);

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

      await AppDataService.sendFeedback('Rating: $rating\n$message');

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 55),
                  const Text(
                    'Feedback',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: 295,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(45),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Rate Your Experience',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              onPressed: () {
                                setState(() => rating = index + 1);
                              },
                              icon: Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 34,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Write the feedback:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: feedbackController,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFEFF3FF),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 145,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: loading ? null : submitFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brown,
                            ),
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Submit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}