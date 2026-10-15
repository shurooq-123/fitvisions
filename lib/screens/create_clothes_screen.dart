import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/ai_generation_service.dart';
import '../widgets/prototype_ui.dart';
import 'ai_generation_screen.dart';
import '../widgets/clothing_library.dart';
import '../services/dress_reference.dart';
import '../widgets/dress_reference_picker.dart';
import '../widgets/favourite_colour_strip.dart';

class CreateClothesScreen extends StatefulWidget {
  const CreateClothesScreen({super.key});
  @override
  State<CreateClothesScreen> createState() => _CreateClothesScreenState();
}

class _CreateClothesScreenState extends State<CreateClothesScreen> {
  final formKey = GlobalKey<FormState>();
  final otherOccasion = TextEditingController();
  final notes = TextEditingController();
  final answers = <String, String>{};
  bool reviewing = false;
  String? template;
  String? facePhoto;
  DressReference? dressReference;
  bool analyzingSkin = false;
  int formRevision = 0;

  static const baseQuestions = <String, List<String>>{
    'Gender / clothing style': ['Female', 'Male', 'Unisex'],
    'Age group': [
      'Child (0–12)',
      'Teen (13–17)',
      'Adult (18–29)',
      'Adult (30–49)',
      'Adult (50+)'
    ],
    'Size': [
      'XS',
      'Small',
      'Medium',
      'Large',
      'XL',
      'XXL',
      'Custom / not sure'
    ],
    'Occasion': [
      'Eid',
      'Bridal dress',
      'Wedding guest',
      'Birthday',
      'Abaya',
      'Other'
    ],
    'Skin tone (optional)': [
      'Prefer not to specify',
      'Fair',
      'Light',
      'Medium',
      'Tan',
      'Deep',
      'Not sure — use camera'
    ],
    'Style': ['Evening', 'Party', 'Soft', 'No preference'],
    'Silhouette': ['Bodycon', 'Sheath', 'Mermaid', 'A-line', 'No preference'],
    'Length': ['Short', 'Midi', 'Long', 'No preference'],
    'Neckline': [
      'Round neck',
      'V-neck',
      'High neck',
      'Off-shoulder',
      'Square',
      'Sweetheart',
      'Cowl',
      'Halter',
      'Strapless',
      'Asymmetric',
      'No preference'
    ],
    'Sleeves': ['Sleeveless', 'Short sleeves', 'Long sleeves', 'No preference'],
    'Fit': ['Loose', 'Regular', 'Fitted', 'No preference'],
    'Fabric': [
      'Cotton',
      'Linen',
      'Satin',
      'Silk',
      'Chiffon',
      'Crepe',
      'Lace',
      'No preference'
    ],
    'Favourite colour': [
      'Black',
      'White',
      'Navy',
      'Blue',
      'Green',
      'Red',
      'Pink',
      'Purple',
      'Beige',
      'Brown',
      'Grey',
      'Teal',
      'Gold',
      'No preference'
    ],
    'Details': ['Minimal', 'Embroidery', 'Lace', 'Beading', 'No preference'],
  };

  Map<String, List<String>> get questions {
    if (answers['Gender / clothing style'] != 'Male') return baseQuestions;
    final type = answers['Outfit type'];
    return {
      'Gender / clothing style': baseQuestions['Gender / clothing style']!,
      'Age group': baseQuestions['Age group']!,
      'Size': baseQuestions['Size']!,
      'Outfit type': [
        'Omani formal wear',
        'Formal suit',
        'Sportswear',
        'Casual outfit'
      ],
      'Occasion': [
        'Eid',
        'Wedding groom',
        'Wedding guest',
        'Work / formal event',
        'Birthday',
        'Sports / training',
        'Everyday',
        'Other'
      ],
      'Skin tone (optional)': baseQuestions['Skin tone (optional)']!,
      if (type == 'Omani formal wear') ...{
        'Headwear': answers['Occasion'] == 'Wedding groom'
            ? ['Massar']
            : ['Kumma', 'Massar', 'No headwear'],
        'Dishdasha collar': ['Traditional Omani collar', 'Simple round collar'],
        'Embroidery': ['Subtle', 'Decorative', 'None'],
      } else if (type == 'Formal suit') ...{
        'Suit style': ['Two-piece', 'Three-piece', 'Blazer and trousers'],
        'Lapel': ['Notch', 'Peak', 'Shawl'],
        'Tie': ['Tie', 'Bow tie', 'No tie'],
      } else if (type == 'Sportswear') ...{
        'Activity': ['Gym', 'Running', 'Football', 'Walking'],
        'Sports top': ['T-shirt', 'Long-sleeve top', 'Zip jacket'],
        'Bottoms': ['Shorts', 'Joggers', 'Track trousers'],
      } else if (type == 'Casual outfit') ...{
        'Top': ['T-shirt', 'Polo', 'Shirt', 'Hoodie'],
        'Bottoms': ['Jeans', 'Chinos', 'Shorts'],
        'Sleeves': ['Short sleeves', 'Long sleeves'],
      },
      'Fit': ['Loose', 'Regular', 'Tailored', 'No preference'],
      'Fabric': type == 'Sportswear'
          ? ['Breathable performance fabric', 'Cotton blend', 'No preference']
          : baseQuestions['Fabric']!,
      'Favourite colour': baseQuestions['Favourite colour']!,
    };
  }

  Future<void> pickFace(ImageSource source) async {
    try {
      final photo = await ImagePicker().pickImage(
          source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 90);
      if (photo == null || !mounted) return;
      setState(() => facePhoto = photo.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Could not open photos. Check permissions and try again.')));
      }
    }
  }

  Future<void> estimateSkin() async {
    if (analyzingSkin) return;
    try {
      final shot = await ImagePicker().pickImage(
          source: ImageSource.camera, maxWidth: 1000, maxHeight: 1000);
      if (shot == null || !mounted) return;
      final approved = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Estimate visible skin tone'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Image.file(File(shot.path), height: 180),
                  const Text(
                      'Use a close-up of your hand or forearm in natural light, without filters. This photo will be sent to Cloudflare AI for an approximate colour estimate, not an ethnicity or medical analysis. Lighting can change the result.'),
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Analyze with Cloudflare'))
                ],
              ));
      if (approved != true || !mounted) return;
      setState(() => analyzingSkin = true);
      final tone = await AiGenerationService.estimateSkin(
          await File(shot.path).readAsBytes());
      if (!mounted) return;
      if (tone == 'Unknown') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'The photo is unclear. Try natural light or choose a tone yourself.')));
        return;
      }
      final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Estimated tone: $tone'),
                content: const Text(
                    'This is an approximate visible colour. You can change it manually.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Choose myself')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Use this tone'))
                ],
              ));
      if (accepted == true && mounted) {
        setState(() {
          answers['Skin tone (optional)'] = tone;
          formRevision++;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => analyzingSkin = false);
    }
  }

  @override
  void dispose() {
    otherOccasion.dispose();
    notes.dispose();
    super.dispose();
  }

  void review() {
    if (analyzingSkin) return;
    if (!formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => reviewing = true);
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
        title: reviewing ? 'Your Clothing Design' : 'Create Clothes',
        child: Column(children: [
          const PrototypeLogo(width: 160, symbolOnly: true),
          const SizedBox(height: 16),
          Text(
              reviewing
                  ? 'Review your choices before generation.'
                  : 'Tell us what you would like to wear.',
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextButton.icon(
            icon: const Icon(Icons.checkroom),
            label: const Text('Choose a ready-made outfit (optional)'),
            onPressed: () async {
              final path = await chooseClothingTemplate(context,
                  gender: answers['Gender / clothing style']);
              if (path == null || !mounted) return;
              setState(() {
                template = path;
                dressReference = null;
              });
            },
          ),
          TextButton.icon(
              icon: const Icon(Icons.collections),
              label: const Text('Browse dress references (50)'),
              onPressed: () async {
                final reference = await chooseDressReference(context, answers);
                if (reference == null || !mounted) return;
                setState(() {
                  dressReference = reference;
                  template = null;
                });
              }),
          if (dressReference != null) ...[
            SizedBox(
                height: 230, child: DressReferencePreview(dressReference!)),
            Text(dressReference!.description, textAlign: TextAlign.center),
            const Text(
                'Your selected preferences take priority where they differ from the reference.'),
            TextButton(
                onPressed: () => setState(() => dressReference = null),
                child: const Text('Remove dress reference')),
          ],
          if (template != null) ...[
            if (clothingTemplates.containsKey(template))
              Image.asset(template!, height: 180)
            else
              Image.file(File(template!), height: 180),
            Text(clothingTemplates[template!] ?? 'Your clothing photo'),
            TextButton(
                onPressed: () => setState(() => template = null),
                child: const Text('Remove outfit')),
          ],
          const Text('Face photo (optional)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Text(
              'Add your face to preview the design on a person. Without a photo, the design uses a headless display.',
              textAlign: TextAlign.center),
          Wrap(alignment: WrapAlignment.center, children: [
            TextButton.icon(
                onPressed: () => pickFace(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery')),
            TextButton.icon(
                onPressed: () => pickFace(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera')),
          ]),
          if (facePhoto != null) ...[
            Image.file(File(facePhoto!), height: 150),
            TextButton(
                onPressed: () => setState(() => facePhoto = null),
                child: const Text('Remove face photo')),
          ],
          const SizedBox(height: 16),
          PrototypePanel(
              radius: 30,
              padding: 20,
              child: reviewing ? summary() : questionnaire()),
          const SizedBox(height: 20),
          if (reviewing && rankedDressReferences(answers).isNotEmpty)
            TextButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Find references for these choices'),
                onPressed: () async {
                  final reference =
                      await chooseDressReference(context, answers);
                  if (reference != null && mounted) {
                    setState(() {
                      dressReference = reference;
                      template = null;
                    });
                  }
                }),
          if (reviewing) ...[
            const Icon(Icons.checkroom, size: 58, color: prototypeBrown),
            const SizedBox(height: 10),
            const Text(
                'Generate a clothing concept, then describe any changes you want.',
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            PrototypeButton('Create design', onPressed: () {
              final details = {...answers};
              if (details['Gender / clothing style'] == 'Male' &&
                  details['Occasion'] == 'Wedding groom' &&
                  details['Outfit type'] == 'Omani formal wear') {
                details['Headwear'] = 'Traditional wrapped Omani Massar';
                details['Bisht'] =
                    'Formal bisht with gold edging over the dishdasha';
              }
              if (details['Occasion'] == 'Other') {
                details['Occasion'] = otherOccasion.text.trim();
              }
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AiGenerationScreen(
                            title: 'Create Clothes',
                            dressReference: dressReference,
                            outfitDetails: dressReference?.description ?? '',
                            photos: [
                              if (template != null) template!,
                              if (facePhoto != null) facePhoto!
                            ],
                            preferredColour: answers['Favourite colour'],
                            size: answers['Size'],
                            prompt:
                                '${dressReference == null ? '' : 'The first image is the single selected garment reference: ${dressReference!.description}. Match its cut and details closely while applying the user preferences; output only one outfit. '} '
                                '${template == null ? '' : 'Use the supplied garment image as the design reference and adapt it to the preferences. '} '
                                '${facePhoto == null ? 'Create a high quality fashion product photograph of one outfit on a headless display mannequin.' : 'The last supplied image is the face reference, not a garment. Show one person wearing the requested outfit, preserving the reference face. Do not copy clothing from the face photo.'} Neutral studio background, full outfit visible, realistic fabric, no text. Age-appropriate clothing only. Design preferences: ${details.entries.map((e) => '${e.key}: ${e.value}').join('; ')}. Additional wishes: ${notes.text.trim()}.',
                          )));
            }),
            const SizedBox(height: 12),
            PrototypeButton('Edit choices',
                onPressed: () => setState(() => reviewing = false)),
          ] else
            PrototypeButton('Review design', onPressed: review),
          const SizedBox(height: 14),
          const Text('Your choices are kept while this page is open.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
      );

  Widget questionnaire() => Form(
      key: formKey,
      child: Column(
        key: ValueKey(formRevision),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final question in questions.entries) ...[
            Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(question.key,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            if (question.key == 'Favourite colour')
              FavouriteColourStrip(
                selected: answers[question.key],
                onChanged: (value) => setState(() {
                  answers[question.key] = value;
                  formRevision++;
                }),
              ),
            if (question.key == 'Style')
              FormField<String>(
                initialValue: answers[question.key],
                validator: (value) =>
                    value == null ? 'Please select a style' : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                        builder: (context, constraints) => Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: question.value.map((value) {
                                final selected = answers[question.key] == value;
                                return SizedBox(
                                  width: (constraints.maxWidth - 12) / 2,
                                  height: 88,
                                  child: Semantics(
                                    selected: selected,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: selected
                                            ? const Color(0xFF5C4745)
                                            : const Color(0xFFF5F5F5),
                                        foregroundColor: selected
                                            ? Colors.white
                                            : const Color(0xFF302B2A),
                                        side: BorderSide(
                                            color: selected
                                                ? const Color(0xFF5C4745)
                                                : const Color(0xFFB9BDB2),
                                            width: selected ? 2 : 1),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        textStyle: const TextStyle(
                                            fontFamily: 'TimesNewRoman',
                                            fontSize: 21,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () {
                                        field.didChange(value);
                                        setState(() =>
                                            answers[question.key] = value);
                                      },
                                      child: Text(value,
                                          textAlign: TextAlign.center),
                                    ),
                                  ),
                                );
                              }).toList(),
                            )),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(field.errorText!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                key: ValueKey(question.key),
                initialValue: answers[question.key],
                isExpanded: true,
                decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                hint: const Text('Select an option'),
                items: question.value
                    .map((value) =>
                        DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) => setState(() {
                  if (value != null) answers[question.key] = value;
                  if (question.key == 'Gender / clothing style') {
                    template = null;
                  }
                  if (rankedDressReferences(answers).isEmpty) {
                    dressReference = null;
                  }
                  if (question.key == 'Gender / clothing style' ||
                      question.key == 'Outfit type' ||
                      question.key == 'Occasion') {
                    final valid = questions;
                    answers.removeWhere((key, value) =>
                        !valid.containsKey(key) ||
                        !valid[key]!.contains(value));
                    formRevision++;
                  }
                }),
                validator: (value) => value == 'Not sure — use camera'
                    ? 'Use the camera or choose a tone / Prefer not to specify'
                    : question.key.contains('(optional)') || value != null
                        ? null
                        : 'Please select an option',
              ),
            if (question.key == 'Skin tone (optional)' &&
                answers[question.key] == 'Not sure — use camera') ...[
              const SizedBox(height: 8),
              TextButton.icon(
                  onPressed: analyzingSkin ? null : estimateSkin,
                  icon: const Icon(Icons.camera_alt),
                  label:
                      Text(analyzingSkin ? 'Analyzing…' : 'Take skin photo')),
              const Text(
                  'Photograph a small area of your hand or forearm in natural light.',
                  style: TextStyle(fontSize: 12)),
            ],
            if (question.key == 'Occasion' &&
                answers['Occasion'] == 'Other') ...[
              const SizedBox(height: 10),
              TextFormField(
                  controller: otherOccasion,
                  maxLength: 100,
                  decoration: const InputDecoration(
                      labelText: 'Describe the occasion',
                      filled: true,
                      fillColor: Colors.white),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please describe the occasion'
                      : null),
            ],
            const SizedBox(height: 18),
          ],
          TextFormField(
              controller: notes,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                  labelText: 'Additional wishes (optional)',
                  hintText: 'Preferred colours, coverage or details…',
                  filled: true,
                  fillColor: Colors.white)),
        ],
      ));

  Widget summary() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final question in questions.keys)
          Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(question,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(question == 'Occasion' && answers[question] == 'Other'
                        ? otherOccasion.text.trim()
                        : answers[question] ?? 'Not specified'),
                  ])),
        if (notes.text.trim().isNotEmpty) ...[
          const Text('Additional wishes',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(notes.text.trim())
        ],
      ]);
}
