import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'measurement_avatar.dart';

Future<ui.Image> _decode(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    try {
      final scale = 384 /
          (descriptor.width > descriptor.height
              ? descriptor.width
              : descriptor.height);
      final codec = await descriptor.instantiateCodec(
          targetWidth: (descriptor.width * scale).round().clamp(1, 384),
          targetHeight: (descriptor.height * scale).round().clamp(1, 384));
      try {
        return (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
    } finally {
      descriptor.dispose();
    }
  } finally {
    buffer.dispose();
  }
}

Future<Uint8List> _png(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw StateError('Could not prepare avatar image.');
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

Future<ui.Rect> _clothingBounds(ui.Image image) async {
  final pixels = await image.toByteData();
  final width = image.width, height = image.height;
  final full = ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  if (pixels == null || width < 8 || height < 8) return full;
  int channel(int x, int y, int c) => pixels.getUint8((y * width + x) * 4 + c);
  int edgeDifference(int x, int y, int edgeX, int edgeY) =>
      (channel(x, y, 0) - channel(edgeX, edgeY, 0)).abs() +
      (channel(x, y, 1) - channel(edgeX, edgeY, 1)).abs() +
      (channel(x, y, 2) - channel(edgeX, edgeY, 2)).abs();
  if (edgeDifference(0, 0, width - 1, 0) > 45 ||
      edgeDifference(0, 0, 0, height - 1) > 65 ||
      edgeDifference(0, 0, width - 1, height - 1) > 65) {
    return full;
  }
  var left = width, right = 0, top = height, bottom = 0;
  for (var y = 1; y < height - 1; y++) {
    var hits = 0, rowLeft = width, rowRight = 0;
    for (var x = 1; x < width - 1; x++) {
      if (channel(x, y, 3) < 128 ||
          (channel(0, 0, 3) >= 128 && edgeDifference(x, y, 0, 0) < 65)) {
        continue;
      }
      hits++;
      if (x < rowLeft) rowLeft = x;
      if (x > rowRight) rowRight = x;
    }
    if (hits < width * .08) continue;
    if (rowLeft < left) left = rowLeft;
    if (rowRight > right) right = rowRight;
    if (y < top) top = y;
    bottom = y;
  }
  if (right - left < width * .15 || bottom - top < height * .20) return full;
  return ui.Rect.fromLTRB(left.toDouble(), top.toDouble(),
      (right + 1).toDouble(), (bottom + 1).toDouble());
}

Future<Uint8List> prepareAvatarMaterial(Uint8List? bytes, AvatarGarment garment,
    {ui.Color? overrideColour}) async {
  final source = bytes == null ? null : await _decode(bytes);
  try {
    final bounds = source == null ? null : await _clothingBounds(source);
    final trouserPatch =
        source != null && bounds != null && garment == AvatarGarment.separates
            ? await _trouserPatch(source, bounds)
            : null;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    for (var part = 0; part < 2; part++) {
      final target = ui.Rect.fromLTWH(0, part * 192.0, 192, 192);
      final paint = ui.Paint()
        ..color = const ui.Color(0xff405c70)
        ..filterQuality = ui.FilterQuality.medium;
      if (source == null || bounds == null) {
        canvas.drawRect(target, paint..color = overrideColour ?? paint.color);
      } else {
        final separates = garment == AvatarGarment.separates;
        final isTop = part == 0 || !separates;
        final start = separates ? (isTop ? .18 : .60) : .27;
        final end = separates ? (isTop ? .42 : .82) : .68;
        // A narrow patch avoids the gaps between trouser legs and the
        // background at the sides of a fitted garment.
        final x = separates && !isTop ? .35 : .50;
        final halfWidth = isTop ? .20 : .10;
        final patch = !isTop && trouserPatch != null
            ? trouserPatch
            : ui.Rect.fromLTRB(
                bounds.left + bounds.width * (x - halfWidth),
                bounds.top + bounds.height * start,
                bounds.left + bounds.width * (x + halfWidth),
                bounds.top + bounds.height * end,
              );
        if (overrideColour != null && isTop) {
          paint.colorFilter = ui.ColorFilter.mode(
              overrideColour.withValues(alpha: .80), ui.BlendMode.srcATop);
        }
        canvas.drawImageRect(source, patch, target, paint);
      }
    }
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(192, 384);
      try {
        return await _png(image);
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  } finally {
    source?.dispose();
  }
}

Future<ui.Rect> _trouserPatch(ui.Image image, ui.Rect bounds) async {
  final pixels = await image.toByteData();
  final top = bounds.top + bounds.height * .62;
  final bottom = bounds.top + bounds.height * .82;
  final half = bounds.width * .052;
  double chosen = bounds.left + bounds.width * .34;
  var best = -1;
  if (pixels != null) {
    int offset(double x, double y) =>
        (y.toInt().clamp(0, image.height - 1) * image.width +
            x.toInt().clamp(0, image.width - 1)) *
        4;
    // Select a patch entirely inside a leg. The two trouser legs are
    // usually separated by the photo background near the centre.
    for (final fraction in [.34, .29, .39, .24, .66, .71, .61, .76]) {
      final center = bounds.left + bounds.width * fraction;
      var foreground = 0;
      for (var row = 0; row < 6; row++) {
        final y = top + (bottom - top) * row / 5;
        final background = offset(0, y);
        for (var column = -2; column <= 2; column++) {
          final pixel = offset(center + half * column / 2, y);
          final difference =
              (pixels.getUint8(pixel) - pixels.getUint8(background)).abs() +
                  (pixels.getUint8(pixel + 1) - pixels.getUint8(background + 1))
                      .abs() +
                  (pixels.getUint8(pixel + 2) - pixels.getUint8(background + 2))
                      .abs();
          if (pixels.getUint8(pixel + 3) > 127 &&
              (pixels.getUint8(background + 3) < 128 || difference > 55)) {
            foreground++;
          }
        }
      }
      if (foreground > best) {
        best = foreground;
        chosen = center;
      }
    }
  }
  return ui.Rect.fromLTRB(chosen - half, top, chosen + half, bottom);
}

Future<ui.Image?> prepareAvatarFace(String path) async {
  final source = await _decode(await File(path).readAsBytes());
  try {
    final landmark = await const MethodChannel('fitvisions/avatar-face')
        .invokeListMethod<double>('locate', await _png(source));
    if (landmark == null || landmark.length != 3 || landmark[2] < 12) {
      return null;
    }
    final [eyeX, eyeY, distance] = landmark;
    final crop = ui.Rect.fromLTRB(eyeX - distance * 1.22,
        eyeY - distance * 1.12, eyeX + distance * 1.22, eyeY + distance * 1.60);
    if (crop.left < 0 ||
        crop.top < 0 ||
        crop.right > source.width ||
        crop.bottom > source.height) {
      return null;
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const target = ui.Rect.fromLTWH(0, 0, 192, 224);
    canvas.drawImageRect(source, crop, target,
        ui.Paint()..filterQuality = ui.FilterQuality.high);
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(192, 224);
    } finally {
      picture.dispose();
    }
  } finally {
    source.dispose();
  }
}
