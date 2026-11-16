import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_generation_service.dart';
import '../widgets/prototype_ui.dart';

class AvatarComparisonScreen extends StatefulWidget {
  const AvatarComparisonScreen(
      {super.key,
      required this.bodyImage,
      required this.measurements,
      this.candidateGenerator});
  final Uint8List bodyImage;
  final Map<String, String> measurements;
  final Future<Uint8List> Function(String, List<String>, String)?
      candidateGenerator;
  @override
  State<AvatarComparisonScreen> createState() => _AvatarComparisonScreenState();
}

class _AvatarComparisonScreenState extends State<AvatarComparisonScreen> {
  Uint8List? garment, person;
  bool busy = false;
  String status = '';
  final results = <Map<String, dynamic>>[];
  Future<void> choose(bool personal, ImageSource source) async {
    if (busy) return;
    try {
      final picked = await ImagePicker().pickImage(
          source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 90);
      if (picked == null) return;
      final bytes = await File(picked.path).readAsBytes();
      if (mounted) {
        setState(() {
          if (personal) {
            person = bytes;
          } else {
            garment = bytes;
          }
          results.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => status =
            'Could not load this photo. Check camera or gallery permissions.');
      }
    }
  }

  Future<void> compare() async {
    if (busy) return;
    setState(() {
      busy = true;
      results.clear();
      status = 'Preparing identical references…';
    });
    try {
      final refs = <String>[];
      for (final bytes in [
        widget.bodyImage,
        if (garment != null) garment!,
        if (person != null) person!
      ]) {
        refs.add(await AiGenerationService.reference(bytes));
      }
      final prompt =
          'Create one fully clothed full-body fashion image. Reference 0 is the measured mannequin; preserve its silhouette and neutral pose. '
          'Body measurements in cm: ${widget.measurements}. '
          '${garment == null ? 'Use a plain neutral modest outfit.' : 'Reference 1 is the garment: preserve cut, colour, fabric pattern, neckline and sleeve details.'} '
          '${person == null ? 'Use a neutral featureless face, no real-person identity.' : 'Reference ${garment == null ? 1 : 2} is the person: preserve appearance, not their original outfit.'} '
          'Neutral studio background. No text. This is a visual preview, not a certified clothing fit.';
      final frozen = List<String>.unmodifiable(refs);
      for (final candidate in ['flux-2-klein-4b', 'flux-2-klein-9b']) {
        if (!mounted) break;
        setState(() => status = 'Testing $candidate…');
        final clock = Stopwatch()..start();
        try {
          final bytes = await (widget.candidateGenerator ??
              AiGenerationService.generateCandidate)(prompt, frozen, candidate);
          if (mounted) {
            setState(() => results.add({
                  'model': candidate,
                  'image': bytes,
                  'seconds': clock.elapsedMilliseconds / 1000
                }));
          }
        } catch (e) {
          if (mounted) {
            setState(() => results.add({
                  'model': candidate,
                  'error': e.toString().replaceFirst('Exception: ', '')
                }));
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => status =
            'Could not prepare the images. Try choosing clear photos again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          if (results.length == 2) {
            status = 'Comparison finished. Review each result below.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
      title: 'Compare Avatar Models',
      child: Column(children: [
        const Text(
            'Both models receive the same measurements, images, prompt, output size and seed. This tests visual resemblance, not centimetre accuracy.',
            textAlign: TextAlign.center),
        SizedBox(height: 180, child: Image.memory(widget.bodyImage)),
        Text(widget.measurements.entries
            .map((e) => '${e.key}: ${e.value} cm')
            .join(' • ')),
        for (final personal in [false, true]) ...[
          Text(
              personal
                  ? 'Personal photo (optional)'
                  : 'Garment photo (optional)',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Wrap(children: [
            TextButton.icon(
                onPressed:
                    busy ? null : () => choose(personal, ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery')),
            TextButton.icon(
                onPressed:
                    busy ? null : () => choose(personal, ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'))
          ]),
          if ((personal ? person : garment) != null) ...[
            SizedBox(
                height: 160,
                child: Image.memory((personal ? person : garment)!)),
            TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                          if (personal) {
                            person = null;
                          } else {
                            garment = null;
                          }
                          results.clear();
                        }),
                child: const Text('Remove photo'))
          ],
        ],
        const Text(
            'Starting sends these selected images and measurements to Cloudflare and uses two generations from your account quota. Results remain on this page until you leave.',
            textAlign: TextAlign.center),
        if (busy) const CircularProgressIndicator(),
        Text(status),
        TextButton(
            onPressed: busy ? null : compare,
            child: const Text('Run comparison')),
        for (final r in results)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Text(r['model'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (r['image'] != null) ...[
                      Image.memory(r['image'] as Uint8List),
                      Text(
                          '${(r['seconds'] as double).toStringAsFixed(1)} seconds'),
                      const Text(
                          'Compare body silhouette, garment cut, colour, pattern and face. These results do not verify physical dimensions.')
                    ] else
                      Text(r['error'] as String),
                  ]))),
      ]));
}
