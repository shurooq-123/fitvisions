import 'package:flutter/material.dart';
import 'personal_cloth_measurement_screen.dart';

/// Compatibility entry point; both old measurement routes share one form.
class ClothMeasurementScreen extends StatelessWidget {
  const ClothMeasurementScreen({super.key});
  @override
  Widget build(BuildContext context) => const PersonalClothMeasurementScreen();
}
