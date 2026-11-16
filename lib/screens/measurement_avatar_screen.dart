import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/measurement_avatar.dart';
import '../services/app_data_service.dart';
import '../widgets/measurement_avatar_view.dart';
import '../widgets/prototype_ui.dart';
import 'ai_generation_screen.dart';
import 'avatar_comparison_screen.dart';

class MeasurementAvatarScreen extends StatefulWidget {
  const MeasurementAvatarScreen({super.key, required this.measurements});
  final Map<String, String> measurements;
  @override
  State<MeasurementAvatarScreen> createState() =>
      _MeasurementAvatarScreenState();
}

class _MeasurementAvatarScreenState extends State<MeasurementAvatarScreen> {
  final form = GlobalKey<FormState>();
  late final fields = {
    for (final key in ['Height', 'Chest', 'Waist', 'Hips'])
      key: TextEditingController(text: widget.measurements[key])
  };
  late MeasurementAvatar model = MeasurementAvatar(widget.measurements);
  double angle = 0;
  bool busy = false;
  String? error;
  Map<String, String> get values => {
        ...widget.measurements,
        for (final e in fields.entries) e.key: e.value.text
      };
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool updateModel() {
    if (!form.currentState!.validate()) return false;
    setState(() {
      model = MeasurementAvatar(values);
      error = null;
    });
    return true;
  }

  Future<void> save() async {
    if (!updateModel()) return;
    setState(() => busy = true);
    try {
      final bytes = await renderMeasurementAvatar(model, angle: angle);
      await AppDataService.saveGeneration(
          'Measured geometric avatar: ${model.measured}', bytes, 'avatar');
      await AppDataService.saveOrUpdateMeasurements(measurements: {
        'measurementType': 'bodyOnly',
        'height': values['Height'],
        'chest': values['Chest'],
        'waist': values['Waist'],
        'hip': values['Hips'],
        'weight': values['Weight']
      });
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AiGenerationScreen(
                  title: 'Measured Avatar',
                  prompt: '',
                  avatar: true,
                  initialOutput: bytes,
                  geometryOnly: true,
                  measurements: values)));
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'Could not save this avatar to your account. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
      title: 'Measured Avatar',
      child: Column(children: [
        const Text(
            'A geometric mannequin built locally from your measurements. No AI guesses are used for its four measured dimensions.',
            textAlign: TextAlign.center),
        SizedBox(
            height: 370,
            width: 280,
            child: CustomPaint(
                painter: MeasurementAvatarPainter(model, angle: angle))),
        Slider(
            value: angle,
            min: -math.pi,
            max: math.pi,
            label: 'View angle',
            onChanged: busy ? null : (v) => setState(() => angle = v)),
        Form(
            key: form,
            child: Column(children: [
              for (final e in fields.entries)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: TextFormField(
                      controller: e.value,
                      enabled: !busy,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          labelText: e.key,
                          suffixText: 'cm',
                          border: const OutlineInputBorder()),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return n == null ||
                                !n.isFinite ||
                                n <= 0 ||
                                n > (e.key == 'Height' ? 250 : 300)
                            ? 'Enter a valid ${e.key.toLowerCase()} in cm'
                            : null;
                      },
                    ))
            ])),
        TextButton(
            onPressed: busy ? null : updateModel,
            child: const Text('Update body')),
        for (final e in model.measured.entries)
          Text('${e.key}: ${e.value.toStringAsFixed(2)} cm on mesh'),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
                'Height and torso loop lengths match the entered values. Body depth, limbs and head are estimated. Weight does not uniquely determine shape. This is not a body scan or a clothing-fit simulation. Personal and garment photos do not change this geometric mannequin.',
                textAlign: TextAlign.center)),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red)),
        if (busy) const CircularProgressIndicator(),
        PrototypeButton('Save avatar', onPressed: busy ? null : save),
        TextButton(
            onPressed: busy
                ? null
                : () async {
                    if (!updateModel()) return;
                    setState(() => busy = true);
                    try {
                      final bytes = await renderMeasurementAvatar(model);
                      if (!context.mounted) return;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AvatarComparisonScreen(
                                  bodyImage: bytes,
                                  measurements: model.dimensions.map(
                                      (k, v) => MapEntry(k, v.toString())))));
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: const Text('Compare AI models')),
      ]));
}
