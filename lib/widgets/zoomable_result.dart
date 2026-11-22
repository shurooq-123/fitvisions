import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/app_language.dart';

class ZoomableResult extends StatefulWidget {
  const ZoomableResult({super.key, required this.child});
  final Widget child;
  @override
  State<ZoomableResult> createState() => _ZoomableResultState();
}

class _ZoomableResultState extends State<ZoomableResult> {
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
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        AspectRatio(
            aspectRatio: 1,
            child: ColoredBox(
                color: AppColors.page(context),
                child: InteractiveViewer(
                    transformationController: transform,
                    minScale: 1,
                    maxScale: 4,
                    child: Center(child: widget.child)))),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              tooltip: tr('Zoom out'),
              icon: const Icon(Icons.zoom_out),
              onPressed: () => zoom(1 / 1.25)),
          IconButton(
              tooltip: tr('Reset zoom'),
              icon: const Icon(Icons.center_focus_strong),
              onPressed: () => transform.value = Matrix4.identity()),
          IconButton(
              tooltip: tr('Zoom in'),
              icon: const Icon(Icons.zoom_in),
              onPressed: () => zoom(1.25)),
        ])
      ]);
}
