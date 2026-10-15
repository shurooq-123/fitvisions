import 'package:flutter/material.dart';

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
};

class MeasurementLabel extends StatelessWidget {
  const MeasurementLabel(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Tooltip(
        message: measurementHelp[label] ?? label,
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
const sizeRows = <List<String>>[
  ['XS', '78–84', '60–66', '84–90'],
  ['S', '84–90', '66–72', '90–96'],
  ['M', '90–96', '72–78', '96–102'],
  ['L', '96–104', '78–86', '102–110'],
  ['XL', '104–112', '86–94', '110–118'],
  ['XXL', '112–120', '94–102', '118–126'],
];

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
  const MeasurementGuide({super.key});
  @override
  Widget build(BuildContext context) => Column(children: [
        const SizedBox(height: 20),
        const Text('Size guide (cm)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        const Text(
            'Illustrative adult chart only. Sizes vary by brand, gender and garment. XS means extra small; XL means extra large.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Table(border: TableBorder.all(color: Colors.black26), children: [
          for (final row in [
            ['Size', 'Chest', 'Waist', 'Hips'],
            ...sizeRows
          ])
            TableRow(children: [
              for (final cell in row)
                Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                    child: Text(cell,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12)))
            ])
        ]),
      ]);
}
