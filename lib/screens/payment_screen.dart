import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_data_service.dart';
import '../widgets/custom_back_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const bg = Color(0xFFD3D9CC);
  static const brown = Color(0xFF5E4747);

  final holderController = TextEditingController();
  final cardController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  bool loading = false;

  Future<void> pay() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final plan = args?['plan'] ?? 'Subscription';
    final price = (args?['price'] ?? 0).toDouble();

    if (holderController.text.trim().isEmpty ||
        cardController.text.trim().isEmpty ||
        expiryController.text.trim().isEmpty ||
        cvvController.text.trim().isEmpty) {
      showMessage('Please fill all payment fields');
      return;
    }

    if (!RegExp(r'^[0-9]{14}$').hasMatch(cardController.text.trim())) {
      showMessage('Card number must contain 14 digits');
      return;
    }

    if (!RegExp(r'^(0[1-9]|1[0-2])\/[0-9]{2}$')
        .hasMatch(expiryController.text.trim())) {
      showMessage('Expiry date must be MM/YY');
      return;
    }

    if (!RegExp(r'^[0-9]{3}$').hasMatch(cvvController.text.trim())) {
      showMessage('CVV must contain 3 digits');
      return;
    }

    try {
      setState(() => loading = true);

      await AppDataService.savePayment(
        plan: plan,
        amount: price,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/avatar');
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: brown,
      ),
    );
  }

  @override
  void dispose() {
    holderController.dispose();
    cardController.dispose();
    expiryController.dispose();
    cvvController.dispose();
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
                  const CustomBackButton(),

                  const SizedBox(height: 55),

                  const Text(
                    'Payment',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    width: 295,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(58),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            paymentImage('images/p1.png'),
                            paymentImage('images/p2.png'),
                            paymentImage('images/p3.png'),
                          ],
                        ),

                        const SizedBox(height: 20),

                        label('Card Holder Name'),

                        field(
                          controller: holderController,
                          hint: 'John Doe',
                        ),

                        label('Card Number'),

                        field(
                          controller: cardController,
                          hint: '00000000000000',
                          keyboard: TextInputType.number,
                          formatter: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(14),
                          ],
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  label('Expiry Date'),
                                  field(
                                    controller: expiryController,
                                    hint: '04/28',
                                    keyboard: TextInputType.number,
                                    formatter: [
                                      LengthLimitingTextInputFormatter(5),
                                      ExpiryDateFormatter(),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  label('CVV'),
                                  field(
                                    controller: cvvController,
                                    hint: '000',
                                    keyboard: TextInputType.number,
                                    formatter: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: 150,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : pay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Pay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget paymentImage(String path) {
    return Container(
      width: 72,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          path,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 5,
      ),
      child: Text(text),
    );
  }

  Widget field({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatter,
  }) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatter,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFEFF3FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
        ),
      ),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length > 4) {
      digits = digits.substring(0, 4);
    }

    String formatted = digits;

    if (digits.length > 2) {
      formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}