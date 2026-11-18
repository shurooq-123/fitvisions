import 'package:flutter/material.dart';
import '../services/avatar_gender.dart';
import '../services/measurement_avatar.dart';
import '../services/body_size_presets.dart';
import '../services/app_language.dart';
import 'measurement_avatar_view.dart';

class LiveMeasurementPreview extends StatelessWidget {
  const LiveMeasurementPreview({super.key, required this.values, this.gender});
  final Map<String, String> values;
  final AvatarGender? gender;
  @override
  Widget build(BuildContext context) {
    if (!validAvatarMeasurements(values)) return const SizedBox.shrink();
    final model = MeasurementAvatar(values,
        garment: AvatarGarment.separates, gender: gender);
    return Column(children: [
      const AppText('Live measurement preview'),
      SizedBox(
          height: 220,
          width: 180,
          child: CustomPaint(
              key: const ValueKey('live-measurement-preview'),
              painter: MeasurementAvatarPainter(model))),
      const AppText(
          'Shape updates immediately. Apply changes to regenerate the dressed AI image.',
          textAlign: TextAlign.center),
    ]);
  }
}
