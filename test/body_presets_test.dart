import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/services/body_size_presets.dart';
import 'package:fitvisions/services/measurement_avatar.dart';
import 'package:fitvisions/widgets/measurement_avatar_view.dart';
void main() {
 TestWidgetsFlutterBinding.ensureInitialized();
 test('All six body presets retain exact specified torso loops and heights', () async {
  final loader=FontLoader('TimesNewRoman')..addFont(rootBundle.load('assets/fonts/times.ttf'));
  await loader.load();
  final report=<Map<String,dynamic>>[];
  final folder=Directory('output/body-presets'); await folder.create(recursive:true);
  for(final size in ['S','M','L','XL','XXL','XXXL']) {
   for(final height in [155.0,175.0,195.0]) {
    final values=bodySizePreset(size,height);
    final model=MeasurementAvatar(values);
    for(final entry in model.measured.entries) {
     expect(entry.value,closeTo(double.parse(values[entry.key]!),1e-7));
    }
    final bytes=await renderBodyReferenceSheet(model);
    await File('${folder.path}/$size-${height.toInt()}.png').writeAsBytes(bytes);
    report.add({'size':size,'input':values,'measured':model.measured});
   }
  }
  await File('${folder.path}/geometry-audit.json').writeAsString(const JsonEncoder.withIndent('  ').convert(report));
 });
}
