import 'dart:convert';
import 'package:flutter/material.dart';
import 'saved_image.dart';

class HistoryPreview extends StatelessWidget {
  const HistoryPreview(this.data, {super.key});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final encoded = data['previewBase64'];
    if (encoded is String && encoded.isNotEmpty) {
      try {
        return Image.memory(base64Decode(encoded),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image_outlined));
      } catch (_) {
        return const Icon(Icons.broken_image_outlined);
      }
    }
    if (data['imagePath'] is String) return SavedImage(data['imagePath']);
    return const Icon(Icons.history, color: Color(0xFF51227D));
  }
}

void showHistoryResult(BuildContext context, Map<String, dynamic> data) {
  showDialog(
      context: context,
      builder: (_) => AlertDialog(
            title: Text('${data['title'] ?? 'Activity'}'),
            content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data['previewBase64'] is String ||
                        data['imagePath'] is String) ...[
                      SizedBox(height: 330, child: HistoryPreview(data)),
                      const Text('Saved preview'),
                    ] else
                      const Text('No saved image for this older activity.'),
                  ],
                ))),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'))
            ],
          ));
}
