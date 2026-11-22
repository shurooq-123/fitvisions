import '../services/app_language.dart';
import '../services/avatar_gender.dart';
import '../constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../services/body_size_presets.dart';

const measurementHelp = <String, String>{
  'Height':
      'Stand straight without shoes. Measure from the floor to the top of your head (cm).',
  'Weight':
      'Use your current weight from a scale, wearing light clothing (kg).',
  'Chest':
      'Wrap the tape around the fullest part of your chest, under the arms. Keep it level and comfortably loose (cm).',
  'Waist':
      'Measure around your natural waist, usually the narrowest part of your torso. Do not pull the tape tight (cm).',
  'Hips':
      'Measure around the widest part of your hips and seat with your feet together (cm).',
  'Shoulders':
      'Measure straight across your back from one shoulder point to the other (cm).',
};

class MeasurementLabel extends StatelessWidget {
  const MeasurementLabel(this.label, {super.key, this.value, this.previous});
  final double? value, previous;
  final String label;
  @override
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => InkWell(
            onTap: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => MeasurementIllustration(
                    label: label, value: value, previous: previous)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(child: AppText(label)),
              if (value != null && previous != null && value != previous)
                Icon(
                    value! > previous!
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 14,
                    semanticLabel: tr(value! > previous!
                        ? 'Measurement increased'
                        : 'Measurement decreased')),
              const SizedBox(width: 3),
              const Icon(Icons.info_outline, size: 14)
            ]),
          ));
}

class MeasurementIllustration extends StatefulWidget {
  const MeasurementIllustration(
      {super.key, required this.label, this.value, this.previous});
  final String label;
  final double? value, previous;
  @override
  State<MeasurementIllustration> createState() =>
      _MeasurementIllustrationState();
}

class _MeasurementIllustrationState extends State<MeasurementIllustration> {
  final transform = TransformationController();
  void zoom(double factor) {
    final scale =
        (transform.value.getMaxScaleOnAxis() * factor).clamp(1.0, 4.0);
    transform.value = Matrix4.identity()..scale(scale);
  }

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawing = SizedBox(
        width: 130,
        height: 180,
        child: Semantics(
            label: measurementHelp[widget.label] ?? widget.label,
            child: CustomPaint(
                painter: BodyMeasurePainter(widget.label,
                    value: widget.value, previous: widget.previous))));
    return Dialog(
        child: SizedBox(
            width: 320,
            height: MediaQuery.sizeOf(context).height * .7,
            child: Column(children: [
              Row(children: [
                const SizedBox(width: 12),
                Expanded(child: AppText(widget.label)),
                IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context))
              ]),
              Expanded(
                  child: ColoredBox(
                      color: const Color(0xFF85465F),
                      child: InteractiveViewer(
                          transformationController: transform,
                          minScale: 1,
                          maxScale: 4,
                          child: Center(
                              child: AspectRatio(
                                  aspectRatio: 130 / 180,
                                  child: FittedBox(child: drawing)))))),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                    tooltip: tr('Zoom out'),
                    onPressed: () => zoom(1 / 1.25),
                    icon: const Icon(Icons.zoom_out)),
                IconButton(
                    tooltip: tr('Reset zoom'),
                    onPressed: () => transform.value = Matrix4.identity(),
                    icon: const Icon(Icons.center_focus_strong)),
                IconButton(
                    tooltip: tr('Zoom in'),
                    onPressed: () => zoom(1.25),
                    icon: const Icon(Icons.zoom_in)),
              ]),
            ])));
  }
}

// Illustrative adult ranges, not a garment manufacturer's sizing standard.
const sizeRows = bodySizeRows;

String suggestedSize(Map<String, String> measurements) {
  final chest = double.tryParse(measurements['Chest'] ?? '');
  final waist = double.tryParse(measurements['Waist'] ?? '');
  final hips = double.tryParse(measurements['Hips'] ?? '');
  if (chest == null || waist == null || hips == null) {
    return 'Compare chest, waist and hips with the size guide.';
  }
  for (final row in sizeRows) {
    if (chest <= double.parse(row[1].split('–').last) &&
        waist <= double.parse(row[2].split('–').last) &&
        hips <= double.parse(row[3].split('–').last)) {
      return 'Starting point: ${row[0]} in this example chart. Confirm with your brand and preferred fit.';
    }
  }
  return 'Outside this example chart: check extended or custom sizes. Keep your actual measurements.';
}

bool validMeasurements(Map<String, String> values) {
  for (final entry in {
    'Height': 250,
    'Weight': 400,
    'Chest': 300,
    'Waist': 300,
    'Hips': 300
  }.entries) {
    final v = double.tryParse(values[entry.key] ?? '');
    if (v == null || !v.isFinite || v <= 0 || v > entry.value) return false;
  }
  return true;
}

class MeasurementGuide extends StatelessWidget {
  const MeasurementGuide(
      {super.key,
      this.inches = false,
      this.onSelect,
      this.selectedSize,
      this.avatarSizing = false});
  final bool inches;
  final bool avatarSizing;
  final String? selectedSize;
  final void Function(String, Map<String, double>)? onSelect;
  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    final rows = avatarSizing ? avatarSizeRows : sizeRows;
    return Column(children: [
      const SizedBox(height: 20),
      AppText('Size guide (${inches ? 'in' : 'cm'})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      if (!avatarSizing)
        const AppText(
            'Illustrative adult chart only. Sizes vary by brand, gender and garment. XS means extra small; XL means extra large.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12)),
      const SizedBox(height: 8),
      Table(
          border: TableBorder.all(
              color: AppColors.muted(context, const Color(0xFFE9D5DE)),
              borderRadius: BorderRadius.circular(12)),
          children: [
            for (final row in [
              ['Size', 'Chest', 'Waist', 'Hips', if (avatarSizing) 'Shoulders'],
              ...rows
            ])
              TableRow(
                  decoration: BoxDecoration(
                      color: row.first == 'Size'
                          ? const Color(0xFF85465F)
                          : row.first == selectedSize
                              ? AppColors.adaptive(
                                  context,
                                  const Color(0xFFF0DCE5),
                                  const Color(0xFF573747))
                              : rows.indexOf(row).isEven
                                  ? AppColors.field(
                                      context, const Color(0xFFFAF9F6))
                                  : AppColors.panel(
                                      context, const Color(0xFFF6E8EC))),
                  children: [
                    for (final cell in row)
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 9, horizontal: 2),
                          child: InkWell(
                              onTap: onSelect == null || row.first == 'Size'
                                  ? null
                                  : () => onSelect!(
                                      row.first, bodySizeMidpoints(row)),
                              child: AppText(
                                  inches && row.first != 'Size' && cell != row.first
                                      ? cell
                                          .split('–')
                                          .map((v) => (double.parse(v) / 2.54)
                                              .toStringAsFixed(1))
                                          .join('–')
                                      : cell,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: row.first == 'Size'
                                          ? Colors.white
                                          : AppColors.ink(
                                              context, const Color(0xFF382331)),
                                      fontWeight:
                                          row.first == 'Size' || row.first == selectedSize
                                              ? FontWeight.bold
                                              : FontWeight.normal))))
                  ])
          ]),
    ]);
  }
}

class BodyMeasurePainter extends CustomPainter {
  BodyMeasurePainter(this.label, {this.value, this.previous});
  final double? value, previous;
  final String label;
  @override
  void paint(Canvas canvas, Size size) {
    final verticalMeasure = label == 'Height' || label == 'Length';
    final factor = verticalMeasure
        ? ((value ?? 170) / 250).clamp(.2, 1.0)
        : ((value ?? 90) / 90).clamp(.6, 1.35);
    canvas.save();
    canvas.translate(65, 90);
    canvas.scale(verticalMeasure ? 1 : factor, verticalMeasure ? factor : 1);
    canvas.translate(-65, -90);
    final body = Paint()
      ..color = const Color(0xFFB78299)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(65, 20), 12, body);
    for (final points in [
      [65.0, 40.0, 65.0, 100.0],
      [65.0, 48.0, 36.0, 90.0],
      [65.0, 48.0, 94.0, 90.0],
      [65.0, 100.0, 45.0, 155.0],
      [65.0, 100.0, 85.0, 155.0]
    ]) {
      canvas.drawLine(
          Offset(points[0], points[1]), Offset(points[2], points[3]), body);
    }
    canvas.restore();
    final arrow = Paint()
      ..color = const Color(0xFFB84E66)
      ..strokeWidth = 2.5;
    if (label == 'Weight') {
      canvas.drawRect(const Rect.fromLTWH(30, 153, 70, 9), arrow);
      return;
    }
    final vertical = label == 'Height' || label == 'Length';
    final y = label == 'Shoulders'
        ? 47.0
        : label == 'Chest'
            ? 55.0
            : label == 'Waist'
                ? 79.0
                : 100.0;
    final a = vertical
        ? Offset(112, 160 - 152 * factor)
        : Offset(65 - 23 * factor, y);
    final b = vertical ? const Offset(112, 160) : Offset(65 + 23 * factor, y);
    canvas.drawLine(a, b, arrow);
    for (final sign in [-1.0, 1.0]) {
      canvas.drawLine(
          a, a + (vertical ? Offset(sign * 5, 7) : Offset(7, sign * 5)), arrow);
      canvas.drawLine(b,
          b + (vertical ? Offset(sign * 5, -7) : Offset(-7, sign * 5)), arrow);
    }
    final text = TextPainter(
        text: TextSpan(
            text:
                '$label${value == null ? '' : ' ${value!.toStringAsFixed(1)} cm'}${value != null && previous != null && value != previous ? (value! > previous! ? ' ↑' : ' ↓') : ''}',
            style: const TextStyle(color: Colors.white, fontSize: 12)),
        textDirection: TextDirection.ltr)
      ..layout();
    text.paint(canvas, Offset((size.width - text.width) / 2, 163));
  }

  @override
  bool shouldRepaint(BodyMeasurePainter old) =>
      old.label != label || old.value != value || old.previous != previous;
}

class BodyMeasurements extends StatefulWidget {
  const BodyMeasurements(
      {super.key,
      required this.onChanged,
      this.onSize,
      this.onUnitChanged,
      this.afterFields,
      this.avatarSizing = false,
      this.initialValues = const {},
      this.gender});
  final ValueChanged<Map<String, String>> onChanged;
  final ValueChanged<String>? onSize;
  final ValueChanged<bool>? onUnitChanged;
  final Widget? afterFields;
  final bool avatarSizing;
  final Map<String, String> initialValues;
  final AvatarGender? gender;
  @override
  State<BodyMeasurements> createState() => _BodyMeasurementsState();
}

class _BodyMeasurementsState extends State<BodyMeasurements> {
  late final fields = {
    for (final name in [
      'Height',
      'Chest',
      'Waist',
      'Hips',
      if (widget.avatarSizing) 'Shoulders'
    ])
      name: TextEditingController()
  };
  final centimetres = <String, double?>{};
  final previousValues = <String, double?>{};
  bool inches = false;
  String? selectedSize;
  @override
  void initState() {
    super.initState();
    for (final key in fields.keys) {
      final n = double.tryParse(widget.initialValues[key] ?? '');
      if (n != null) setCentimetres(key, n);
    }
  }

  void emit() {
    final values = <String, String>{
      for (final key in fields.keys) key: centimetres[key]?.toString() ?? '',
    };
    widget.onChanged(values);
  }

  void setCentimetres(String key, double value) {
    previousValues[key] = centimetres[key];
    centimetres[key] = value;
    fields[key]!.text =
        inches ? (value / 2.54).toStringAsFixed(2) : value.toString();
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => Column(children: [
            DropdownButton<bool>(
                isExpanded: true,
                value: inches,
                items: const [
                  DropdownMenuItem(
                      value: false, child: AppText('Centimetres (cm)')),
                  DropdownMenuItem(value: true, child: AppText('Inches (in)'))
                ],
                onChanged: (v) {
                  if (v == null || v == inches) return;
                  setState(() {
                    inches = v;
                    for (final key in fields.keys) {
                      final cm = centimetres[key];
                      if (cm != null)
                        fields[key]!.text = inches
                            ? (cm / 2.54).toStringAsFixed(2)
                            : cm.toString();
                    }
                  });
                  widget.onUnitChanged?.call(inches);
                  emit();
                }),
            for (final e in fields.entries)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    SizedBox(
                        width: 90,
                        child: MeasurementLabel(e.key,
                            value: centimetres[e.key],
                            previous: previousValues[e.key])),
                    Expanded(
                        child: TextField(
                            controller: e.value,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (text) {
                              final value = double.tryParse(text);
                              previousValues[e.key] = centimetres[e.key];
                              centimetres[e.key] = value == null
                                  ? null
                                  : value * (inches ? 2.54 : 1);
                              setState(() {});
                              emit();
                            },
                            decoration: InputDecoration(
                                hintText: trError(
                                    widget.avatarSizing && e.key == 'Height'
                                        ? (inches ? '19.69–98.43' : '50–250')
                                        : e.key == 'Shoulders'
                                            ? 'Optional'
                                            : null),
                                suffixText: inches ? 'in' : 'cm',
                                filled: true,
                                fillColor: AppColors.field(
                                    context, const Color(0xFFFFFDFC)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE5CED7))))))
                  ])),
            if (widget.afterFields case final field?) field,
            const SizedBox(height: 12),
            if (!widget.avatarSizing) ...[
              const AppText('Height examples',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 6, children: [
                for (final cm in [145, 155, 165, 175, 185, 195, 205])
                  ActionChip(
                      label: AppText(inches
                          ? '${(cm / 2.54).toStringAsFixed(1)} in'
                          : '$cm cm'),
                      onPressed: () {
                        setState(() => setCentimetres('Height', cm.toDouble()));
                        emit();
                      })
              ]),
            ],
            MeasurementGuide(
                inches: inches,
                avatarSizing: widget.avatarSizing,
                selectedSize: selectedSize,
                onSelect: (name, values) {
                  setState(() {
                    selectedSize = name;
                    for (final e in values.entries) {
                      setCentimetres(e.key, e.value);
                    }
                  });
                  emit();
                  widget.onSize?.call(name);
                }),
            if (selectedSize != null)
              AppText('Selected size: $selectedSize',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            if (!widget.avatarSizing)
              const AppText(
                  'Tap a size to fill chest, waist and hips with example values. Enter your own height; sizes vary by brand.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12)),
          ]));
}
