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
  const MeasurementLabel(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Tooltip(
        richMessage: WidgetSpan(
            child: SizedBox(
                width: 130,
                height: 180,
                child: Semantics(
                    label: measurementHelp[label] ?? label,
                    child: CustomPaint(painter: BodyMeasurePainter(label))))),
        decoration: BoxDecoration(
            color: const Color(0xFF574543),
            borderRadius: BorderRadius.circular(12)),
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 7),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(label)),
          const SizedBox(width: 3),
          const Icon(Icons.info_outline, size: 14)
        ]),
      );
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
    final rows = avatarSizing ? avatarSizeRows : sizeRows;
    return Column(children: [
      const SizedBox(height: 20),
      Text('Size guide (${inches ? 'in' : 'cm'})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      if (!avatarSizing)
        const Text(
            'Illustrative adult chart only. Sizes vary by brand, gender and garment. XS means extra small; XL means extra large.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12)),
      const SizedBox(height: 8),
      Table(
          border: TableBorder.all(
              color: const Color(0xFFD7D8D0),
              borderRadius: BorderRadius.circular(12)),
          children: [
            for (final row in [
              ['Size', 'Chest', 'Waist', 'Hips', if (avatarSizing) 'Shoulders'],
              ...rows
            ])
              TableRow(
                  decoration: BoxDecoration(
                      color: row.first == 'Size'
                          ? const Color(0xFF574543)
                          : row.first == selectedSize
                              ? const Color(0xFFE4D8E8)
                              : rows.indexOf(row).isEven
                                  ? const Color(0xFFFAF9F6)
                                  : const Color(0xFFE6E9DF)),
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
                              child: Text(
                                  inches &&
                                          row.first != 'Size' &&
                                          cell != row.first
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
                                          : const Color(0xFF37352F),
                                      fontWeight: row.first == 'Size' ||
                                              row.first == selectedSize
                                          ? FontWeight.bold
                                          : FontWeight.normal))))
                  ])
          ]),
    ]);
  }
}

class BodyMeasurePainter extends CustomPainter {
  BodyMeasurePainter(this.label);
  final String label;
  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()
      ..color = const Color(0xFFCED1C6)
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
    final a = vertical ? const Offset(112, 8) : Offset(42, y);
    final b = vertical ? const Offset(112, 160) : Offset(88, y);
    canvas.drawLine(a, b, arrow);
    for (final sign in [-1.0, 1.0]) {
      canvas.drawLine(
          a, a + (vertical ? Offset(sign * 5, 7) : Offset(7, sign * 5)), arrow);
      canvas.drawLine(b,
          b + (vertical ? Offset(sign * 5, -7) : Offset(-7, sign * 5)), arrow);
    }
    final text = TextPainter(
        text: TextSpan(
            text: label,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
        textDirection: TextDirection.ltr)
      ..layout();
    text.paint(canvas, Offset((size.width - text.width) / 2, 163));
  }

  @override
  bool shouldRepaint(BodyMeasurePainter old) => old.label != label;
}

class BodyMeasurements extends StatefulWidget {
  const BodyMeasurements(
      {super.key,
      required this.onChanged,
      this.onSize,
      this.onUnitChanged,
      this.afterFields,
      this.avatarSizing = false});
  final ValueChanged<Map<String, String>> onChanged;
  final ValueChanged<String>? onSize;
  final ValueChanged<bool>? onUnitChanged;
  final Widget? afterFields;
  final bool avatarSizing;
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
  bool inches = false;
  String? selectedSize;
  void emit() {
    final values = <String, String>{
      for (final key in fields.keys) key: centimetres[key]?.toString() ?? '',
    };
    widget.onChanged(values);
  }

  void setCentimetres(String key, double value) {
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
  Widget build(BuildContext context) => Column(children: [
        DropdownButton<bool>(
            isExpanded: true,
            value: inches,
            items: const [
              DropdownMenuItem(value: false, child: Text('Centimetres (cm)')),
              DropdownMenuItem(value: true, child: Text('Inches (in)'))
            ],
            onChanged: (v) {
              if (v == null || v == inches) return;
              setState(() {
                inches = v;
                for (final key in fields.keys) {
                  final cm = centimetres[key];
                  if (cm != null) setCentimetres(key, cm);
                }
              });
              widget.onUnitChanged?.call(inches);
              emit();
            }),
        for (final e in fields.entries)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(width: 90, child: MeasurementLabel(e.key)),
                Expanded(
                    child: TextField(
                        controller: e.value,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (text) {
                          final value = double.tryParse(text);
                          centimetres[e.key] = value == null
                              ? null
                              : value * (inches ? 2.54 : 1);
                          setState(() {});
                          emit();
                        },
                        decoration: InputDecoration(
                            hintText: widget.avatarSizing && e.key == 'Height'
                                ? (inches ? '19.69–98.43' : '50–250')
                                : e.key == 'Shoulders'
                                    ? 'Optional'
                                    : null,
                            suffixText: inches ? 'in' : 'cm',
                            filled: true,
                            fillColor: const Color(0xFFFFFDFC),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFB8B9AE))))))
              ])),
        if (widget.afterFields case final field?) field,
        const SizedBox(height: 12),
        if (!widget.avatarSizing) ...[
          const Text('Height examples',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(spacing: 6, children: [
            for (final cm in [145, 155, 165, 175, 185, 195, 205])
              ActionChip(
                  label: Text(inches
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
          Text('Selected size: $selectedSize',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        if (!widget.avatarSizing)
          const Text(
              'Tap a size to fill chest, waist and hips with example values. Enter your own height; sizes vary by brand.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12)),
      ]);
}
