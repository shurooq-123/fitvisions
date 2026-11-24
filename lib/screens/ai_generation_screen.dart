import 'ai_assistance_screen.dart';
import 'photo_editor_screen.dart';
import '../services/app_language.dart';
import '../services/clothing_compatibility.dart';
import '../constants/app_colors.dart';
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
import '../widgets/zoomable_result.dart';
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
      this.clothingClassifier,
      this.subscriptionCheck,
      this.autoGenerate = false,
      this.compactDesignResult = false,
      this.initialOutput,
      this.openHistoryEditor = false,
      this.geometryOnly = false,
      this.measuredBodyReference = false});
  final bool openHistoryEditor;
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
  final Future<String> Function(Uint8List)? clothingClassifier;
  final Future<bool> Function()? subscriptionCheck;
  @override
  State<AiGenerationScreen> createState() => _AiGenerationScreenState();
}

class _AiGenerationScreenState extends State<AiGenerationScreen> {
  final changes = TextEditingController();
  final actionUpdates = ValueNotifier(0);
  late final Map<String, TextEditingController> measures;
  String? clothingPhoto;
  String? checkedClothing, checkedCategory;
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
  final previousMeasurements = <String, double?>{};
  int resultRevision = 0;
  late bool inches = widget.measurementsInInches;
  Map<String, String> bodyReferenceMeasurements = const {};
  Uint8List? generatedBodyReference;
  bool busy = false;
  String? error;
  String? pendingHistoryId, pendingHistoryTitle;
  Uint8List? pendingHistoryImage;
  Future<void> retryHistory() async {
    if (pendingHistoryImage == null || busy) return;
    update(() => busy = true);
    try {
      await AppDataService.saveGeneration(pendingHistoryTitle!,
          pendingHistoryImage!, widget.avatar ? 'avatar' : 'clothes',
          recordId: pendingHistoryId, editData: historyEditData);
      if (mounted)
        update(() {
          pendingHistoryImage = null;
          error = null;
        });
    } catch (_) {
      if (mounted)
        update(() => error =
            'History is not saved yet. Check your connection, then retry.');
    } finally {
      if (mounted) update(() => busy = false);
    }
  }

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
    if (widget.openHistoryEditor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted)
          avatarAction(context, 'edit', closeOptionsAfterEdit: false);
      });
    }
    if (widget.autoGenerate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) generate();
      });
    }
  }

  Map<String, dynamic> get historyEditData => {
        'measurements': currentMeasurements,
        'gender': widget.avatarGender?.name ?? '',
        'prompt': widget.prompt,
        'outfitDetails': widget.outfitDetails,
      };
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
    final old = double.tryParse(currentMeasurements[key] ?? '');
    update(() {
      previousMeasurements[key] = old;
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
                  AppText('Payment could not be verified. Please try again.')));
        }
      }
      if (mounted) update(() => unlocked = paid);
      return mounted && paid;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                AppText('Could not check your subscription. Please retry.')));
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
            title: widget.avatar ? 'Edit avatar' : 'Edit clothing design',
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
                          final previousRevision = resultRevision;
                          await applyChanges();
                          if (!editorContext.mounted ||
                              ModalRoute.of(editorContext)?.isCurrent != true ||
                              resultRevision == previousRevision) {
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

  Future<void> applyChanges() => generate(edit: true);

  Future<void> replaceClothing() async {
    if (busy) return;
    if (widget.generator == null &&
        (!await checkout(avatarAction: 'edit') || !mounted)) return;
    final selected = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (selected != null && mounted) {
      final edited = await editPhoto(context, selected.path);
      if (edited == null || !mounted) return;
      update(() {
        clothingPhoto = edited;
        structureChanged = true;
      });
    }
  }

  Future<void> generate({bool edit = false}) async {
    if (busy) return;
    if ((output != null || edit) &&
        (widget.generator == null || widget.subscriptionCheck != null)) {
      if (!await checkout(avatarAction: 'edit') || !mounted) return;
    }
    if (pendingHistoryImage != null) {
      update(() => error =
          'Save the current result to History before generating another.');
      return;
    }
    final measurements = currentMeasurements;
    if (measures.isNotEmpty && !validAvatarMeasurements(measurements)) {
      update(() => error = measurements.entries
          .where((e) => measurementError(e.key, e.value) != null)
          .map((e) => '${tr(e.key)}: ${measurementError(e.key, e.value)}')
          .join(' • '));
      return;
    }
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
        !(widget.openHistoryEditor
            ? validAvatarMeasurements(measurements)
            : validMeasurements(measurements))) {
      update(() => error = 'Enter valid positive measurements in cm and kg.');
      return;
    }
    if (edit &&
        !structureChanged &&
        !mapEquals(currentMeasurements, resultMeasurements)) {
      structureChanged = true;
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
      if ((widget.generator == null || widget.clothingClassifier != null) &&
          clothingPhoto != null &&
          widget.avatarGender != null) {
        if (checkedClothing != clothingPhoto || checkedCategory == 'unknown') {
          checkedCategory = await (widget.clothingClassifier ??
              AiGenerationService
                  .clothingCategory)(await imageReference(clothingPhoto!));
          checkedClothing = clothingPhoto;
        }
        final mismatch = clothingMismatch(
            widget.avatarGender!, checkedCategory ?? 'unknown');
        if (mismatch != null) throw Exception(mismatch);
      }
      final result = hasMeasuredPreview
          ? await generateCloudAvatar(measurements, edit: edit)
          : await generateImage(measurements, edit: edit);
      if (!mounted) return;
      update(() {
        output = result;
        resultRevision++;
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
          pendingHistoryId =
              '${AppDataService.requireUser().uid}_${AppDataService.firestore.collection('history').doc().id}';
          pendingHistoryTitle = description;
          pendingHistoryImage = result;
          await AppDataService.saveGeneration(
              description, result, widget.avatar ? 'avatar' : 'clothes',
              recordId: pendingHistoryId, editData: historyEditData);
          pendingHistoryImage = null;
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
          'shoulders': measurements['Shoulders'],
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
              MeasurementAvatar(measurements,
                  garment: AvatarGarment.separates, gender: gender),
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
            hasPortrait: widget.personalPhoto != null),
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
      ZoomableResult(
          child: Image.memory(avatarViews[avatarView] ?? output!,
              gaplessPlayback: true,
              semanticLabel: '${avatarView.label} avatar view')),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          tooltip: tr('Previous avatar view'),
          onPressed: canRotate ? () => rotateAvatar(-1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        DropdownButton<AvatarViewAngle>(
          value: avatarView,
          items: [
            for (final angle in AvatarViewAngle.values)
              DropdownMenuItem(value: angle, child: AppText(angle.label)),
          ],
          onChanged: !canRotate
              ? null
              : (angle) {
                  if (angle != null) showAvatarView(angle);
                },
        ),
        IconButton(
          tooltip: tr('Next avatar view'),
          onPressed: canRotate ? () => rotateAvatar(1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ]),
      if (loadingView case final angle?) ...[
        const LinearProgressIndicator(),
        AppText('Generating ${angle.label.toLowerCase()} view…'),
      ],
      if (viewError != null)
        AppText(viewError!,
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
      const AppText('Your measurements',
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
                color: AppColors.panel(context, Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.adaptive(context, const Color(0xFFEAD7DF),
                        const Color(0xFF624554))),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0D85465F),
                      blurRadius: 10,
                      offset: Offset(0, 3))
                ],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(name,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.ink(context, prototypeBrown))),
                    const SizedBox(height: 4),
                    AppText('${displayMeasurement(value)} $measurementUnit',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ]),
            ),
        ]);
      }),
      const SizedBox(height: 8),
      const AppText('Entered values • AI preview is approximate',
          style: TextStyle(fontSize: 12)),
    ]);
  }

  Future<Uint8List> generateImage(Map<String, String> measurements,
      {required bool edit}) async {
    final photos = <Uint8List>[];
    final editImage = edit &&
        output != null &&
        (widget.openHistoryEditor || !structureChanged);
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
    final genderInstruction = widget.avatarGender == null
        ? ''
        : ' The avatar must remain an adult ${widget.avatarGender!.subject}, including for unisex garments. Use the entered body measurements; do not copy the reference model body or gender. ';
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
          ? 'Edit reference image 0: $editInstructions. ${structureChanged ? 'Reshape the same dressed figure using these body measurements in cm: $measurements. Preserve the garment design.' : ''} $genderInstruction $bodyInstruction Preserve all other details. Fully clothed, non-explicit fashion image. ${widget.outfitDetails}'
          : '${widget.outfitDetails} $basePrompt$genderInstruction$bodyInstruction ${edit ? 'Additional requested changes: $editInstructions' : ''}',
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
    if (busy || output == null) return;
    if (widget.generator == null &&
        (!await checkout(avatarAction: 'download') || !mounted)) return;
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: AppText('Saved to Downloads / FitVisions.')));
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
        if (pendingHistoryImage != null)
          TextButton.icon(
              onPressed: busy ? null : retryHistory,
              icon: const Icon(Icons.cloud_upload),
              label: const AppText('Retry saving history')),
        if (busy)
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const CircularProgressIndicator(),
                if (!widget.compactDesignResult) ...[
                  const SizedBox(height: 12),
                  const AppText('Preparing your result…'),
                ],
              ])),
        if (error != null)
          Padding(
              padding: const EdgeInsets.all(12),
              child:
                  AppText(error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 12),
      ];

  List<Widget> editorFields() => [
        if (widget.avatar && measures.isNotEmpty)
          ExpansionTile(
              title: const AppText('Edit measurements / clothing'),
              initiallyExpanded: hasMeasuredPreview,
              children: [
                if (hasMeasuredPreview)
                  DropdownButton<bool>(
                    isExpanded: true,
                    value: inches,
                    items: const [
                      DropdownMenuItem(
                          value: false, child: AppText('Centimetres (cm)')),
                      DropdownMenuItem(
                          value: true, child: AppText('Inches (in)')),
                    ],
                    onChanged: busy ? null : changeMeasurementUnit,
                  ),
                for (final entry in measures.entries)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        SizedBox(
                            width: 100,
                            child: MeasurementLabel(entry.key,
                                value: double.tryParse(
                                    currentMeasurements[entry.key] ?? ''),
                                previous: previousMeasurements[entry.key])),
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
                                    errorText: entry.value.text.isEmpty
                                        ? null
                                        : measurementError(entry.key,
                                            currentMeasurements[entry.key]),
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
                      label: const AppText('Change clothing photo')),
                if (!hasMeasuredPreview && clothingPhoto != null)
                  const AppText('Clothing photo selected'),
                if (!hasMeasuredPreview) const MeasurementGuide(),
              ]),
        const SizedBox(height: 12),
        if (!hasMeasuredPreview && !widget.compactDesignResult)
          AppText(widget.avatar
              ? suggestedSize(currentMeasurements)
              : 'Size suggestion: use ${widget.size ?? 'your chosen size'} as a starting point and compare the brand chart. Do not change your body measurements to match a size.'),
        const SizedBox(height: 12),
        const AppText('Change clothing colour',
            style: TextStyle(fontWeight: FontWeight.bold)),
        if (showEditDescription)
          const AppText(
              'Choose a colour, then tap Apply changes. AI colour matching is approximate.',
              textAlign: TextAlign.center),
        Wrap(
            spacing: 8,
            children: palette.entries
                .map((colour) => ChoiceChip(
                    avatar:
                        CircleAvatar(backgroundColor: colour.value, radius: 9),
                    label: AppText(colour.key),
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
          AppText(
              colourChanges.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join(' • '),
              textAlign: TextAlign.center),
          TextButton(
              onPressed: busy ? null : () => update(colourChanges.clear),
              child: const AppText('Clear colour choices')),
        ],
        const SizedBox(height: 16),
        if (showEditDescription)
          TextField(
              controller: changes,
              enabled: !busy,
              maxLength: 500,
              maxLines: 2,
              decoration: InputDecoration(
                  labelText: tr('Describe your changes'),
                  hintText:
                      trError('Change the colour, sleeves or embroidery'))),
      ];

  @override
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => PrototypePage(
          title: widget.title,
          nav: !hasMeasuredPreview,
          child: Column(children: [
            if (!hasMeasuredPreview && !widget.compactDesignResult)
              AppText(
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
                  : ZoomableResult(
                      child: Image.memory(output!, gaplessPlayback: true)),
            if (output != null && !widget.geometryOnly)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(children: [
                        const AppText('You May Also Like',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const AppText(
                            'Discover complementary clothing, colours and styles.'),
                        TextButton.icon(
                            icon: const Icon(Icons.auto_awesome),
                            label: const AppText('Show suggestions'),
                            onPressed: busy
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AiAssistanceScreen(
                                              recommendations: true,
                                              referenceImage: output,
                                              initialMeasurements:
                                                  resultMeasurements.isNotEmpty
                                                      ? resultMeasurements
                                                      : {
                                                          for (final e
                                                              in measures
                                                                  .entries)
                                                            e.key: e.value.text
                                                        },
                                              clothingContext:
                                                  'Selected garment: ${widget.outfitDetails.isNotEmpty ? widget.outfitDetails : garmentCut?.name ?? "uploaded outfit"}. Gender: ${widget.avatarGender?.name ?? "not specified"}. Colour: ${widget.preferredColour ?? "not specified"}. ${changes.text}',
                                            )))),
                      ]))),
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
                  child: AppText(
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
                onPressed:
                    busy || loadingView != null ? null : showAvatarActions,
                child: const AppText('Continue'),
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
              const AppText(
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
                  child: const AppText('Edit body dimensions')),
            ],
            if (output != null &&
                unlocked &&
                !widget.geometryOnly &&
                !hasMeasuredPreview &&
                !widget.compactDesignResult) ...[
              const AppText('Demo access unlocked • No real payment',
                  style: TextStyle(fontSize: 12)),
              ...editorFields(),
              PrototypeButton('Apply changes',
                  onPressed: busy || checkingOut ? null : applyChanges),
              const SizedBox(height: 12),
              PrototypeButton('Download', onPressed: busy ? null : download),
              TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.pushNamed(context, '/feedback'),
                  child: const AppText('Feedback')),
            ],
          ])));
}
