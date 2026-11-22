import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/app_language.dart';

class PhotoMark {
  const PhotoMark(this.start, this.end, this.color, {this.text});
  final Offset start, end;
  final Color color;
  final String? text;
}

void paintPhotoMarks(Canvas canvas, List<PhotoMark> marks, Size size) {
  for (final mark in marks) {
    final a = Offset(mark.start.dx * size.width, mark.start.dy * size.height),
        b = Offset(mark.end.dx * size.width, mark.end.dy * size.height);
    if (mark.text != null) {
      final text = TextPainter(
          text: TextSpan(
              text: mark.text,
              style: TextStyle(
                  color: mark.color,
                  fontSize: size.shortestSide * .05,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.black54)),
          textDirection: TextDirection.ltr)
        ..layout(maxWidth: size.width - a.dx);
      text.paint(canvas, a);
    } else {
      final p = Paint()
        ..color = mark.color
        ..strokeWidth = size.shortestSide * .008
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, b, p);
      final angle = math.atan2(b.dy - a.dy, b.dx - a.dx),
          length = size.shortestSide * .05;
      for (final side in [-.55, .55])
        canvas.drawLine(
            b,
            b -
                Offset(math.cos(angle + side) * length,
                    math.sin(angle + side) * length),
            p);
    }
  }
}

Future<ui.Image> renderEditedPhoto(ui.Image source, Rect crop, int width,
    int height, List<PhotoMark> marks) async {
  if (width < 64 ||
      height < 64 ||
      width > 4096 ||
      height > 4096 ||
      width * height > 16000000 ||
      crop.width <= 0 ||
      crop.height <= 0 ||
      crop.left < 0 ||
      crop.top < 0 ||
      crop.right > 1 ||
      crop.bottom > 1) throw ArgumentError('Invalid image dimensions');
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.scale(width / (source.width * crop.width),
      height / (source.height * crop.height));
  canvas.translate(-crop.left * source.width, -crop.top * source.height);
  canvas.drawImage(
      source, Offset.zero, Paint()..filterQuality = FilterQuality.high);
  paintPhotoMarks(
      canvas, marks, Size(source.width.toDouble(), source.height.toDouble()));
  final picture = rec.endRecording();
  final result = await picture.toImage(width, height);
  picture.dispose();
  return result;
}

Future<String?> editPhoto(BuildContext context, String path) =>
    Navigator.push<String>(context,
        MaterialPageRoute(builder: (_) => PhotoEditorScreen(path: path)));

class PhotoEditorScreen extends StatefulWidget {
  const PhotoEditorScreen({super.key, required this.path});
  final String path;
  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  ui.Image? image;
  String? error;
  bool saving = false, locked = true;
  String mode = 'Crop';
  Rect crop = const Rect.fromLTWH(0, 0, 1, 1);
  Offset? start, end;
  Color colour = Colors.red;
  final marks = <PhotoMark>[];
  final width = TextEditingController(),
      height = TextEditingController(),
      text = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final codec =
          await ui.instantiateImageCodec(await File(widget.path).readAsBytes());
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() {
        image = frame.image;
        resetSize();
      });
    } catch (_) {
      if (mounted) setState(() => error = 'Could not open image.');
    }
  }

  void resetSize() {
    if (image != null) {
      width.text = (image!.width * crop.width).round().toString();
      height.text = (image!.height * crop.height).round().toString();
    }
  }

  Offset point(Offset p, Size s) =>
      Offset((p.dx / s.width).clamp(0, .999), (p.dy / s.height).clamp(0, .999));
  Future<void> save() async {
    if (image == null || saving) return;
    final w = int.tryParse(width.text), h = int.tryParse(height.text);
    if (w == null ||
        h == null ||
        w < 64 ||
        h < 64 ||
        w > 4096 ||
        h > 4096 ||
        w * h > 16000000) {
      setState(() => error =
          'Use dimensions from 64 to 4096 pixels, up to 16 megapixels.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final result = await renderEditedPhoto(image!, crop, w, h, marks);
      final bytes = await result.toByteData(format: ui.ImageByteFormat.png);
      result.dispose();
      if (bytes == null) throw StateError('No image');
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/fitvisions_edit_${DateTime.now().microsecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      if (mounted) Navigator.pop(context, file.path);
    } catch (_) {
      if (mounted)
        setState(() => error = 'Could not save edited photo. Try again.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    image?.dispose();
    width.dispose();
    height.dispose();
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const AppText('Edit photo'), actions: [
        TextButton(
            onPressed:
                saving ? null : () => Navigator.pop(context, widget.path),
            child: const AppText('Use original'))
      ]),
      body: SafeArea(
          child: image == null
              ? Center(
                  child: error == null
                      ? const CircularProgressIndicator()
                      : AppText(error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Wrap(spacing: 8, children: [
                      for (final tool in ['Crop', 'Arrow', 'Text'])
                        ChoiceChip(
                            label: AppText(tool),
                            selected: mode == tool,
                            onSelected: saving
                                ? null
                                : (_) => setState(() => mode = tool))
                    ]),
                    const SizedBox(height: 12),
                    AppText(mode == 'Crop'
                        ? 'Drag on the image to select the area to keep.'
                        : mode == 'Arrow'
                            ? 'Drag to draw an arrow.'
                            : 'Enter text, then tap its position on the image.'),
                    if (mode == 'Text')
                      TextField(
                          controller: text,
                          maxLength: 100,
                          decoration: InputDecoration(
                              labelText: tr('Annotation text'))),
                    if (mode != 'Crop')
                      Wrap(children: [
                        for (final c in [
                          Colors.red,
                          Colors.white,
                          Colors.black,
                          Colors.blue
                        ])
                          IconButton(
                              tooltip: c == colour
                                  ? tr('Selected colour')
                                  : tr('Choose colour'),
                              onPressed: () => setState(() => colour = c),
                              icon: Icon(
                                  c == colour
                                      ? Icons.check_circle
                                      : Icons.circle,
                                  color: c))
                      ]),
                    AspectRatio(
                        aspectRatio: image!.width / image!.height,
                        child: LayoutBuilder(builder: (context, box) {
                          final size = box.biggest;
                          return GestureDetector(
                              onTapUp: mode != 'Text' || saving
                                  ? null
                                  : (d) {
                                      if (text.text.trim().isEmpty) return;
                                      setState(() => marks.add(PhotoMark(
                                          point(d.localPosition, size),
                                          Offset.zero,
                                          colour,
                                          text: text.text.trim())));
                                    },
                              onPanStart: mode == 'Text' || saving
                                  ? null
                                  : (d) => setState(() {
                                        start = point(d.localPosition, size);
                                        end = start;
                                      }),
                              onPanUpdate: mode == 'Text' || saving
                                  ? null
                                  : (d) => setState(
                                      () => end = point(d.localPosition, size)),
                              onPanEnd: mode == 'Text' || saving
                                  ? null
                                  : (_) {
                                      if (start == null || end == null) return;
                                      setState(() {
                                        if (mode == 'Crop') {
                                          final r =
                                              Rect.fromPoints(start!, end!);
                                          if (r.width > .02 && r.height > .02) {
                                            crop = r;
                                            resetSize();
                                          }
                                        } else {
                                          marks.add(
                                              PhotoMark(start!, end!, colour));
                                        }
                                        start = null;
                                        end = null;
                                      });
                                    },
                              child: CustomPaint(
                                  painter: _PhotoPainter(image!, crop, marks,
                                      mode, start, end, colour)));
                        })),
                    Wrap(spacing: 8, children: [
                      TextButton(
                          onPressed: () => setState(() {
                                crop = const Rect.fromLTWH(0, 0, 1, 1);
                                resetSize();
                              }),
                          child: const AppText('Reset crop')),
                      TextButton(
                          onPressed: marks.isEmpty
                              ? null
                              : () => setState(marks.removeLast),
                          child: const AppText('Undo annotation'))
                    ]),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: width,
                              keyboardType: TextInputType.number,
                              decoration:
                                  InputDecoration(labelText: tr('Width (px)')),
                              onChanged: (v) {
                                final n = int.tryParse(v);
                                if (locked && n != null)
                                  height.text = (n *
                                          image!.height *
                                          crop.height /
                                          (image!.width * crop.width))
                                      .round()
                                      .toString();
                              })),
                      IconButton(
                          tooltip: tr('Keep proportions'),
                          onPressed: () => setState(() => locked = !locked),
                          icon: Icon(locked ? Icons.lock : Icons.lock_open)),
                      Expanded(
                          child: TextField(
                              controller: height,
                              keyboardType: TextInputType.number,
                              decoration:
                                  InputDecoration(labelText: tr('Height (px)')),
                              onChanged: (v) {
                                final n = int.tryParse(v);
                                if (locked && n != null)
                                  width.text = (n *
                                          image!.width *
                                          crop.width /
                                          (image!.height * crop.height))
                                      .round()
                                      .toString();
                              }))
                    ]),
                    if (error != null)
                      AppText(error!,
                          style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                        onPressed: saving ? null : save,
                        icon: const Icon(Icons.save_outlined),
                        label:
                            AppText(saving ? 'Saving...' : 'Save edited copy')),
                  ]))));
}

class _PhotoPainter extends CustomPainter {
  _PhotoPainter(this.image, this.crop, this.marks, this.mode, this.start,
      this.end, this.colour);
  final ui.Image image;
  final Rect crop;
  final List<PhotoMark> marks;
  final String mode;
  final Offset? start, end;
  final Color colour;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Offset.zero & size,
        Paint());
    paintPhotoMarks(canvas, marks, size);
    if (mode == 'Arrow' && start != null && end != null)
      paintPhotoMarks(canvas, [PhotoMark(start!, end!, colour)], size);
    final r = mode == 'Crop' && start != null && end != null
        ? Rect.fromPoints(start!, end!)
        : crop;
    final rect = Rect.fromLTWH(r.left * size.width, r.top * size.height,
        r.width * size.width, r.height * size.height);
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(rect);
    canvas.drawPath(outside, Paint()..color = Colors.black38);
    canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _PhotoPainter old) => true;
}
