import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_generation_service.dart';
import '../services/avatar_prompt.dart';
import '../services/app_data_service.dart';
import '../widgets/measurement_guide.dart';
import '../widgets/prototype_ui.dart';
import '../widgets/clothing_library.dart';
import '../services/dress_reference.dart';
import '../services/design_edit_prompt.dart';

class AiGenerationScreen extends StatefulWidget {
  const AiGenerationScreen(
      {super.key,
      required this.title,
      required this.prompt,
      this.photos = const [],
      this.dressReference,
      this.avatar = false,
      this.measurements = const {},
      this.clothingPhoto,
      this.personalPhoto,
      this.preferredColour,
      this.size,
      this.outfitDetails = '',
      this.generator});
  final String title, prompt;
  final String outfitDetails;
  final List<String> photos;
  final DressReference? dressReference;
  final bool avatar;
  final Map<String, String> measurements;
  final String? clothingPhoto, personalPhoto, preferredColour, size;
  final Future<Uint8List> Function(String, List<Uint8List>)? generator;
  @override
  State<AiGenerationScreen> createState() => _AiGenerationScreenState();
}

class _AiGenerationScreenState extends State<AiGenerationScreen> {
  final changes = TextEditingController();
  late final Map<String, TextEditingController> measures;
  String? clothingPhoto;
  bool unlocked = false, checkingOut = false, structureChanged = false;
  Uint8List? output;
  bool busy = false;
  String? error;
  static const colourTarget = 'Main garment';
  final colourChanges = <String, String>{};
  static const palette = <String, Color>{
    'White': Colors.white,
    'Ivory': Color(0xFFFFFFE0),
    'Black': Colors.black,
    'Beige': Color(0xFFD8C4A4),
    'Brown': Color(0xFF795548),
    'Navy': Color(0xFF182B50),
    'Blue': Colors.blue,
    'Emerald': Color(0xFF167650),
    'Burgundy': Color(0xFF800020),
    'Red': Colors.red,
    'Pink': Colors.pink,
    'Purple': Colors.purple,
    'Grey': Colors.grey,
    'Gold': Color(0xFFD4AF37),
  };
  String get editInstructions =>
      designEditInstructions(changes.text, colourChanges);
  @override
  void initState() {
    super.initState();
    clothingPhoto = widget.clothingPhoto;
    measures = widget.measurements
        .map((key, value) => MapEntry(key, TextEditingController(text: value)));
  }

  Map<String, String> get currentMeasurements =>
      measures.map((key, value) => MapEntry(key, value.text.trim()));
  Future<void> checkout() async {
    if (checkingOut || busy) return;
    setState(() => checkingOut = true);
    final paid = await Navigator.pushNamed(context, '/subscription',
        arguments: {'returnToDesign': true});
    if (!mounted) return;
    setState(() {
      unlocked = paid == true;
      checkingOut = false;
    });
  }

  Future<void> replaceClothing() async {
    if (!unlocked || busy) return;
    final selected = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (selected != null && mounted) {
      setState(() {
        clothingPhoto = selected.path;
        structureChanged = true;
      });
    }
  }

  Future<void> generate({bool edit = false}) async {
    if (busy) return;
    if (output != null && !unlocked) return;
    if (widget.avatar &&
        measures.isNotEmpty &&
        !validMeasurements(currentMeasurements)) {
      setState(() => error = 'Enter valid positive measurements in cm and kg.');
      return;
    }
    if (edit && !structureChanged && editInstructions.isEmpty) {
      setState(() => error = 'Describe the changes you want.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final photos = <Uint8List>[];
      if (edit && output != null && !structureChanged) {
        photos.add(output!);
      } else {
        if (widget.dressReference != null) {
          photos.add(await widget.dressReference!.imageBytes());
        }
        final paths = widget.avatar && measures.isNotEmpty
            ? [
                if (clothingPhoto != null) clothingPhoto!,
                if (widget.personalPhoto != null) widget.personalPhoto!
              ]
            : widget.photos;
        for (final path in paths) {
          photos.add(clothingTemplates.containsKey(path)
              ? (await rootBundle.load(path)).buffer.asUint8List()
              : await File(path).readAsBytes());
        }
      }
      final basePrompt = widget.avatar && measures.isNotEmpty
          ? avatarPrompt(currentMeasurements,
              clothing: clothingPhoto != null,
              person: widget.personalPhoto != null)
          : widget.prompt;
      final result = await (widget.generator ?? AiGenerationService.generate)(
          edit && !structureChanged
              ? 'Edit the supplied image: $editInstructions. Preserve all other details. Fully clothed, non-explicit fashion image.'
              : '$basePrompt ${widget.outfitDetails} ${edit ? 'Additional requested changes: $editInstructions' : ''}',
          photos);
      if (mounted) setState(() => output = result);
      if (widget.generator == null) {
        try {
          final preferences = widget.prompt.contains('Design preferences:')
              ? widget.prompt.split('Design preferences:').last
              : '';
          final description =
              '${edit ? 'Edited' : 'Generated'} ${widget.title}: ${widget.outfitDetails} ${clothingTemplates[clothingPhoto] ?? widget.photos.map((p) => clothingTemplates[p] ?? 'uploaded clothing photo').join(', ')} ${edit ? editInstructions : preferences}';
          await AppDataService.saveGeneration(
              description, result, widget.avatar ? 'avatar' : 'clothes');
        } catch (_) {
          if (mounted) {
            setState(() => error =
                'Image generated, but history could not be saved. Check your connection.');
          }
        }
      }
      if (structureChanged && widget.avatar && widget.generator == null) {
        await AppDataService.saveOrUpdateMeasurements(measurements: {
          'measurementType': clothingPhoto == null
              ? 'bodyOnly'
              : widget.personalPhoto == null
                  ? 'clothOnly'
                  : 'personalAndCloth',
          'height': currentMeasurements['Height'],
          'weight': currentMeasurements['Weight'],
          'chest': currentMeasurements['Chest'],
          'waist': currentMeasurements['Waist'],
          'hip': currentMeasurements['Hips'],
          'clothImagePath': clothingPhoto,
          'personalImagePath': widget.personalPhoto,
        });
      }
      structureChanged = false;
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> download() async {
    if (!unlocked || busy || output == null) return;
    setState(() => busy = true);
    try {
      // Native savePreview expects PNG bytes.
      final codec = await ui.instantiateImageCodec(output!);
      final frame = await codec.getNextFrame();
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      if (png == null) throw StateError('Image unavailable');
      await const MethodChannel('fitvisions/downloads')
          .invokeMethod<String>('savePreview', png.buffer.asUint8List());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to Downloads / FitVisions.')));
        Navigator.pushNamed(context, '/feedback');
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Could not save the image.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    changes.dispose();
    for (final c in measures.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
      title: widget.title,
      child: Column(children: [
        Text(
            widget.avatar
                ? '3D-style avatar image. Body measurements and fit are not guaranteed.'
                : 'Create a clothing concept from your selected preferences.',
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        if (output != null) Image.memory(output!, gaplessPlayback: true),
        if (output == null)
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                  'Your design details, measurements and any selected photos will be sent to Cloudflare AI when you tap Generate.')),
        if (busy)
          const Padding(
              padding: EdgeInsets.all(16),
              child: Column(children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Generating… this can take up to 3 minutes.')
              ])),
        if (error != null)
          Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 12),
        if (output == null)
          PrototypeButton('Generate',
              onPressed: busy ? null : () => generate()),
        if (output != null && !unlocked) ...[
          const Text(
              'Subscribe and complete the demo payment to edit or download this image. No real charge.',
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          PrototypeButton(checkingOut ? 'Opening…' : 'Edit / Save',
              onPressed: checkingOut || busy ? null : checkout),
        ],
        if (output != null && unlocked) ...[
          const Text('Demo access unlocked • No real payment',
              style: TextStyle(fontSize: 12)),
          if (widget.avatar && measures.isNotEmpty)
            ExpansionTile(
                title: const Text('Edit measurements / clothing'),
                children: [
                  for (final entry in measures.entries)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          SizedBox(
                              width: 100, child: MeasurementLabel(entry.key)),
                          Expanded(
                              child: TextField(
                                  controller: entry.value,
                                  enabled: !busy,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  onChanged: (_) =>
                                      setState(() => structureChanged = true),
                                  decoration: InputDecoration(
                                      suffixText: entry.key == 'Weight'
                                          ? 'kg'
                                          : 'cm'))),
                        ])),
                  TextButton.icon(
                      onPressed: busy ? null : replaceClothing,
                      icon: const Icon(Icons.image),
                      label: const Text('Change clothing photo')),
                  TextButton.icon(
                    icon: const Icon(Icons.checkroom),
                    label: const Text('Choose a ready-made outfit'),
                    onPressed: busy
                        ? null
                        : () async {
                            final path = await chooseClothingTemplate(context);
                            if (path == null || !mounted) return;
                            setState(() {
                              clothingPhoto = path;
                              structureChanged = true;
                            });
                          },
                  ),
                  if (clothingPhoto != null)
                    const Text('Clothing photo selected'),
                  const MeasurementGuide(),
                ]),
          const SizedBox(height: 12),
          Text(widget.avatar
              ? suggestedSize(currentMeasurements)
              : 'Size suggestion: use ${widget.size ?? 'your chosen size'} as a starting point and compare the brand chart. Do not change your body measurements to match a size.'),
          const SizedBox(height: 12),
          const Text('Change clothing colour',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Text(
              'Choose a colour, then tap Apply changes. AI colour matching is approximate.',
              textAlign: TextAlign.center),
          Wrap(
              spacing: 8,
              children: palette.entries
                  .map((colour) => ChoiceChip(
                      avatar: CircleAvatar(
                          backgroundColor: colour.value, radius: 9),
                      label: Text(colour.key),
                      selected: colourChanges[colourTarget] == colour.key,
                      onSelected: busy
                          ? null
                          : (selected) => setState(() {
                                if (selected) {
                                  colourChanges[colourTarget] = colour.key;
                                } else {
                                  colourChanges.remove(colourTarget);
                                }
                              })))
                  .toList()),
          if (colourChanges.isNotEmpty) ...[
            Text(
                colourChanges.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join(' • '),
                textAlign: TextAlign.center),
            TextButton(
                onPressed: busy ? null : () => setState(colourChanges.clear),
                child: const Text('Clear colour choices')),
          ],
          const SizedBox(height: 16),
          TextField(
              controller: changes,
              enabled: !busy,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Describe your changes',
                  hintText: 'Change the colour, sleeves or embroidery')),
          PrototypeButton('Apply changes',
              onPressed: busy ? null : () => generate(edit: true)),
          const SizedBox(height: 12),
          PrototypeButton('Download', onPressed: busy ? null : download),
          TextButton(
              onPressed:
                  busy ? null : () => Navigator.pushNamed(context, '/feedback'),
              child: const Text('Continue to feedback')),
        ],
      ]));
}
