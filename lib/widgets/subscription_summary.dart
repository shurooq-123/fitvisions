import '../constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../services/app_data_service.dart';
import '../services/subscription_access.dart';
import 'prototype_ui.dart';

class SubscriptionSummary extends StatelessWidget {
  const SubscriptionSummary(
      {super.key, this.showPayment = false, this.onChoosePlan});

  final bool showPayment;
  final VoidCallback? onChoosePlan;
  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>?>(
        stream: AppDataService.subscriptionStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(showPayment
                ? 'Could not load payment details.'
                : 'Could not load subscription.');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          final sub = snapshot.data;
          if (sub == null) {
            return Column(children: [
              Text(showPayment
                  ? 'No payment for an active subscription'
                  : 'No active subscription'),
              if (onChoosePlan != null)
                TextButton(
                    onPressed: onChoosePlan,
                    child: const Text('Choose a subscription')),
            ]);
          }
          final locale = MaterialLocalizations.of(context);
          String timestamp(String key) {
            final date = (sub[key] as DateTime).toLocal();
            final time = locale.formatTimeOfDay(TimeOfDay.fromDateTime(date),
                alwaysUse24HourFormat:
                    MediaQuery.alwaysUse24HourFormatOf(context));
            return '${locale.formatFullDate(date)} • $time';
          }

          if (showPayment) {
            return PrototypePanel(
                radius: 24,
                child: Column(children: [
                  Icon(Icons.check_circle_outline,
                      color: AppColors.accent(context)),
                  const Text('Demo payment completed',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('${sub['plan']}'),
                  Text('Amount: ${sub['amount']} OMR'),
                  Text('Payment date: ${timestamp('startsAt')}',
                      textAlign: TextAlign.center),
                  const Text('No real charge', style: TextStyle(fontSize: 12)),
                ]));
          }

          return PrototypePanel(
              radius: 24,
              child: Column(children: [
                Icon(Icons.workspace_premium, color: AppColors.accent(context)),
                Text('${sub['plan']}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Active demo subscription • ${sub['amount']} OMR'),
                Text(SubscriptionAccess.months(sub['amount'] as num) == 1
                    ? 'Duration: 1 month'
                    : 'Duration: 6 months'),
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
