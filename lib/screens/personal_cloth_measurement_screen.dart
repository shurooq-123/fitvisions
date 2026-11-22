import 'photo_editor_screen.dart';
import '../services/app_language.dart';
import '../constants/app_colors.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/app_data_service.dart';
import '../widgets/prototype_ui.dart';
import 'ai_generation_screen.dart';
import '../services/avatar_prompt.dart';
import '../services/body_size_presets.dart';
import '../widgets/measurement_guide.dart';

class PersonalClothMeasurementScreen extends StatefulWidget {
  const PersonalClothMeasurementScreen({super.key});

  @override
  State<PersonalClothMeasurementScreen> createState() =>
      _PersonalClothMeasurementScreenState();
}

class _PersonalClothMeasurementScreenState
    extends State<PersonalClothMeasurementScreen> {
  static const brown = Color(0xFF574543);

  Map<String, String> bodyMeasurements = {};
  String? selectedSize;
  bool inches = false;

  File? clothImage;
  File? personalImage;
  AvatarGender? gender;
  String? savedClothPath;
  String? savedPersonalPath;

  bool loading = false;
  Future<void> pickClothImage() => pickImage('cloth');
  Future<void> pickPersonalImage() => pickImage('personal');

  Future<void> pickImage(String kind) async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final source = await showModalBottomSheet<ImageSource>(
          context: context,
          builder: (context) => SafeArea(
                  child: Wrap(children: [
                ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const AppText('Camera'),
                    onTap: () => Navigator.pop(context, ImageSource.camera)),
                ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const AppText('Album'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery)),
              ])));
      if (source == null) return;
      final image = await ImagePicker().pickImage(
          source: source, maxWidth: 2048, maxHeight: 2048, imageQuality: 90);
      if (image == null || !mounted) return;
      final edited = await editPhoto(context, image.path);
      if (edited == null || !mounted) return;
      final path = await AppDataService.saveImage(edited, kind);
      if (!mounted) return;
      setState(() {
        if (kind == 'cloth') {
          clothImage = File(path.startsWith('gs://') ? edited : path);
          savedClothPath = path;
        } else {
          personalImage = File(path.startsWith('gs://') ? edited : path);
          savedPersonalPath = path;
        }
      });
    } catch (_) {
      if (mounted) {
        showMessage(
            'Could not save the image. Check your connection and storage setup.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> saveData() async {
    if (loading) return;
    final measurements = {
      for (final entry in bodyMeasurements.entries)
        if (entry.value.isNotEmpty) entry.key: entry.value,
    };
    if (!validAvatarMeasurements(measurements)) {
      showMessage(
          'Enter a height of 50–250 cm and valid chest, waist and hip measurements. Shoulder width is optional.');
      return;
    }
    if (clothImage == null) {
      showMessage('Choose a clothing image from your album.');
      return;
    }
    if (gender == null) {
      showMessage('Select Female or Male.');
      return;
    }
    try {
      setState(() => loading = true);

      await AppDataService.saveOrUpdateMeasurements(
        measurements: {
          'measurementType': clothImage == null
              ? 'bodyOnly'
              : personalImage == null
                  ? 'clothOnly'
                  : 'personalAndCloth',
          'height': measurements['Height'],
          'chest': measurements['Chest'],
          'waist': measurements['Waist'],
          'hip': measurements['Hips'],
          'shoulders': measurements['Shoulders'],
          'clothImagePath': savedClothPath,
          'personalImagePath': savedPersonalPath,
        },
      );

      if (!mounted) return;

      showMessage(
        'Measurements saved successfully',
      );

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AiGenerationScreen(
                  title: 'Generate Avatar',
                  measuredBodyReference: true,
                  avatar: true,
                  autoGenerate: true,
                  photos: [
                    if (clothImage != null) clothImage!.path,
                    if (personalImage != null) personalImage!.path
                  ],
                  measurements: measurements,
                  measurementsInInches: inches,
                  clothingPhoto: clothImage?.path,
                  avatarGender: gender,
                  size: selectedSize,
                  personalPhoto: personalImage?.path,
                  prompt: avatarPrompt(measurements,
                      clothing: clothImage != null,
                      person: personalImage != null))));
    } catch (e) {
      if (mounted) showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(text),
        backgroundColor: brown,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => PrototypePage(
              child: Column(children: [
            const PrototypeLogo(width: 225),
            const SizedBox(height: 12),
            const AppText('Generate Avatar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            PrototypePanel(
                child: Column(children: [
              BodyMeasurements(
                avatarSizing: true,
                gender: gender,
                onChanged: (values) => bodyMeasurements = values,
                onSize: (size) => selectedSize = size,
                onUnitChanged: (value) => inches = value,
                afterFields: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: DropdownButtonFormField<AvatarGender>(
                    initialValue: gender,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: tr('Gender'),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: AvatarGender.female, child: AppText('Female')),
                      DropdownMenuItem(
                          value: AvatarGender.male, child: AppText('Male')),
                    ],
                    onChanged: loading
                        ? null
                        : (value) => setState(() => gender = value),
                  ),
                ),
              ),
              photoBox('Clothing image', clothImage, pickClothImage),
              const SizedBox(height: 10),
              photoBox('Personal photo (optional)', personalImage,
                  pickPersonalImage),
              const SizedBox(height: 22),
              PrototypeButton(loading ? 'Saving...' : 'Generate',
                  onPressed: loading ? null : saveData),
            ])),
          ])));
  Widget photoBox(String label, File? file, VoidCallback pick) => Material(
        color: AppColors.panel(context, Colors.white),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.muted(context, Colors.black26)),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: loading ? null : pick,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(children: [
                  Icon(Icons.photo_library_outlined,
                      color: AppColors.ink(context, prototypeBrown)),
                  const SizedBox(width: 8),
                  Expanded(child: AppText(label)),
                ]),
                if (file != null) ...[
                  const SizedBox(height: 8),
                  Image.file(file, height: 110),
                  Wrap(children: [
                    TextButton.icon(
                        icon: const Icon(Icons.zoom_in),
                        label: const AppText('Zoom preview'),
                        onPressed: () => showDialog(
                            context: context,
                            builder: (context) => Dialog(
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                      SizedBox(
                                          height: MediaQuery.sizeOf(context)
                                                  .height *
                                              .6,
                                          child: InteractiveViewer(
                                              minScale: .5,
                                              maxScale: 5,
                                              child: Image.file(file))),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const AppText('Close'))
                                    ])))),
                    TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const AppText('Remove'),
                        onPressed: loading
                            ? null
                            : () => setState(() {
                                  if (label.startsWith('Clothing')) {
                                    clothImage = null;
                                    savedClothPath = null;
                                  } else {
                                    personalImage = null;
                                    savedPersonalPath = null;
                                  }
                                })),
                  ]),
                ],
              ]),
            ),
          ),
        ),
      );
}
