import '../widgets/prototype_ui.dart';
import 'package:flutter/material.dart';
import '../services/app_data_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, this.saveRequest});
  final Future<void> Function(String)? saveRequest;
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool loading = false;
  Future<void> submit(String? subscriptionId) async {
    if (loading || subscriptionId == null) return;
    setState(() => loading = true);
    try {
      if (widget.saveRequest != null) {
        await widget.saveRequest!(subscriptionId);
      } else {
        await AppDataService.savePayment(subscriptionId: subscriptionId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Request saved. No money has been charged.')));
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args?['returnToDesign'] == true) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacementNamed(context, '/feedback');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save the request. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final subscriptionId = args?['subscriptionId'] as String?;
    return PrototypePage(
        title: 'Payment',
        child: Column(children: [
          PrototypePanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Image.asset('images/fv3.png',
                    height: 65, width: double.infinity, fit: BoxFit.cover),
                const SizedBox(height: 12),
                const Center(
                    child: Text('Demo payment • No real charge',
                        style: TextStyle(fontSize: 12))),
                const SizedBox(height: 22),
                demoField('Card Holder Name', 'John Doe'),
                demoField('Card Number', '000 000 000 00'),
                Row(children: [
                  Expanded(child: demoField('Expiry Date', '04/28')),
                  const SizedBox(width: 24),
                  Expanded(child: demoField('CVV', '0000'))
                ]),
              ])),
          const SizedBox(height: 24),
          const Text(
              'No money will be charged. Sample card details are for display only.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12)),
          const SizedBox(height: 20),
          PrototypeButton(
              loading
                  ? 'Saving...'
                  : subscriptionId == null
                      ? 'Choose subscription'
                      : 'Pay',
              onPressed: loading
                  ? null
                  : subscriptionId == null
                      ? () => Navigator.pushReplacementNamed(
                          context, '/subscription')
                      : () => submit(subscriptionId)),
        ]));
  }

  Widget demoField(String label, String sample) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label),
        const SizedBox(height: 7),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                color: const Color(0xFFEDF0FF),
                border: Border.all(color: Colors.black54),
                borderRadius: BorderRadius.circular(22)),
            child: Text(sample, style: const TextStyle(color: Colors.black54)))
      ]));
}
