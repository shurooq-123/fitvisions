import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/widgets/measurement_guide.dart';
void main(){testWidgets('Measurement guide remains open and zooms until explicitly closed',(tester)async{
 await tester.pumpWidget(const MaterialApp(home:Scaffold(body:MeasurementLabel('Waist',value:80,previous:75))));
 await tester.tap(find.text('Waist'));await tester.pumpAndSettle();
 await tester.pump(const Duration(seconds:30));expect(find.byType(MeasurementIllustration),findsOneWidget);
 await tester.tap(find.byIcon(Icons.zoom_in));await tester.pump();
 expect(tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!.value.getMaxScaleOnAxis(),greaterThan(1));
 await tester.tap(find.byIcon(Icons.zoom_out));await tester.pump();
 expect(tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!.value.getMaxScaleOnAxis(),1);
 await tester.tap(find.byIcon(Icons.close));await tester.pumpAndSettle();expect(find.byType(MeasurementIllustration),findsNothing);
});}
