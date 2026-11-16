import 'package:flutter/material.dart';
import '../widgets/prototype_ui.dart';
import '../widgets/outfit_catalog.dart';
import 'personal_cloth_measurement_screen.dart';

class ReadyOutfitsScreen extends StatefulWidget {
  const ReadyOutfitsScreen({super.key});
  @override
  State<ReadyOutfitsScreen> createState() => _ReadyOutfitsScreenState();
}

class _ReadyOutfitsScreenState extends State<ReadyOutfitsScreen> {
  String query = '';
  List<String> get categories => outfitCategories
      .where((category) =>
          category.toLowerCase().contains(query.trim().toLowerCase()) ||
          outfitReferences.any((o) =>
              o.category == category &&
              '${o.name} ${o.details}'
                  .toLowerCase()
                  .contains(query.trim().toLowerCase())) ||
          (category == 'Professional Clothes' &&
              professionOptions.any(
                  (p) => p.toLowerCase().contains(query.trim().toLowerCase()))))
      .toList();
  @override
  Widget build(BuildContext context) => PrototypePage(
        title: 'Try Ready-made Outfits',
        child: Column(children: [
          OutfitSearchField(
              onChanged: (value) => setState(() => query = value)),
          const SizedBox(height: 12),
          const Text('Choose a collection'),
          if (categories.isEmpty)
            const Text('No matching outfits. Try another search.'),
          const SizedBox(height: 20),
          for (final category in categories)
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
                          builder: (_) => OutfitCollectionScreen(
                              category: category,
                              initialQuery: category
                                      .toLowerCase()
                                      .contains(query.trim().toLowerCase())
                                  ? ''
                                  : query.trim()))),
                )),
        ]),
      );
}

class OutfitCollectionScreen extends StatefulWidget {
  const OutfitCollectionScreen(
      {super.key, required this.category, this.initialQuery = ''});
  final String initialQuery;
  final String category;
  @override
  State<OutfitCollectionScreen> createState() => _OutfitCollectionScreenState();
}

class _OutfitCollectionScreenState extends State<OutfitCollectionScreen> {
  late String query;
  String? gender;
  OutfitReference? selected;
  String headwear = 'Kumma';
  bool bisht = false;
  String? profession;
  final otherProfession = TextEditingController();
  @override void initState() { super.initState(); query = widget.initialQuery; }
  bool get professional => widget.category == 'Professional Clothes';
  List<OutfitReference> get availableOutfits => gender == null
      ? []
      : outfitsFor(widget.category, gender!)
          .where((o) =>
              !professional || profession == null || o.name == profession)
          .toList();
  List<OutfitReference> get visibleOutfits => availableOutfits
      .where((o) => '${o.name} ${o.details}'
          .toLowerCase()
          .contains(query.trim().toLowerCase()))
      .toList();
  @override
  void dispose() {
    otherProfession.dispose();
    super.dispose();
  }

  void openOutfit() {
    final path = selected?.path;
    final details = selected?.details ??
        'Design appropriate Omani workwear for the selected profession.';
    final accessories = gender == 'Male' &&
            widget.category == 'Traditional Clothes'
        ? 'Headwear: $headwear. Bisht: ${bisht ? 'include' : 'none'}. Apply these choices even if the reference differs.'
        : '';
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PersonalClothMeasurementScreen(
                initialClothing: path,
                readyMade: true,
                outfitDetails:
                    '$gender. ${widget.category}. ${professional ? 'Profession in Oman: ${profession == 'Other' ? otherProfession.text.trim() : profession}.' : ''} $details $accessories')));
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
        title: widget.category,
        child: Column(children: [
          OutfitSearchField(
              initialQuery: widget.initialQuery,
              onChanged: (value) => setState(() => query = value)),
          const SizedBox(height: 12),
          if (gender != null &&
              visibleOutfits.isEmpty &&
              availableOutfits.isNotEmpty)
            const Text('No matching outfits. Try another search.'),
          DropdownButtonFormField<String>(
            initialValue: gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const ['Male', 'Female']
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (value) => setState(() {
              gender = value;
              selected = null;
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
              onChanged: (value) => setState(() {
                profession = value;
                selected = null;
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
            if (profession != null && availableOutfits.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'No catalog image is available for this profession. Select it below to create an illustrative Omani outfit.',
                      textAlign: TextAlign.center)),
            if (visibleOutfits.isNotEmpty)
              const Text(
                  'Illustrative workwear. Uniforms may differ by employer.',
                  textAlign: TextAlign.center),
          ],
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
          if (gender == null)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Select a gender to see available outfits.')),
          if (gender != null)
            for (final outfit in visibleOutfits)
              Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selected = outfit;
                      });
                      openOutfit();
                    },
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
          const SizedBox(height: 20),
          if (professional && profession != null && availableOutfits.isEmpty)
            ListTile(
              title: Text(
                  profession == 'Other' ? 'Use this profession' : profession!),
              trailing: const Icon(Icons.chevron_right),
              onTap:
                  profession == 'Other' && otherProfession.text.trim().isEmpty
                      ? null
                      : openOutfit,
            ),
        ]),
      );
}

class OutfitSearchField extends StatefulWidget {
  const OutfitSearchField(
      {super.key, this.initialQuery = '', required this.onChanged});
  final String initialQuery;
  final ValueChanged<String> onChanged;
  @override
  State<OutfitSearchField> createState() => _OutfitSearchFieldState();
}

class _OutfitSearchFieldState extends State<OutfitSearchField> {
  late final controller = TextEditingController(text: widget.initialQuery);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
        decoration: InputDecoration(
          hintText: 'Search outfits or professions',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    setState(() {});
                    widget.onChanged('');
                  }),
          filled: true,
          fillColor: prototypeCard,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none),
        ),
      );
}
