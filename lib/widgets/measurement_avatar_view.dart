import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../services/measurement_avatar.dart';

double _avatarRadius(MeasurementAvatar model) =>
    [...model.triangles, ...model.garmentTop, ...model.garmentBottom]
        .expand((face) => [face.a, face.b, face.c])
        .map((p) => math.sqrt(p.x * p.x + p.z * p.z))
        .reduce(math.max);

class MeasurementAvatarPainter extends CustomPainter {
  MeasurementAvatarPainter(this.model,
      {this.angle = 0,
      this.pitch = 0,
      this.atlas,
      this.portrait,
      this.frameHeight,
      this.showMeasurements = false,
      this.garmentColour = const Color(0xFF607D8B),
      this.bottomColour = const Color(0xFF37474F)});
  final MeasurementAvatar model;
  final double angle;
  final double pitch;
  final ui.Image? atlas;
  final ui.Image? portrait;
  final double? frameHeight;
  final bool showMeasurements;
  final Color garmentColour, bottomColour;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFF3F2EF));
    final c = math.cos(angle), s = math.sin(angle);
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final middle = model.height / 2;
    AvatarPoint rotate(AvatarPoint p) {
      final y = p.y - middle, z = -p.x * s + p.z * c;
      return AvatarPoint(
          p.x * c + p.z * s, middle + y * cp - z * sp, y * sp + z * cp);
    }

    final skin = model.garment == null ? model.triangles : model.exposedSkin;
    final faces = [
      for (final (mesh, colour, surface) in [
        (skin, const Color(0xFFC8A997), 0),
        (model.headSurface, const Color(0xFFC8A997), 1),
        (model.garmentTop, garmentColour, 2),
        (model.garmentBottom, bottomColour, 3),
      ])
        for (final t in mesh)
          (
            AvatarTriangle(rotate(t.a), rotate(t.b), rotate(t.c)),
            colour,
            t,
            surface
          )
    ]..sort((a, b) => (a.$1.a.z + a.$1.b.z + a.$1.c.z)
        .compareTo(b.$1.a.z + b.$1.b.z + b.$1.c.z));
    final extent = _avatarRadius(model);
    final scale = math.min(size.height * .86 / (frameHeight ?? model.height),
        size.width * (showMeasurements ? .72 : .84) / (extent * 2));
    Offset project(AvatarPoint p) =>
        Offset(size.width / 2 + p.x * scale, size.height * .94 - p.y * scale);
    final paint = Paint()..isAntiAlias = false;
    Paint? texturePaint(ui.Image? image) => image == null
        ? null
        : (Paint()
          ..shader = ui.ImageShader(
              image,
              TileMode.clamp,
              TileMode.clamp,
              Float64List.fromList(
                  [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1])));
    final fabricPaint = texturePaint(atlas);
    final facePaint = texturePaint(portrait);
    for (final (t, baseColour, source, surface) in faces) {
      final u = t.b - t.a, v = t.c - t.a;
      final nx = u.y * v.z - u.z * v.y,
          ny = u.z * v.x - u.x * v.z,
          nz = u.x * v.y - u.y * v.x;
      final norm = math.sqrt(nx * nx + ny * ny + nz * nz);
      final light = norm == 0
          ? .6
          : (.50 + .40 * ((nx * -.4 + ny * .3 + nz * .85) / norm).abs())
              .clamp(.25, .95);
      paint.color = Color.lerp(baseColour, Colors.black, 1 - light)!;
      final a = project(t.a), b = project(t.b), d = project(t.c);
      final fabric = atlas;
      if (surface >= 2 && fabric != null && fabricPaint != null) {
        Offset uv(AvatarPoint p) {
          final horizontal = (.5 + p.x / (extent * 2)).clamp(.02, .98);
          final vertical = surface == 3
              ? (1 - p.y / (model.height * .46)).clamp(.01, .99)
              : (1 - p.y / (model.height * .82)).clamp(.01, .99);
          return Offset(horizontal * fabric.width,
              (vertical + (surface == 3 ? 1 : 0)) * fabric.height / 2);
        }

        final shade =
            Color.lerp(Colors.white, Colors.black, (1 - light) * .24)!;
        final vertices = ui.Vertices(ui.VertexMode.triangles, [a, b, d],
            colors: [shade, shade, shade],
            textureCoordinates: [uv(source.a), uv(source.b), uv(source.c)]);
        canvas.drawVertices(vertices, BlendMode.modulate, fabricPaint);
        vertices.dispose();
        continue;
      }
      canvas.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..lineTo(b.dx, b.dy)
            ..lineTo(d.dx, d.dy)
            ..close(),
          paint);
      final face = portrait;
      if (surface == 1 && face != null && facePaint != null) {
        Offset faceUv(AvatarPoint p) => Offset(
              (.5 + p.x / (model.height * .11)).clamp(0.0, 1.0) * face.width,
              (1 - (p.y / model.height - .854) / .146).clamp(0.0, 1.0) *
                  face.height,
            );
        Color faceAlpha(AvatarPoint p) => Colors.white.withValues(
            alpha: (p.z / (model.height * .035)).clamp(0.0, 1.0).toDouble());
        final colours = [
          faceAlpha(source.a),
          faceAlpha(source.b),
          faceAlpha(source.c)
        ];
        if (colours.any((colour) => colour.a > 0)) {
          final vertices = ui.Vertices(ui.VertexMode.triangles, [a, b, d],
              colors: colours,
              textureCoordinates: [
                faceUv(source.a),
                faceUv(source.b),
                faceUv(source.c)
              ]);
          canvas.drawVertices(vertices, BlendMode.modulate, facePaint);
          vertices.dispose();
        }
      }
    }
    if (!showMeasurements) return;
    final guide = Paint()
      ..color = const Color(0xFF694B66)
      ..strokeWidth = 1.5;
    final head = project(AvatarPoint(0, model.height, 0));
    final feet = project(const AvatarPoint(0, 0, 0));
    final heightX = size.width * .07;
    canvas.drawLine(Offset(heightX, head.dy), Offset(heightX, feet.dy), guide);
    for (final y in [head.dy, feet.dy]) {
      canvas.drawLine(Offset(heightX - 4, y), Offset(heightX + 4, y), guide);
    }
    void label(String name, Offset position) {
      final text = TextPainter(
        text: TextSpan(
          text: name,
          style: const TextStyle(fontSize: 11, color: Color(0xFF382438)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final box = (position & Size(text.width, text.height)).inflate(3);
      canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(4)),
          Paint()..color = Colors.white);
      text.paint(canvas, position);
      text.dispose();
    }

    String cm(String name) =>
        '${model.dimensions[name]!.toStringAsFixed(2)} cm';
    final heightLabelY =
        (head.dy - 19).clamp(4.0, size.height - 110).toDouble();
    label('Height ${cm('Height')}', Offset(heightX + 7, heightLabelY));
    var nextLabelY = heightLabelY + 22;
    final labelled = [
      for (final name in ['Shoulders', 'Chest', 'Waist', 'Hips'])
        if (model.loops.containsKey(name)) name,
    ];
    for (final (index, name) in labelled.indexed) {
      final ring = model.loops[name];
      if (ring == null) continue;
      final line = (name == 'Shoulders' ? [ring.first, ring[32]] : ring)
          .map((p) => project(rotate(p)))
          .toList();
      final y = project(rotate(AvatarPoint(0, ring.first.y, 0))).dy;
      final right = line.map((p) => p.dx).reduce(math.max);
      final labelX =
          (right + 4).clamp(8.0, math.max(8.0, size.width - 121)).toDouble();
      final labelY = math.min(math.max(nextLabelY, y - 13),
          size.height - 20 * (labelled.length - index));
      if (name == 'Shoulders') {
        canvas.drawLine(line.first, line.last, guide);
      } else {
        for (var i = 0; i < line.length; i++) {
          canvas.drawLine(line[i], line[(i + 1) % line.length], guide);
        }
      }
      canvas.drawLine(Offset(right, y), Offset(labelX, labelY + 9), guide);
      label('$name ${cm(name)}', Offset(labelX, labelY));
      nextLabelY = labelY + 20;
    }
  }

  @override
  bool shouldRepaint(MeasurementAvatarPainter old) =>
      old.model != model ||
      old.angle != angle ||
      old.pitch != pitch ||
      old.atlas != atlas ||
      old.portrait != portrait ||
      old.frameHeight != frameHeight ||
      old.showMeasurements != showMeasurements ||
      old.garmentColour != garmentColour ||
      old.bottomColour != bottomColour;
}

Future<Uint8List> renderMeasurementAvatar(MeasurementAvatar model,
    {double angle = 0,
    double pitch = 0,
    ui.Image? atlas,
    ui.Image? portrait,
    double? frameHeight,
    bool showMeasurements = false}) async {
  final recorder = ui.PictureRecorder();
  MeasurementAvatarPainter(model,
          angle: angle,
          pitch: pitch,
          atlas: atlas,
          portrait: portrait,
          frameHeight: frameHeight,
          showMeasurements: showMeasurements)
      .paint(Canvas(recorder), const Size(768, 1024));
  final picture = recorder.endRecording();
  final image = await picture.toImage(768, 1024);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  if (bytes == null) throw StateError('Could not render avatar');
  return bytes.buffer.asUint8List();
}

/// Two views on a fixed 250 cm frame retain height differences between presets.
Future<Uint8List> renderBodyReferenceSheet(MeasurementAvatar model,
    {bool includeLabels = true}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (var i = 0; i < 2; i++) {
    canvas.save();
    canvas.translate(i * 480.0, 0);
    MeasurementAvatarPainter(model,
            angle: i == 0 ? 0 : math.pi / 2, frameHeight: 250)
        .paint(canvas, Size(480, includeLabels ? 880 : 960));
    canvas.restore();
  }
  if (includeLabels) {
    canvas.drawRect(const Rect.fromLTWH(0, 880, 960, 80),
        Paint()..color = const Color(0xFFF3F2EF));
    final label = TextPainter(
        text: TextSpan(
            text:
                'FRONT                         SIDE\nHeight ${model.height.toStringAsFixed(1)} cm | Chest ${model.dimensions['Chest']} | Waist ${model.dimensions['Waist']} | Hips ${model.dimensions['Hips']} cm',
            style: const TextStyle(
                fontFamily: 'TimesNewRoman',
                fontSize: 23,
                color: Colors.black)),
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: 940);
    label.paint(canvas, const Offset(10, 884));
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(960, 960);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  if (bytes == null) throw StateError('Could not render body reference');
  return bytes.buffer.asUint8List();
}
