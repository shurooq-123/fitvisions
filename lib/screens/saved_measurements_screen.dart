import 'package:flutter/material.dart';
import '../widgets/measurement_guide.dart';
import '../widgets/prototype_ui.dart';
import '../services/app_data_service.dart';

class SavedMeasurementsScreen extends StatefulWidget {
  const SavedMeasurementsScreen({super.key});
  @override
  State<SavedMeasurementsScreen> createState() =>
      _SavedMeasurementsScreenState();
}

class _SavedMeasurementsScreenState extends State<SavedMeasurementsScreen> {
  Map<String, String> values = {};
  String? message;
  bool saving = false;
  @override
  Widget build(BuildContext context) => PrototypePage(
      title: 'My Measurements',
      child: Column(children: [
        const Text(
            'Saved on this device automatically. Save to profile to sync with your account.'),
        BodyMeasurements(onChanged: (v) => values = v),
        if (message != null) Text(message!),
        PrototypeButton(saving ? 'Saving…' : 'Save to profile',
            onPressed: saving
                ? null
                : () async {
                    if (values.length != 4 ||
                        values.values.any((v) =>
                            double.tryParse(v) == null ||
                            !double.parse(v).isFinite ||
                            double.parse(v) <= 0 ||
                            double.parse(v) > 300)) {
                      setState(() =>
                          message = 'Complete the measurement fields above.');
                      return;
                    }
                    setState(() => saving = true);
                    try {
                      await AppDataService.saveOrUpdateMeasurements(
                          measurements: {
                            'measurementType': 'bodyOnly',
                            'height': values['Height'],
                            'chest': values['Chest'],
                            'waist': values['Waist'],
                            'hip': values['Hips']
                          });
                      if (mounted) {
                        setState(() =>
                            message = 'Measurements saved to your profile.');
                      }
                    } catch (_) {
                      if (mounted) {
                        setState(() => message =
                            'Saved on this device. Could not sync; please try again.');
                      }
                    } finally {
                      if (mounted) setState(() => saving = false);
                    }
                  }),
      ]));
}
