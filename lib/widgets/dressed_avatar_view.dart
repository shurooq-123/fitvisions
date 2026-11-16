import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/measurement_avatar.dart';
import 'measurement_avatar_view.dart';
import 'prototype_ui.dart';

class DressedAvatarView extends StatefulWidget {
  const DressedAvatarView({
    super.key,
    required this.model,
    required this.atlas,
    this.portrait,
  });

  final MeasurementAvatar model;
  final ui.Image atlas;
  final ui.Image? portrait;

  @override
  State<DressedAvatarView> createState() => _DressedAvatarViewState();
}

class _DressedAvatarViewState extends State<DressedAvatarView> {
  double angle = 0;
  double pitch = 0;
  bool showMeasurements = true;

  void rotate(double horizontal, double vertical) {
    setState(() {
      angle = (angle + horizontal) % (math.pi * 2);
      pitch = (pitch + vertical).clamp(-math.pi / 2, math.pi / 2).toDouble();
    });
  }

  @override
  Widget build(BuildContext context) => PrototypePanel(
        child: Column(children: [
          const Text('Your 3D avatar',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Semantics(
            image: true,
            label: showMeasurements
                ? widget.model.dimensions.entries
                    .map((entry) => '${entry.key} ${entry.value} cm')
                    .join(', ')
                : 'Dressed 3D avatar',
            child: GestureDetector(
              onPanUpdate: (event) =>
                  rotate(event.delta.dx / 85, event.delta.dy / 85),
              child: SizedBox(
                width: double.infinity,
                height: 380,
                child: CustomPaint(
                  painter: MeasurementAvatarPainter(
                    widget.model,
                    angle: angle,
                    pitch: pitch,
                    atlas: widget.atlas,
                    portrait: widget.portrait,
                    showMeasurements: showMeasurements,
                  ),
                ),
              ),
            ),
          ),
          Wrap(alignment: WrapAlignment.center, children: [
            IconButton(
              tooltip: 'Rotate left',
              onPressed: () => rotate(-math.pi / 8, 0),
              icon: const Icon(Icons.arrow_back),
            ),
            IconButton(
              tooltip: 'View from above',
              onPressed: () => rotate(0, math.pi / 8),
              icon: const Icon(Icons.arrow_upward),
            ),
            IconButton(
              tooltip: 'View from below',
              onPressed: () => rotate(0, -math.pi / 8),
              icon: const Icon(Icons.arrow_downward),
            ),
            IconButton(
              tooltip: 'Rotate right',
              onPressed: () => rotate(math.pi / 8, 0),
              icon: const Icon(Icons.arrow_forward),
            ),
          ]),
          SwitchListTile(
            title: const Text('Show measurements'),
            value: showMeasurements,
            onChanged: (value) => setState(() => showMeasurements = value),
          ),
        ]),
      );
}
