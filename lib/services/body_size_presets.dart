// Illustrative adult presets, not universal clothing sizes or medical measurements.
const bodySizeRows = <List<String>>[
  ['XS', '78–84', '60–66', '84–90'],
  ['S', '84–90', '66–72', '90–96'],
  ['M', '90–96', '72–78', '96–102'],
  ['L', '96–104', '78–86', '102–110'],
  ['XL', '104–112', '86–94', '110–118'],
  ['XXL', '112–120', '94–102', '118–126'],
  ['XXXL', '120–128', '102–110', '126–134'],
];

// Fixed FitVisions avatar presets: chest, waist, hips, shoulder width in cm.
const avatarSizeRows = <List<String>>[
  ['XS', '81', '63', '87', '36'],
  ['S', '87', '69', '93', '38'],
  ['M', '93', '75', '99', '40'],
  ['L', '100', '82', '106', '42'],
  ['XL', '108', '90', '114', '44.5'],
  ['XXL', '116', '98', '122', '47.5'],
  ['XXXL', '124', '106', '130', '50.5'],
  ['4XL', '132', '114', '138', '53.5'],
  ['5XL', '140', '122', '146', '56.5'],
];
const avatarMinimumHeight = 50.0;

Map<String, double> bodySizeMidpoints(List<String> row) => {
      for (var i = 1; i < row.length; i++)
        ['Chest', 'Waist', 'Hips', 'Shoulders'][i - 1]: _presetValue(row[i]),
    };

double _presetValue(String cell) {
  final bounds = cell.split('–').map(double.parse).toList();
  return (bounds.first + bounds.last) / 2;
}

Map<String, String> bodySizePreset(String size, double heightCm) {
  final row = bodySizeRows.firstWhere((row) => row.first == size);
  return {
    'Height': heightCm.toString(),
    ...bodySizeMidpoints(row)
        .map((key, value) => MapEntry(key, value.toString())),
  };
}

const measurementLimits = <String, (double, double)>{
  'Height': (50, 250),
  'Chest': (30, 300),
  'Waist': (30, 300),
  'Hips': (30, 300),
  'Shoulders': (15, 100),
};
String? measurementError(String key, String? raw) {
  final range = measurementLimits[key];
  if (range == null || (key == 'Shoulders' && (raw ?? '').trim().isEmpty))
    return null;
  final n = double.tryParse(raw ?? '');
  if (n == null || !n.isFinite || n < range.$1 || n > range.$2) {
    return '${range.$1.toInt()}–${range.$2.toInt()} cm';
  }
  return null;
}

bool completeBodyMeasurements(Map<String, String> values) => [
      'Height',
      'Chest',
      'Waist',
      'Hips'
    ].every((key) => measurementError(key, values[key]) == null);
bool validAvatarMeasurements(Map<String, String> values) =>
    completeBodyMeasurements(values) &&
    measurementError('Shoulders', values['Shoulders']) == null;
