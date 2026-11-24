import '../services/app_language.dart';
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
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => StreamBuilder<Map<String, dynamic>?>(
            stream: AppDataService.subscriptionStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return AppText(showPayment
                    ? 'Could not load payment details.'
                    : 'Could not load subscription.');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final sub = snapshot.data;
              if (sub == null) {
                return Column(children: [
                  AppText(showPayment
                      ? 'No payment for an active subscription'
                      : 'No active subscription'),
                  if (onChoosePlan != null)
                    TextButton(
                        onPressed: onChoosePlan,
                        child: const AppText('Choose a subscription')),
                ]);
              }
              final locale = MaterialLocalizations.of(context);
              String timestamp(String key) {
                final date = (sub[key] as DateTime).toLocal();
                final time = locale.formatTimeOfDay(
                    TimeOfDay.fromDateTime(date),
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
                      const AppText('Demo payment completed',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      AppText('${sub['plan']}'),
                      AppText('Amount: ${sub['amount']} OMR'),
                      AppText('Payment date: ${timestamp('startsAt')}',
                          textAlign: TextAlign.center),
                      const AppText('No real charge',
                          style: TextStyle(fontSize: 12)),
                    ]));
              }

              return PrototypePanel(
                  radius: 24,
                  child: Column(children: [
                    Icon(Icons.workspace_premium,
                        color: AppColors.accent(context)),
                    AppText('${sub['plan']}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    AppText(
                        '${SubscriptionAccess.planMonths(sub)} ${tr('Months')}'),
                    const SizedBox(height: 8),
                    AppText('Expires on: ${timestamp('expiresAt')}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    AppText(
                        '${((sub['expiresAt'] as DateTime).difference(DateTime.now()).inSeconds / 86400).ceil().clamp(0, 99999)} ${tr('days remaining')}',
                        style: TextStyle(
                            color: AppColors.accent(context),
                            fontWeight: FontWeight.w600)),
                  ]));
            },
          ));
}
