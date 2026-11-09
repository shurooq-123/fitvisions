import 'dart:math' as math;

class AvatarPoint {
  const AvatarPoint(this.x, this.y, this.z);
  final double x, y, z;
  AvatarPoint operator -(AvatarPoint b) =>
      AvatarPoint(x - b.x, y - b.y, z - b.z);
  double get length => math.sqrt(x * x + y * y + z * z);
}

class AvatarTriangle {
  const AvatarTriangle(this.a, this.b, this.c);
  final AvatarPoint a, b, c;
}

enum AvatarGarment { separates, dress, longDress, robe }

/// Dimensions are in cm. Only height and the three named torso loops are
/// constrained, along with shoulder width when supplied.
class MeasurementAvatar {
  MeasurementAvatar(Map<String, String> values,
      {this.depthRatio = .68, this.garment}) {
    for (final name in ['Height', 'Chest', 'Waist', 'Hips']) {
      final n = double.tryParse(values[name] ?? '');
      if (n == null ||
          !n.isFinite ||
          n <= 0 ||
          n > (name == 'Height' ? 250 : 300)) {
        throw ArgumentError('Invalid $name');
      }
      dimensions[name] = n;
    }
    final shoulders = values['Shoulders']?.trim() ?? '';
    if (shoulders.isNotEmpty) {
      final width = double.tryParse(shoulders);
      if (width == null || !width.isFinite || width <= 0 || width > 100) {
        throw ArgumentError('Invalid Shoulders');
      }
      dimensions['Shoulders'] = width;
    }
    if (!depthRatio.isFinite || depthRatio < .45 || depthRatio > 1) {
      throw ArgumentError('Invalid depth ratio');
    }
    _build();
  }
  final double depthRatio;
  final AvatarGarment? garment;
  final dimensions = <String, double>{};
  final loops = <String, List<AvatarPoint>>{};
  final triangles = <AvatarTriangle>[];
  final exposedSkin = <AvatarTriangle>[];
  final headSurface = <AvatarTriangle>[];
  final garmentTop = <AvatarTriangle>[];
  final garmentBottom = <AvatarTriangle>[];
  double get height => dimensions['Height']!;
  static double perimeter(List<AvatarPoint> loop) {
    double sum = 0;
    for (var i = 0; i < loop.length; i++) {
      sum += (loop[i] - loop[(i + 1) % loop.length]).length;
    }
    return sum;
  }

  List<AvatarPoint> ring(double y, double circumference,
      {double x = 0, double z = 0, double? ratio}) {
    final r = ratio ?? depthRatio;
    final unit = List.generate(64, (i) {
      final t = i * 2 * math.pi / 64;
      return AvatarPoint(math.cos(t), 0, r * math.sin(t));
    });
    final scale = circumference / perimeter(unit);
    return unit
        .map((p) => AvatarPoint(x + p.x * scale, y, z + p.z * scale))
        .toList();
  }

  void loft(List<List<AvatarPoint>> rings, {List<AvatarTriangle>? surface}) {
    final faces = surface ?? triangles;
    for (var j = 0; j < rings.length - 1; j++) {
      for (var i = 0; i < 64; i++) {
        final n = (i + 1) % 64;
        faces
            .add(AvatarTriangle(rings[j][i], rings[j + 1][i], rings[j + 1][n]));
        faces.add(AvatarTriangle(rings[j][i], rings[j + 1][n], rings[j][n]));
      }
    }
    for (final r in [rings.first, rings.last]) {
      final center = AvatarPoint(r.fold<double>(0, (s, p) => s + p.x) / 64,
          r.first.y, r.fold<double>(0, (s, p) => s + p.z) / 64);
      for (var i = 0; i < 64; i++) {
        faces.add(AvatarTriangle(center, r[i], r[(i + 1) % 64]));
      }
    }
  }

  List<AvatarPoint> offsetRing(List<AvatarPoint> points, double ease) {
    final centerX = (points.first.x + points[32].x) / 2;
    final centerZ = (points[16].z + points[48].z) / 2;
    return [
      for (final point in points)
        AvatarPoint(point.x + (point.x - centerX) * ease, point.y,
            point.z + (point.z - centerZ) * ease),
    ];
  }

  void _build() {
    final h = height,
        chest = dimensions['Chest']!,
        waist = dimensions['Waist']!,
        hips = dimensions['Hips']!;
    final neck = math.min(chest * .36, h * .22);
    final torso = <List<AvatarPoint>>[];
    for (final station in <List<double>>[
      [.44, hips * .7],
      [.51, hips],
      [.55, (hips + waist) / 2],
      [.59, waist],
      [.66, (waist + chest) / 2],
      [.73, chest],
      [.78, chest * .95],
      [.80, chest * .85],
      [.82, neck * 1.45],
      [.84, neck],
      [.88, neck * .94]
    ]) {
      final y = station[0];
      final belly = (waist / h - .42).clamp(0.0, .42) * h;
      var r = ring(y * h, station[1],
          z: y == .59
              ? belly * .12
              : y == .55 || y == .66
                  ? belly * .06
                  : 0,
          ratio: y == .59
              ? (depthRatio + .06).clamp(.45, 1).toDouble()
              : depthRatio);
      final shoulders = dimensions['Shoulders'];
      if (station[0] == .80 && shoulders != null) {
        final stretch = shoulders / (r.first.x * 2);
        r = [for (final p in r) AvatarPoint(p.x * stretch, p.y, p.z)];
      }
      torso.add(r);
      if (station[0] == .51) loops['Hips'] = r;
      if (station[0] == .59) loops['Waist'] = r;
      if (station[0] == .73) loops['Chest'] = r;
      if (station[0] == .80 && shoulders != null) loops['Shoulders'] = r;
    }
    final smooth = <List<AvatarPoint>>[];
    for (var j = 0; j < torso.length - 1; j++) {
      final a = torso[j], b = torso[j + 1];
      for (var step = 0; step < 6; step++) {
        final t = step / 6, blend = t * t * (3 - 2 * t);
        smooth.add(List.generate(
            64,
            (i) => AvatarPoint(
                a[i].x + (b[i].x - a[i].x) * blend,
                a[i].y + (b[i].y - a[i].y) * t,
                a[i].z + (b[i].z - a[i].z) * blend)));
      }
    }
    smooth.add(torso.last);
    loft(smooth);
    final dressed = garment != null;
    final hem = garment == AvatarGarment.dress ? .24 : .05;
    final shortSleeves =
        garment == AvatarGarment.dress || garment == AvatarGarment.longDress;
    if (dressed) {
      loft(smooth.where((r) => r.first.y >= h * .82).toList(),
          surface: exposedSkin);
    }
    final hipWidth = loops['Hips']!.first.x;
    final shoulder = dimensions['Shoulders'] == null
        ? loops['Chest']!.first.x
        : dimensions['Shoulders']! / 2;
    for (final sign in [-1.0, 1.0]) {
      final legs = [
        for (final s in <List<double>>[
          [0, .14],
          [.025, .21],
          [.045, .17],
          [.12, .18],
          [.22, .27],
          [.28, .24],
          [.37, .37],
          [.46, .47]
        ])
          ring(h * s[0], hips * s[1],
              x: sign * hipWidth * .48,
              z: s[0] < .045 ? h * .024 : 0,
              ratio: s[0] < .045 ? 1.65 : .88)
      ];
      loft(legs);
      final arms = [
        for (final s in <List<double>>[
          [.37, .015, 1.46],
          [.385, .085, 1.48],
          [.412, .10, 1.49],
          [.43, .087, 1.49],
          [.48, .13, 1.46],
          [.57, .17, 1.37],
          [.62, .16, 1.29],
          [.70, .24, 1.24],
          [.77, .24, 1.01],
          [.80, .09, .91]
        ])
          ring(h * s[0], chest * s[1],
              x: sign *
                  shoulder *
                  (dimensions.containsKey('Shoulders') ? s[2] / 1.1 : s[2]),
              ratio: s[0] < .43 ? .69 : .90)
      ];
      loft(arms);
      if (dressed) {
        final cuff = shortSleeves ? 7 : 3;
        loft(arms.take(cuff + 1).toList(), surface: exposedSkin);
        final visibleLegRings = garment == AvatarGarment.separates
            ? 3
            : hem < .1
                ? 4
                : 6;
        loft(legs.take(visibleLegRings).toList(), surface: exposedSkin);
        loft(arms.skip(cuff).map((r) => offsetRing(r, .09)).toList(),
            surface: garmentTop);
      }
      if (garment == AvatarGarment.separates) {
        loft(legs.skip(2).map((r) => offsetRing(r, .13)).toList(),
            surface: garmentBottom);
      }
    }
    if (garment != null) {
      final bodice = smooth
          .where((r) => r.first.y >= .51 * h && r.first.y <= .82 * h)
          .map((r) => offsetRing(r, .08));
      loft([
        if (garment == AvatarGarment.separates)
          offsetRing(torso.first, .32)
        else ...[
          ring(h * hem, hips * 1.25, ratio: .86),
          ring(h * (hem + .51) / 2, hips * 1.19, ratio: .82),
        ],
        ...bodice,
      ], surface: garmentTop);
    }
    // Jaw, cheeks, forehead and crown. Shape is independent of the torso size.
    final head = <List<AvatarPoint>>[];
    for (var i = 0; i <= 24; i++) {
      final t = (1 - math.cos(math.pi * i / 24)) / 2;
      final y = .854 + .146 * t;
      final width = math.sqrt(math.sin(t * math.pi)) * (.74 + .35 * t);
      final base = ring(h * y, h * .318 * math.max(.002, width), ratio: 1.08);
      head.add([
        for (final (j, point) in base.indexed)
          AvatarPoint(
              point.x,
              point.y,
              point.z +
                  h *
                      .012 *
                      math.exp(-math.pow((t - .43) / .13, 2) -
                          math.pow((j - 16) / 3.7, 2))),
      ]);
    }
    loft(head);
    if (dressed) loft(head, surface: headSurface);
  }

  Map<String, double> get measured => {
        'Height': triangles
                .expand((t) => [t.a, t.b, t.c])
                .map((p) => p.y)
                .reduce(math.max) -
            triangles
                .expand((t) => [t.a, t.b, t.c])
                .map((p) => p.y)
                .reduce(math.min),
        for (final e in loops.entries)
          e.key: e.key == 'Shoulders'
              ? (e.value.first - e.value[32]).length
              : perimeter(e.value)
      };
  String toObj() {
    final b = StringBuffer(
        '# FitVisions parametric mannequin; coordinates in centimetres\n');
    var index = 1;
    for (final t in triangles) {
      for (final p in [t.a, t.b, t.c]) {
        b.writeln('v ${p.x} ${p.y} ${p.z}');
      }
      b.writeln('f $index ${index + 1} ${index + 2}');
      index += 3;
    }
    return b.toString();
  }
}
