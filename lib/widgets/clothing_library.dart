import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'prototype_ui.dart';
import 'outfit_catalog.dart';

final clothingTemplates = <String, String>{
  for (final outfit in outfitReferences) outfit.path: outfit.name,
  'images/omani_men.png': 'Omani dishdasha',
  'images/omani_groom.png': 'Omani groom — Massar & Bisht',
  'images/omani_women.png': 'Omani-inspired women’s outfit',
  'images/bridal_lace.png': 'Lace wedding dress',
  'images/bridal_satin.png': 'Satin wedding dress',
};

Future<String?> chooseClothingTemplate(BuildContext context, {String? gender}) {
  String? selectedGender =
      gender == 'Male' || gender == 'Female' ? gender : null;
  String category = outfitCategories.first;
  bool capturing = false;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: prototypeBackground,
    builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .8,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      const Expanded(
                          child: Text('Ready-made outfits',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold))),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close)),
                    ]),
                  ),
                  const Text('Included in the app • Tap an outfit to use it'),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(children: [
                        DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration:
                                const InputDecoration(labelText: 'Collection'),
                            items: outfitCategories
                                .map((v) =>
                                    DropdownMenuItem(value: v, child: Text(v)))
                                .toList(),
                            onChanged: (v) =>
                                setSheetState(() => category = v!)),
                        DropdownButtonFormField<String>(
                            initialValue: selectedGender,
                            decoration:
                                const InputDecoration(labelText: 'Gender'),
                            items: const ['Male', 'Female']
                                .map((v) =>
                                    DropdownMenuItem(value: v, child: Text(v)))
                                .toList(),
                            onChanged: gender == 'Male' || gender == 'Female'
                                ? null
                                : (v) =>
                                    setSheetState(() => selectedGender = v)),
                      ])),
                  TextButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text(capturing
                        ? 'Opening camera…'
                        : 'Take a clothing photo'),
                    onPressed: capturing
                        ? null
                        : () async {
                            setSheetState(() => capturing = true);
                            try {
                              final photo = await ImagePicker().pickImage(
                                  source: ImageSource.camera,
                                  maxWidth: 1600,
                                  maxHeight: 1600,
                                  imageQuality: 90);
                              if (photo != null && context.mounted) {
                                Navigator.pop(context, photo.path);
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Could not open the camera. Check camera permissions or choose a ready-made outfit.')));
                              }
                            } finally {
                              if (context.mounted) {
                                setSheetState(() => capturing = false);
                              }
                            }
                          },
                  ),
                  Expanded(
                      child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: .58,
                    padding: const EdgeInsets.all(16),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: (selectedGender == null
                            ? <OutfitReference>[]
                            : outfitsFor(category, selectedGender!))
                        .map((o) => MapEntry(o.path, o.name))
                        .map((entry) => Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => Navigator.pop(context, entry.key),
                                child: Column(children: [
                                  Expanded(
                                      child: Image.asset(entry.key,
                                          fit: BoxFit.contain)),
                                  Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(entry.value,
                                          textAlign: TextAlign.center)),
                                ]),
                              ),
                            ))
                        .toList(),
                  )),
                ]),
              ),
            )),
  );
}
