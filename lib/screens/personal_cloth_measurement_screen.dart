import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/app_data_service.dart';
import '../widgets/prototype_ui.dart';
import 'ai_generation_screen.dart';
import '../services/avatar_prompt.dart';
import '../widgets/measurement_guide.dart';
import '../widgets/clothing_library.dart';

class PersonalClothMeasurementScreen extends StatefulWidget {
  const PersonalClothMeasurementScreen({super.key, this.initialClothing, this.outfitDetails = ''});
  final String? initialClothing;
  final String outfitDetails;

  @override
  State<PersonalClothMeasurementScreen> createState() =>
      _PersonalClothMeasurementScreenState();
}

class _PersonalClothMeasurementScreenState
    extends State<PersonalClothMeasurementScreen> {
  static const brown = Color(0xFF574543);

  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final chestController = TextEditingController();
  final waistController = TextEditingController();
  final hipController = TextEditingController();

  File? clothImage;
  File? personalImage;
  String? savedClothPath;
  String? savedPersonalPath;

  bool loading = false;
  @override
  void initState() {
    super.initState();
    if (widget.initialClothing != null) {
      clothImage = File(widget.initialClothing!);
      savedClothPath = widget.initialClothing;
    }
  }

  Future<void> pickClothImage() => pickImage('cloth');
  Future<void> pickPersonalImage() => pickImage('personal');

  Future<void> pickImage(String kind) async {
    if (loading) return;
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    setState(() => loading = true);
    try {
      final path = await AppDataService.saveImage(image.path, kind);
      if (!mounted) return;
      setState(() {
        if (kind == 'cloth') {
          clothImage = File(image.path);
          savedClothPath = path;
        } else {
          personalImage = File(image.path);
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
    if (heightController.text.trim().isEmpty ||
        weightController.text.trim().isEmpty ||
        chestController.text.trim().isEmpty ||
        waistController.text.trim().isEmpty ||
        hipController.text.trim().isEmpty) {
      showMessage('Please enter all measurements');
      return;
    }

    final values = [
      heightController,
      weightController,
      chestController,
      waistController,
      hipController
    ].map((c) => double.tryParse(c.text.trim())).toList();
    if (values.any((v) => v == null || !v.isFinite || v <= 0) ||
        values[0]! > 250 ||
        values[1]! > 400 ||
        values.skip(2).any((v) => v! > 300)) {
      showMessage(
          'Enter valid positive measurements: height/chest/waist/hips in cm and weight in kg.');
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
          'height': heightController.text.trim(),
          'weight': weightController.text.trim(),
          'chest': chestController.text.trim(),
          'waist': waistController.text.trim(),
          'hip': hipController.text.trim(),
          'clothImagePath': savedClothPath,
          'personalImagePath': savedPersonalPath,
        },
      );

      if (!mounted) return;

      showMessage(
        'Measurements saved successfully',
      );

      final paths = [
        if (clothImage != null) clothImage!.path,
        if (personalImage != null) personalImage!.path
      ];
      final measurements = {
        'Height': heightController.text.trim(),
        'Weight': weightController.text.trim(),
        'Chest': chestController.text.trim(),
        'Waist': waistController.text.trim(),
        'Hips': hipController.text.trim()
      };
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AiGenerationScreen(
                    title: 'Generate Avatar',
                    avatar: true,
                    outfitDetails: widget.outfitDetails,
                    photos: paths,
                    measurements: measurements,
                    clothingPhoto: clothImage?.path,
                    personalPhoto: personalImage?.path,
                    prompt: avatarPrompt(measurements,
                        clothing: clothImage != null,
                        person: personalImage != null),
                  )));
    } catch (e) {
      showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: brown,
      ),
    );
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    chestController.dispose();
    waistController.dispose();
    hipController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
          child: Column(children: [
        const PrototypeLogo(width: 190, symbolOnly: true),
        const SizedBox(height: 20),
        const Text('Generate Avatar',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        const Text(
            'Hover over or tap a measurement name for help. Photos are optional; without a personal photo we create a synthetic 3D-style avatar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12)),
        const SizedBox(height: 12),
        PrototypePanel(
            child: Column(children: [
          measurementRow('Height', heightController, '175 cm'),
          measurementRow('Weight', weightController, '55 kg'),
          measurementRow('Chest', chestController, '96 cm'),
          measurementRow('Waist', waistController, '75 cm'),
          measurementRow('Hips', hipController, '75 cm'),
          uploadRow('Clothing photo\n(optional)', clothImage, pickClothImage),
          TextButton.icon(
            icon: const Icon(Icons.checkroom),
            label: const Text('Choose a ready-made outfit'),
            onPressed: loading
                ? null
                : () async {
                    final path = await chooseClothingTemplate(context);
                    if (path == null || !mounted) return;
                    setState(() {
                      clothImage = File(path);
                      savedClothPath = path;
                    });
                  },
          ),
          if (clothImage != null) ...[
            if (clothingTemplates.containsKey(clothImage!.path))
              Image.asset(clothImage!.path, height: 160)
            else
              Image.file(clothImage!, height: 160),
            TextButton(
                onPressed: loading
                    ? null
                    : () => setState(() {
                          clothImage = null;
                          savedClothPath = null;
                        }),
                child: const Text('Remove clothing photo')),
          ],
          uploadRow(
              'Personal photo\n(optional)', personalImage, pickPersonalImage),
          if (personalImage != null)
            TextButton(
                onPressed: loading
                    ? null
                    : () => setState(() {
                          personalImage = null;
                          savedPersonalPath = null;
                        }),
                child: const Text('Remove personal photo')),
          const SizedBox(height: 22),
          PrototypeButton(loading ? 'Saving...' : 'Generate',
              onPressed: loading ? null : saveData),
        ])),
        if (!AppDataService.cloudImagesEnabled)
          const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                  'Selected photos are sent to Cloudflare only when you confirm AI generation.',
                  style: TextStyle(fontSize: 11))),
        const MeasurementGuide(),
      ]));
  Widget measurementRow(
          String label, TextEditingController controller, String hint) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            SizedBox(width: 92, child: MeasurementLabel(label)),
            Expanded(
                child: SizedBox(
                    height: 34,
                    child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                            hintText: hint,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            border: const OutlineInputBorder(
                                borderRadius: BorderRadius.zero)))))
          ]));
  Widget uploadRow(String label, File? file, VoidCallback pick) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        SizedBox(width: 92, child: Text(label)),
        Expanded(
            child: InkWell(
                onTap: loading ? null : pick,
                child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black54)),
                    child: Icon(
                        file == null ? Icons.upload_outlined : Icons.check,
                        size: 20,
                        color: prototypeBrown))))
      ]));
}
