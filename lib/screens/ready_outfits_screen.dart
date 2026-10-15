import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/prototype_ui.dart';
import '../widgets/outfit_catalog.dart';
import 'personal_cloth_measurement_screen.dart';

class ReadyOutfitsScreen extends StatelessWidget {
  const ReadyOutfitsScreen({super.key});
  @override
  Widget build(BuildContext context) => PrototypePage(
        title: 'Ready-made outfits',
        child: Column(children: [
          const Text('Choose a collection'),
          const SizedBox(height: 20),
          for (final category in outfitCategories)
            Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: Icon(
                      category == 'Wedding'
                          ? Icons.favorite_border
                          : category == 'Professional Clothes'
                              ? Icons.work_outline
                              : Icons.checkroom,
                      color: prototypeBrown),
                  title: Text(category),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              OutfitCollectionScreen(category: category))),
                )),
        ]),
      );
}

class OutfitCollectionScreen extends StatefulWidget {
  const OutfitCollectionScreen({super.key, required this.category});
  final String category;
  @override
  State<OutfitCollectionScreen> createState() => _OutfitCollectionScreenState();
}

class _OutfitCollectionScreenState extends State<OutfitCollectionScreen> {
  String? gender;
  OutfitReference? selected;
  String headwear = 'Kumma';
  bool bisht = false;
  String? cameraPhoto;
  bool capturing = false;
  String? profession;
  final otherProfession = TextEditingController();
  bool get professional => widget.category == 'Professional Clothes';
  bool get canChoosePhoto =>
      gender != null && (!professional || profession != null);
  List<OutfitReference> get visibleOutfits => gender == null
      ? []
      : outfitsFor(widget.category, gender!)
          .where((o) => !professional || o.name == profession)
          .toList();
  @override
  void dispose() {
    otherProfession.dispose();
    super.dispose();
  }

  Future<void> captureClothing(
      [ImageSource source = ImageSource.camera]) async {
    if (capturing || !canChoosePhoto) return;
    setState(() => capturing = true);
    try {
      final photo = await ImagePicker().pickImage(
          source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 90);
      if (photo == null || !mounted) return;
      setState(() {
        cameraPhoto = photo.path;
        selected = null;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Could not open the camera or gallery. Check permissions and try again.')));
      }
    } finally {
      if (mounted) setState(() => capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
        title: widget.category,
        child: Column(children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const ['Male', 'Female']
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: capturing
                ? null
                : (value) => setState(() {
                      gender = value;
                      selected = null;
                      cameraPhoto = null;
                      headwear = 'Kumma';
                      bisht = false;
                    }),
          ),
          if (professional && gender != null) ...[
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Profession'),
              initialValue: profession,
              items: professionOptions
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: capturing
                  ? null
                  : (value) => setState(() {
                        profession = value;
                        selected = null;
                        cameraPhoto = null;
                        otherProfession.clear();
                      }),
            ),
            if (profession == 'Other')
              TextField(
                  controller: otherProfession,
                  maxLength: 80,
                  decoration:
                      const InputDecoration(labelText: 'Profession name'),
                  onChanged: (_) => setState(() {})),
            if (profession != null && visibleOutfits.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'Add a photo of the Omani work outfit from your camera or gallery. A verified local reference is not available yet.',
                      textAlign: TextAlign.center)),
            if (visibleOutfits.isNotEmpty)
              const Text(
                  'Illustrative workwear. Uniforms may differ by employer.',
                  textAlign: TextAlign.center),
          ],
          TextButton.icon(
            onPressed:
                !canChoosePhoto || capturing ? null : () => captureClothing(),
            icon: const Icon(Icons.camera_alt),
            label:
                Text(capturing ? 'Opening camera…' : 'Take a clothing photo'),
          ),
          TextButton.icon(
              onPressed: !canChoosePhoto || capturing
                  ? null
                  : () => captureClothing(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose clothing photo')),
          if (cameraPhoto != null) ...[
            Image.file(File(cameraPhoto!), height: 250, fit: BoxFit.contain),
            const Text('Your clothing photo is selected'),
            TextButton(
                onPressed:
                    capturing ? null : () => setState(() => cameraPhoto = null),
                child: const Text('Remove photo')),
          ],
          if (gender == null)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Select a gender to see available outfits.')),
          if (gender != null)
            for (final outfit in visibleOutfits)
              Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: capturing
                        ? null
                        : () => setState(() {
                              selected = outfit;
                              cameraPhoto = null;
                            }),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(children: [
                          Image.asset(outfit.path,
                              height: 250, fit: BoxFit.contain),
                          ListTile(
                              title: Text(outfit.name),
                              subtitle: Text(outfit.details),
                              trailing: Icon(
                                  selected == outfit
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: prototypeBrown)),
                        ])),
                  )),
          if (gender == 'Male' && widget.category == 'Traditional Clothes') ...[
            DropdownButtonFormField<String>(
                initialValue: headwear,
                decoration: const InputDecoration(labelText: 'Headwear'),
                items: const ['Kumma', 'Massar', 'None']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => headwear = v!)),
            SwitchListTile(
                title: const Text('Add Bisht'),
                value: bisht,
                onChanged: (v) => setState(() => bisht = v)),
          ],
          const SizedBox(height: 20),
          PrototypeButton('Try this outfit',
              onPressed: capturing ||
                      gender == null ||
                      (selected == null && cameraPhoto == null) ||
                      (professional &&
                          profession == 'Other' &&
                          otherProfession.text.trim().isEmpty)
                  ? null
                  : () {
                      final path = cameraPhoto ?? selected!.path;
                      final details = cameraPhoto != null
                          ? 'Use the photographed garment as the clothing reference.'
                          : selected!.details;
                      final accessories = gender == 'Male' &&
                              widget.category == 'Traditional Clothes'
                          ? 'Headwear: $headwear. Bisht: ${bisht ? 'include' : 'none'}. Apply these choices even if the reference differs.'
                          : '';
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PersonalClothMeasurementScreen(
                                  initialClothing: path,
                                  outfitDetails:
                                      '$gender. ${widget.category}. ${professional ? 'Profession in Oman: ${profession == 'Other' ? otherProfession.text.trim() : profession}.' : ''} $details $accessories')));
                    }),
        ]),
      );
}
