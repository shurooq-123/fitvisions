import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/widgets/zoomable_result.dart';
void main(){testWidgets('Result supports zoom in, zoom out and reset',(tester)async{
 await tester.pumpWidget(const MaterialApp(home:Scaffold(body:SizedBox(width:300,child:ZoomableResult(child:Text('Avatar'))))));
 double scale()=>tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!.value.getMaxScaleOnAxis();
 await tester.tap(find.byIcon(Icons.zoom_in));expect(scale(),greaterThan(1));
 await tester.tap(find.byIcon(Icons.zoom_out));expect(scale(),1);
 await tester.tap(find.byIcon(Icons.zoom_in));await tester.tap(find.byIcon(Icons.center_focus_strong));expect(scale(),1);
});}
