import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_generation_service.dart';
import '../services/avatar_prompt.dart';
import '../services/measurement_avatar.dart';
import '../services/body_size_presets.dart';
import '../widgets/measurement_avatar_view.dart';
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
      this.measurementsInInches = false,
      this.clothingPhoto,
      this.garmentType,
      this.avatarGender,
      this.personalPhoto,
      this.preferredColour,
      this.size,
      this.outfitDetails = '',
      this.generator,
      this.subscriptionCheck,
      this.autoGenerate = false,
      this.compactDesignResult = false,
      this.initialOutput,
      this.geometryOnly = false,
      this.measuredBodyReference = false});
  final Uint8List? initialOutput;
  final bool geometryOnly;
  final bool measuredBodyReference;
  final bool autoGenerate;
  final bool compactDesignResult;
  final String title, prompt;
  final String outfitDetails;
  final List<String> photos;
  final DressReference? dressReference;
  final bool avatar;
  final Map<String, String> measurements;
  final bool measurementsInInches;
  final String? clothingPhoto, personalPhoto, preferredColour, size;
  final AvatarGarment? garmentType;
  final AvatarGender? avatarGender;
  final Future<Uint8List> Function(String, List<Uint8List>)? generator;
  final Future<bool> Function()? subscriptionCheck;
  @override
  State<AiGenerationScreen> createState() => _AiGenerationScreenState();
}

class _AiGenerationScreenState extends State<AiGenerationScreen> {
  final changes = TextEditingController();
  final actionUpdates = ValueNotifier(0);
  late final Map<String, TextEditingController> measures;
  String? clothingPhoto;
  bool unlocked = false, checkingOut = false, structureChanged = false;
  Uint8List? output;
  final avatarViews = <AvatarViewAngle, Uint8List>{};
  AvatarViewAngle avatarView = AvatarViewAngle.front;
  AvatarViewAngle? loadingView;
  String? viewError;
  Map<String, String> resultMeasurements = const {};
  late final AvatarGarment? garmentCut;
  late final int avatarSeed = Random().nextInt(1 << 31);
  final editedCentimetres = <String, String>{};
  late bool inches = widget.measurementsInInches;
  Map<String, String> bodyReferenceMeasurements = const {};
  Uint8List? generatedBodyReference;
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
  bool get hasMeasuredPreview => widget.avatar && widget.measuredBodyReference;
  bool get showEditDescription =>
      !hasMeasuredPreview && !widget.compactDesignResult;
  String get measurementUnit => inches ? 'in' : 'cm';
  Future<bool> get activeSubscription =>
      (widget.subscriptionCheck ?? AppDataService.hasActiveSubscription)();
  @override
  void initState() {
    super.initState();
    output = widget.initialOutput;
    if (widget.generator == null && !hasMeasuredPreview) loadSubscription();
    clothingPhoto = widget.clothingPhoto;
    garmentCut = widget.garmentType ??
        (widget.avatarGender == null ? suggestedGarmentCut() : null);
    measures = {
      for (final entry in widget.measurements.entries)
        if (!hasMeasuredPreview || entry.key != 'Weight')
          entry.key: TextEditingController(
            text: hasMeasuredPreview
                ? displayMeasurement(entry.value)
                : entry.value,
          ),
      if (hasMeasuredPreview && !widget.measurements.containsKey('Shoulders'))
        'Shoulders': TextEditingController(),
    };
    if (widget.autoGenerate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) generate();
      });
    }
  }

  void update(VoidCallback change) {
    setState(change);
    actionUpdates.value++;
  }

  Future<void> loadSubscription() async {
    try {
      final active = await activeSubscription;
      if (mounted) update(() => unlocked = active);
    } catch (_) {
      // Checkout performs an explicit retry and reports connection failures.
    }
  }

  String displayMeasurement(String centimetres) {
    if (!inches) return centimetres;
    final value = double.tryParse(centimetres);
    return value == null ? centimetres : (value / 2.54).toStringAsFixed(2);
  }

  void changeMeasurementUnit(bool? useInches) {
    if (useInches == null || useInches == inches) return;
    update(() {
      inches = useInches;
      for (final entry in measures.entries) {
        entry.value.text = displayMeasurement(measurementValue(entry));
      }
    });
  }

  String measurementValue(MapEntry<String, TextEditingController> entry) =>
      (hasMeasuredPreview
              ? editedCentimetres[entry.key] ??
                  widget.measurements[entry.key] ??
                  ''
              : entry.value.text)
          .trim();

  Map<String, String> get currentMeasurements => {
        for (final entry in measures.entries)
          if (measurementValue(entry).isNotEmpty)
            entry.key: measurementValue(entry),
      };

  void editMeasurement(String key, String text) {
    update(() {
      if (hasMeasuredPreview) {
        final value = double.tryParse(text);
        editedCentimetres[key] =
            inches && value != null ? (value * 2.54).toStringAsFixed(3) : text;
      }
      structureChanged = true;
    });
  }

  Future<bool> checkout({String? avatarAction}) async {
    if (checkingOut || busy) return false;
    update(() => checkingOut = true);
    try {
      final active = await activeSubscription;
      if (!mounted) return false;
      var paid = active;
      if (!paid) {
        final completed =
            await Navigator.pushNamed(context, '/subscription', arguments: {
                  'returnToDesign': true,
                  if (avatarAction != null) 'avatarAction': avatarAction,
                }) ==
                true;
        if (!mounted) return false;
        paid = completed && (avatarAction == null || await activeSubscription);
        if (mounted && completed && !paid) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Payment could not be verified. Please try again.')));
        }
      }
      if (mounted) update(() => unlocked = paid);
      return mounted && paid;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not check your subscription. Please retry.')));
      }
      return false;
    } finally {
      if (mounted) update(() => checkingOut = false);
    }
  }

  Future<void> avatarAction(BuildContext actionsContext, String action,
      {bool closeOptionsAfterEdit = true}) async {
    if (!await checkout(avatarAction: action) || !mounted) return;
    if (!actionsContext.mounted ||
        ModalRoute.of(actionsContext)?.isCurrent != true) {
      return;
    }
    if (action == 'download') {
      await download();
    } else {
      final startingUnit = inches;
      final applied =
          await Navigator.of(actionsContext).push(MaterialPageRoute<bool>(
        builder: (editorContext) => ListenableBuilder(
          listenable: actionUpdates,
          builder: (_, __) => PrototypePage(
            title: 'Edit avatar',
            nav: false,
            child: Column(children: [
              ...editorFields(),
              ...operationStatus(),
              PrototypeButton('Apply changes',
                  onPressed: busy || checkingOut
                      ? null
                      : () async {
                          if (hasMeasuredPreview &&
                              inches != startingUnit &&
                              !structureChanged &&
                              editInstructions.isEmpty) {
                            Navigator.pop(editorContext, true);
                            return;
                          }
                          final previous = output;
                          await applyChanges();
                          if (!editorContext.mounted ||
                              ModalRoute.of(editorContext)?.isCurrent != true ||
                              identical(output, previous)) {
                            return;
                          }
                          Navigator.pop(editorContext, true);
                        }),
            ]),
          ),
        ),
      ));
      if (closeOptionsAfterEdit &&
          applied == true &&
          actionsContext.mounted &&
          ModalRoute.of(actionsContext)?.isCurrent == true) {
        Navigator.pop(actionsContext);
      }
    }
  }

  void showAvatarActions() {
    Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (actionsContext) => ListenableBuilder(
            listenable: actionUpdates,
            builder: (_, __) => PrototypePage(
              title: 'Avatar options',
              nav: false,
              child: Column(children: [
                PrototypeButton('Edit',
                    onPressed: busy || checkingOut
                        ? null
                        : () => avatarAction(actionsContext, 'edit')),
                const SizedBox(height: 12),
                PrototypeButton('Download',
                    onPressed: busy || checkingOut
                        ? null
                        : () => avatarAction(actionsContext, 'download')),
                ...operationStatus(),
              ]),
            ),
          ),
        ));
  }

  Future<void> applyChanges() async {
    if ((hasMeasuredPreview || widget.compactDesignResult) &&
        (!await checkout(avatarAction: 'edit') || !mounted)) {
      return;
    }
    await generate(edit: true);
  }

  Future<void> replaceClothing() async {
    if (!unlocked || busy) return;
    final selected = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (selected != null && mounted) {
      update(() {
        clothingPhoto = selected.path;
        structureChanged = true;
      });
    }
  }

  Future<void> generate({bool edit = false}) async {
    if (busy) return;
    if (output != null && !unlocked) return;
    final measurements = currentMeasurements;
    if (hasMeasuredPreview
        ? !validAvatarMeasurements(measurements)
        : widget.measuredBodyReference &&
            !completeBodyMeasurements(measurements)) {
      update(() => error = hasMeasuredPreview
          ? 'Enter a height of 50–250 cm and valid chest, waist and hips. Check shoulder width if entered.'
          : 'Enter valid height, chest, waist and hips before generating.');
      return;
    }
    if (!hasMeasuredPreview &&
        widget.avatar &&
        measures.isNotEmpty &&
        !validMeasurements(measurements)) {
      update(() => error = 'Enter valid positive measurements in cm and kg.');
      return;
    }
    if (edit && !structureChanged && editInstructions.isEmpty) {
      update(() => error = showEditDescription
          ? 'Describe the changes you want.'
          : 'Choose a colour or change a measurement first.');
      return;
    }
    update(() {
      busy = true;
      error = null;
    });
    try {
      final result = hasMeasuredPreview
          ? await generateCloudAvatar(measurements, edit: edit)
          : await generateImage(measurements, edit: edit);
      if (!mounted) return;
      update(() {
        output = result;
        resultMeasurements = measurements;
        avatarViews.clear();
        avatarView = AvatarViewAngle.front;
        viewError = null;
      });
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
            update(() => error =
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
          'height': measurements['Height'],
          if (!hasMeasuredPreview) 'weight': measurements['Weight'],
          'chest': measurements['Chest'],
          'waist': measurements['Waist'],
          'hip': measurements['Hips'],
          'clothImagePath': clothingPhoto,
          'personalImagePath': widget.personalPhoto,
        });
      }
      structureChanged = false;
    } catch (e) {
      if (mounted) {
        update(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) update(() => busy = false);
    }
  }

  Future<Uint8List> imageReference(String path) async {
    if (path.startsWith('images/')) {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
    return File(path).readAsBytes();
  }

  Future<Uint8List> generateCloudAvatar(Map<String, String> measurements,
      {required bool edit}) async {
    final clothing = clothingPhoto;
    final gender = widget.avatarGender;
    final generator = widget.generator ??
        (String prompt, List<Uint8List> references) =>
            AiGenerationService.generate(prompt, references, seed: avatarSeed);
    final clothingBytes =
        clothing == null ? null : await imageReference(clothing);
    final portrait = widget.personalPhoto;
    var body = generatedBodyReference;
    if (body == null || !mapEquals(bodyReferenceMeasurements, measurements)) {
      final portraitBytes =
          portrait == null ? null : await imageReference(portrait);
      final guide = gender == null
          ? null
          : await renderBodyReferenceSheet(
              MeasurementAvatar(measurements, garment: AvatarGarment.separates),
              includeLabels: false);
      body = await generator(
        cloudMeasuredAvatarPrompt(
          measurements,
          garment: garmentCut,
          hasClothing: false,
          hasPortrait: portraitBytes != null,
          gender: gender,
          hasMeasurementGuide: guide != null,
          size: widget.size,
          bodyReference: true,
        ),
        [if (portraitBytes != null) portraitBytes, if (guide != null) guide],
      );
      bodyReferenceMeasurements = Map.of(measurements);
      generatedBodyReference = body;
    }
    if (!mounted) throw StateError('Avatar generation cancelled');
    final prompt = cloudMeasuredAvatarPrompt(
      measurements,
      garment: garmentCut,
      hasClothing: clothingBytes != null,
      hasPortrait: portrait != null,
      gender: gender,
      size: widget.size,
      changes: edit ? editInstructions : '',
    );
    return generator(prompt, [body, if (clothingBytes != null) clothingBytes]);
  }

  void rotateAvatar(int step) {
    const angles = AvatarViewAngle.values;
    showAvatarView(angles[(avatarView.index + step) % angles.length]);
  }

  Future<void> showAvatarView(AvatarViewAngle angle) async {
    final front = output;
    if (front == null ||
        angle == avatarView ||
        loadingView != null ||
        busy ||
        checkingOut) {
      return;
    }
    if (angle == AvatarViewAngle.front || avatarViews.containsKey(angle)) {
      update(() {
        avatarView = angle;
        viewError = null;
      });
      return;
    }
    update(() {
      loadingView = angle;
      viewError = null;
    });
    try {
      final image = await (widget.generator ?? AiGenerationService.generate)(
        cloudAvatarAnglePrompt(angle,
            hasPortrait:
                widget.personalPhoto != null || widget.avatarGender != null),
        [front],
      );
      if (!mounted) return;
      update(() {
        avatarViews[angle] = image;
        avatarView = angle;
      });
    } catch (e) {
      if (mounted) {
        update(() => viewError = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) update(() => loadingView = null);
    }
  }

  Widget avatarResult() {
    final canRotate = loadingView == null && !busy && !checkingOut;
    return Column(children: [
      GestureDetector(
        onHorizontalDragEnd: !canRotate
            ? null
            : (event) {
                final velocity = event.primaryVelocity ?? 0;
                if (velocity.abs() > 100) rotateAvatar(velocity < 0 ? 1 : -1);
              },
        child: Image.memory(
          avatarViews[avatarView] ?? output!,
          gaplessPlayback: true,
          semanticLabel: '${avatarView.label} avatar view',
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          tooltip: 'Previous avatar view',
          onPressed: canRotate ? () => rotateAvatar(-1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        DropdownButton<AvatarViewAngle>(
          value: avatarView,
          items: [
            for (final angle in AvatarViewAngle.values)
              DropdownMenuItem(value: angle, child: Text(angle.label)),
          ],
          onChanged: !canRotate
              ? null
              : (angle) {
                  if (angle != null) showAvatarView(angle);
                },
        ),
        IconButton(
          tooltip: 'Next avatar view',
          onPressed: canRotate ? () => rotateAvatar(1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ]),
      if (loadingView case final angle?) ...[
        const LinearProgressIndicator(),
        Text('Generating ${angle.label.toLowerCase()} view…'),
      ],
      if (viewError != null)
        Text(viewError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red)),
    ]);
  }

  Widget measurementCards() {
    final values = [
      for (final name in ['Height', 'Shoulders', 'Chest', 'Waist', 'Hips'])
        if (resultMeasurements[name] case final value?) (name, value),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Your measurements',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      LayoutBuilder(builder: (context, constraints) {
        const gap = 10.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final (index, (name, value)) in values.indexed)
            Container(
              width: index == values.length - 1 && values.length.isOdd
                  ? constraints.maxWidth
                  : width,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 12, color: prototypeBrown)),
                    const SizedBox(height: 4),
                    Text('${displayMeasurement(value)} $measurementUnit',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ]),
            ),
        ]);
      }),
      const SizedBox(height: 8),
      const Text('Entered values • AI preview is approximate',
          style: TextStyle(fontSize: 12)),
    ]);
  }

  Future<Uint8List> generateImage(Map<String, String> measurements,
      {required bool edit}) async {
    final photos = <Uint8List>[];
    final editImage = edit && output != null && !structureChanged;
    if (editImage) {
      photos.add(output!);
    } else {
      if (widget.dressReference != null) {
        photos.add(await widget.dressReference!.imageBytes());
      }
      final paths = widget.avatar && measures.isNotEmpty
          ? [
              if (clothingPhoto != null) clothingPhoto!,
              if (widget.personalPhoto != null) widget.personalPhoto!,
            ]
          : widget.photos;
      for (final path in paths) {
        photos.add(await imageReference(path));
      }
    }
    if (widget.measuredBodyReference) {
      photos
          .add(await renderBodyReferenceSheet(MeasurementAvatar(measurements)));
    }
    final bodyInstruction = widget.measuredBodyReference
        ? ' The final reference image is a front and side guide to the measured body. Preserve its silhouette and proportions. Output one dressed figure, with no labels.'
        : '';
    final basePrompt = widget.avatar && measures.isNotEmpty
        ? avatarPrompt(measurements,
            clothing: clothingPhoto != null,
            person: widget.personalPhoto != null)
        : widget.prompt;
    return (widget.generator ?? AiGenerationService.generate)(
      editImage
          ? 'Edit reference image 0: $editInstructions. $bodyInstruction Preserve all other details. Fully clothed, non-explicit fashion image. ${widget.outfitDetails}'
          : '${widget.outfitDetails} $basePrompt$bodyInstruction ${edit ? 'Additional requested changes: $editInstructions' : ''}',
      photos,
    );
  }

  AvatarGarment suggestedGarmentCut() {
    final name = (clothingTemplates[clothingPhoto] ?? '').toLowerCase();
    if (name.contains('dress')) return AvatarGarment.longDress;
    if (name.contains('dishdasha') || name.contains('bisht')) {
      return AvatarGarment.robe;
    }
    return AvatarGarment.separates;
  }

  Future<void> download() async {
    if (!unlocked || busy || output == null) return;
    update(() => busy = true);
    try {
      final codec = await ui.instantiateImageCodec(output!);
      final Uint8List bytes;
      try {
        final image = (await codec.getNextFrame()).image;
        try {
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          if (png == null) throw StateError('Image unavailable');
          bytes = png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
        } finally {
          image.dispose();
        }
      } finally {
        codec.dispose();
      }
      await const MethodChannel('fitvisions/downloads')
          .invokeMethod<String>('savePreview', bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to Downloads / FitVisions.')));
        Navigator.pushNamed(context, '/feedback');
      }
    } catch (_) {
      if (mounted) update(() => error = 'Could not save the image.');
    } finally {
      if (mounted) update(() => busy = false);
    }
  }

  @override
  void dispose() {
    actionUpdates.dispose();
    changes.dispose();
    for (final c in measures.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<Widget> operationStatus() => [
        if (busy)
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const CircularProgressIndicator(),
                if (!widget.compactDesignResult) ...[
                  const SizedBox(height: 12),
                  const Text('Preparing your result…'),
                ],
              ])),
        if (error != null)
          Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 12),
      ];

  List<Widget> editorFields() => [
        if (widget.avatar && measures.isNotEmpty)
          ExpansionTile(
              title: const Text('Edit measurements / clothing'),
              initiallyExpanded: hasMeasuredPreview,
              children: [
                if (hasMeasuredPreview)
                  DropdownButton<bool>(
                    isExpanded: true,
                    value: inches,
                    items: const [
                      DropdownMenuItem(
                          value: false, child: Text('Centimetres (cm)')),
                      DropdownMenuItem(value: true, child: Text('Inches (in)')),
                    ],
                    onChanged: busy ? null : changeMeasurementUnit,
                  ),
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
                                onChanged: (text) =>
                                    editMeasurement(entry.key, text),
                                decoration: InputDecoration(
                                    suffixText: hasMeasuredPreview
                                        ? measurementUnit
                                        : entry.key == 'Weight'
                                            ? 'kg'
                                            : 'cm'))),
                      ])),
                if (!hasMeasuredPreview)
                  TextButton.icon(
                      onPressed: busy ? null : replaceClothing,
                      icon: const Icon(Icons.image),
                      label: const Text('Change clothing photo')),
                if (!hasMeasuredPreview && clothingPhoto != null)
                  const Text('Clothing photo selected'),
                if (!hasMeasuredPreview) const MeasurementGuide(),
              ]),
        const SizedBox(height: 12),
        if (!hasMeasuredPreview && !widget.compactDesignResult)
          Text(widget.avatar
              ? suggestedSize(currentMeasurements)
              : 'Size suggestion: use ${widget.size ?? 'your chosen size'} as a starting point and compare the brand chart. Do not change your body measurements to match a size.'),
        const SizedBox(height: 12),
        const Text('Change clothing colour',
            style: TextStyle(fontWeight: FontWeight.bold)),
        if (showEditDescription)
          const Text(
              'Choose a colour, then tap Apply changes. AI colour matching is approximate.',
              textAlign: TextAlign.center),
        Wrap(
            spacing: 8,
            children: palette.entries
                .map((colour) => ChoiceChip(
                    avatar:
                        CircleAvatar(backgroundColor: colour.value, radius: 9),
                    label: Text(colour.key),
                    selected: colourChanges[colourTarget] == colour.key,
                    onSelected: busy
                        ? null
                        : (selected) => update(() {
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
              onPressed: busy ? null : () => update(colourChanges.clear),
              child: const Text('Clear colour choices')),
        ],
        const SizedBox(height: 16),
        if (showEditDescription)
          TextField(
              controller: changes,
              enabled: !busy,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Describe your changes',
                  hintText: 'Change the colour, sleeves or embroidery')),
      ];

  @override
  Widget build(BuildContext context) => PrototypePage(
      title: widget.title,
      nav: !hasMeasuredPreview,
      child: Column(children: [
        if (!hasMeasuredPreview && !widget.compactDesignResult)
          Text(
              widget.geometryOnly
                  ? 'Measured mannequin render. Estimated anatomy; no clothing-fit guarantee.'
                  : widget.avatar
                      ? '3D-style avatar image. Body measurements and fit are not guaranteed.'
                      : 'Create a clothing concept from your selected preferences.',
              textAlign: TextAlign.center),
        const SizedBox(height: 16),
        if (output != null)
          hasMeasuredPreview
              ? avatarResult()
              : Image.memory(output!, gaplessPlayback: true),
        if (hasMeasuredPreview && resultMeasurements.isNotEmpty) ...[
          const SizedBox(height: 12),
          measurementCards(),
        ],
        if (output == null &&
            !widget.autoGenerate &&
            !hasMeasuredPreview &&
            !widget.compactDesignResult)
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                  'Your design details, measurements and any selected photos will be sent to Cloudflare AI when you tap Generate.')),
        if (output == null ||
            (!hasMeasuredPreview &&
                (!widget.compactDesignResult || busy || error != null)))
          ...operationStatus(),
        if (output == null && (!widget.autoGenerate || error != null))
          PrototypeButton('Generate',
              onPressed: busy ? null : () => generate()),
        if (hasMeasuredPreview && output != null)
          TextButton(
            onPressed: busy || loadingView != null ? null : showAvatarActions,
            child: const Text('Continue'),
          ),
        if (widget.compactDesignResult && output != null)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              PrototypeButton('Edit',
                  onPressed: checkingOut || busy
                      ? null
                      : () => avatarAction(context, 'edit',
                          closeOptionsAfterEdit: false)),
              PrototypeButton('Save',
                  onPressed: checkingOut || busy
                      ? null
                      : () => avatarAction(context, 'download')),
            ],
          ),
        if (output != null &&
            !unlocked &&
            !hasMeasuredPreview &&
            !widget.compactDesignResult) ...[
          const Text(
              'Subscribe and complete the demo payment to edit or download this image. No real charge.',
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          PrototypeButton(checkingOut ? 'Opening…' : 'Edit / Save',
              onPressed: checkingOut || busy ? null : () => checkout()),
        ],
        if (output != null && unlocked && widget.geometryOnly) ...[
          PrototypeButton('Download', onPressed: busy ? null : download),
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Edit body dimensions')),
        ],
        if (output != null &&
            unlocked &&
            !widget.geometryOnly &&
            !hasMeasuredPreview &&
            !widget.compactDesignResult) ...[
          const Text('Demo access unlocked • No real payment',
              style: TextStyle(fontSize: 12)),
          ...editorFields(),
          PrototypeButton('Apply changes',
              onPressed: busy || checkingOut ? null : applyChanges),
          const SizedBox(height: 12),
          PrototypeButton('Download', onPressed: busy ? null : download),
          TextButton(
              onPressed:
                  busy ? null : () => Navigator.pushNamed(context, '/feedback'),
              child: const Text('Feedback')),
        ],
      ]));
}
