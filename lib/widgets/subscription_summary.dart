import 'package:flutter/material.dart';
import '../services/app_data_service.dart';
import 'prototype_ui.dart';

class SubscriptionSummary extends StatelessWidget {
  const SubscriptionSummary({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>?>(
        stream: AppDataService.subscriptionStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Could not load subscription.');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          final sub = snapshot.data;
          if (sub == null) return const Text('No active subscription');
          final locale = MaterialLocalizations.of(context);
          String timestamp(String key) {
            final date = (sub[key] as DateTime).toLocal();
            final time = locale.formatTimeOfDay(TimeOfDay.fromDateTime(date),
                alwaysUse24HourFormat:
                    MediaQuery.alwaysUse24HourFormatOf(context));
            return '${locale.formatFullDate(date)} • $time';
          }

          return PrototypePanel(
              radius: 24,
              child: Column(children: [
                const Icon(Icons.workspace_premium, color: Color(0xFF51227D)),
                Text('${sub['plan']}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Active demo subscription • ${sub['amount']} OMR'),
                Text('Subscribed on: ${timestamp('startsAt')}',
                    textAlign: TextAlign.center),
                Text('Expires on: ${timestamp('expiresAt')}',
                    textAlign: TextAlign.center),
                const Text('Includes Generate Avatar and Design Clothes',
                    textAlign: TextAlign.center),
                const Text('No automatic renewal • No real charge',
                    style: TextStyle(fontSize: 12)),
              ]));
        },
      );
}
