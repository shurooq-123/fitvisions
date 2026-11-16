import '../constants/app_colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'saved_image.dart';

class HistoryPreview extends StatelessWidget {
  const HistoryPreview(this.data, {super.key});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    if (data['kind'] == 'subscription') {
      return Icon(Icons.workspace_premium, color: AppColors.accent(context));
    }
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
    return Icon(Icons.history, color: AppColors.accent(context));
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
                    if (data['kind'] == 'subscription')
                      Text(
                          "${data['plan']}\n${data['price']} OMR\nStatus: ${data['status']}\nDemo subscription • No real charge")
                    else if (data['previewBase64'] is String ||
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
