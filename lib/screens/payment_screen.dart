import '../widgets/prototype_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_data_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, this.saveRequest});
  final Future<void> Function(String)? saveRequest;
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static final nameCharacters = RegExp(r'^[\p{L}\p{M} ]*$', unicode: true);
  static final hasLetter = RegExp(r'\p{L}', unicode: true);
  static final positiveDigits = RegExp(r'^[1-9]*$');

  bool loading = false;
  final form = GlobalKey<FormState>();
  final holder = TextEditingController();
  final number = TextEditingController();
  final expiry = TextEditingController();
  final cvv = TextEditingController();
  DateTime? selectedExpiry;

  Future<void> pickExpiry() async {
    if (loading) return;
    final now = DateTime.now();
    final first = DateTime(now.year, now.month + 1);
    final previous = selectedExpiry;
    final date = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: DateTime(2099, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDate:
          previous != null && !previous.isBefore(first) ? previous : first,
      helpText: 'Choose expiry month and year',
    );
    if (!mounted || date == null) return;
    selectedExpiry = date;
    final month = date.month.toString().padLeft(2, '0');
    final year = (date.year % 100).toString().padLeft(2, '0');
    expiry.text = '$month/$year';
  }

  @override
  void dispose() {
    holder.dispose();
    number.dispose();
    expiry.dispose();
    cvv.dispose();
    super.dispose();
  }

  Future<void> submit(String? subscriptionId) async {
    if (loading || subscriptionId == null) return;
    if (!(form.currentState?.validate() ?? false)) return;
    setState(() => loading = true);
    try {
      if (widget.saveRequest != null) {
        await widget.saveRequest!(subscriptionId);
      } else {
        await AppDataService.savePayment(subscriptionId: subscriptionId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Demo subscription activated. No money has been charged.')));
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args?['returnToSubscription'] == true ||
          args?['returnToDesign'] == true) {
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
    final plan = args?['plan'] as String?;
    final price = args?['price'] as num?;
    return PrototypePage(
        title: 'Payment',
        child: Column(children: [
          if (plan != null && price != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('$plan • ${price.toStringAsFixed(0)} OMR',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          PrototypePanel(
              child: Form(
                  key: form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(child: Icon(Icons.credit_card, size: 40)),
                        const SizedBox(height: 12),
                        const Center(
                            child: Text('Demo payment • No real charge',
                                style: TextStyle(fontSize: 12))),
                        const SizedBox(height: 22),
                        demoField('Card Holder Name', 'Test User', holder),
                        demoField('Card Number', '4242 4242 4242 4242', number,
                            digits: 16),
                        Row(children: [
                          Expanded(
                              child: demoField('Expiry Date', 'MM/YY', expiry)),
                          const SizedBox(width: 24),
                          Expanded(
                              child: demoField('CVV', '123', cvv, digits: 3))
                        ]),
                      ]))),
          const SizedBox(height: 24),
          const Text(
              'No money will be charged. Use test details only. Card details are never saved or sent.',
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

  Widget demoField(String label, String hint, TextEditingController controller,
      {int? digits}) {
    final isName = label == 'Card Holder Name';
    final isExpiry = label == 'Expiry Date';
    final allowed = isName ? nameCharacters : positiveDigits;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: isExpiry,
        onTap: isExpiry ? pickExpiry : null,
        obscureText: label == 'CVV',
        keyboardType:
            digits != null ? TextInputType.number : TextInputType.name,
        inputFormatters: isExpiry
            ? null
            : [
                TextInputFormatter.withFunction((previous, next) =>
                    allowed.hasMatch(next.text) ? next : previous),
                if (digits != null) LengthLimitingTextInputFormatter(digits),
              ],
        decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixIconConstraints:
                isExpiry ? const BoxConstraints(minWidth: 32) : null,
            suffixIcon: isExpiry
                ? const Icon(Icons.calendar_today_outlined, size: 18)
                : null),
        validator: (value) {
          final text = (value ?? '').trim();
          if (text.isEmpty) return 'Enter $label';
          if (isName &&
              (!nameCharacters.hasMatch(text) || !hasLetter.hasMatch(text))) {
            return 'Use letters and spaces only';
          }
          if (digits != null &&
              (text.length != digits || !positiveDigits.hasMatch(text))) {
            return 'Enter $digits digits from 1 to 9';
          }
          if (isExpiry) {
            final match = RegExp(r'^(0[1-9]|1[0-2])/(\d{2})$').firstMatch(text);
            if (match == null) return 'Use MM/YY';
            final month =
                DateTime(2000 + int.parse(match[2]!), int.parse(match[1]!));
            final now = DateTime.now();
            if (!month.isAfter(DateTime(now.year, now.month))) {
              return 'Use a future month';
            }
          }
          return null;
        },
      ),
    );
  }
}
