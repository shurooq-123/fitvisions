import '../constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../widgets/prototype_ui.dart';
import 'ai_generation_screen.dart';
import '../services/dress_reference.dart';
import '../services/omani_outfit.dart';
import '../widgets/favourite_colour_strip.dart';

class CreateClothesScreen extends StatefulWidget {
  const CreateClothesScreen({super.key});
  @override
  State<CreateClothesScreen> createState() => _CreateClothesScreenState();
}

class _CreateClothesScreenState extends State<CreateClothesScreen> {
  final formKey = GlobalKey<FormState>();
  final answers = <String, String>{};
  bool reviewing = false;
  String? facePhoto;
  DressReference? dressReference;
  int formRevision = 0;
  bool get male => answers['Gender / clothing style'] == 'Male';
  bool get traditional => answers['Outfit type'] == traditionalOmaniClothes;

  static const baseQuestions = <String, List<String>>{
    'Gender / clothing style': ['Female', 'Male', 'Unisex'],
    'Age group': [
      'Adult (18–29)',
      'Adult (30–49)',
      'Adult (50–64)',
      'Adult (65+)'
    ],
    'Occasion': [
      'Eid',
      'Bridal dress',
      'Wedding guest',
      'Birthday',
      'Graduation',
      'Work / formal event',
      'Everyday'
    ],
    'Skin tone (optional)': [
      'Prefer not to specify',
      'Fair',
      'Light',
      'Medium',
      'Tan',
      'Deep'
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

  String? get occasion => answers['Occasion'];

  String get ageGuidance => switch (answers['Age group']) {
        'Adult (18–29)' => 'Use contemporary styling for a younger adult.',
        'Adult (30–49)' => 'Use refined, tailored styling for a middle adult.',
        'Adult (50–64)' =>
          'Use classic lines and a comfortable fit for a mature adult.',
        'Adult (65+)' =>
          'Show an older adult and favor comfortable, elegant cuts and ease of movement.',
        _ => '',
      };

  List<String> get occasions => male
      ? [
          'Eid',
          'Wedding groom',
          'Wedding guest',
          'Birthday',
          'Graduation',
          'Work / formal event',
          'Sports / training',
          'Everyday',
        ]
      : baseQuestions['Occasion']!;

  List<String> get outfitTypes {
    if (male) {
      return switch (occasion) {
        'Sports / training' => ['Sportswear'],
        'Wedding groom' || 'Wedding guest' || 'Eid' => [
            traditionalOmaniClothes,
            'Formal suit'
          ],
        'Work / formal event' || 'Graduation' => [
            'Formal suit',
            'Casual outfit'
          ],
        'Birthday' => ['Casual outfit', 'Formal suit'],
        'Everyday' => [traditionalOmaniClothes, 'Casual outfit'],
        _ => [
            traditionalOmaniClothes,
            'Formal suit',
            'Sportswear',
            'Casual outfit'
          ],
      };
    }
    return switch (occasion) {
      'Bridal dress' => ['Bridal gown', traditionalOmaniClothes],
      'Graduation' => ['Graduation dress', traditionalOmaniClothes],
      'Eid' || 'Wedding guest' || 'Birthday' || 'Everyday' => [
          traditionalOmaniClothes,
          'Other outfits'
        ],
      _ => ['Other outfits'],
    };
  }

  List<String> get ageOutfits {
    final variations = switch (occasion) {
      'Bridal dress' => [
          'Contemporary bridal gown',
          'Elegant tailored bridal gown',
          'Classic bridal gown',
          'Timeless bridal gown with comfortable coverage',
        ],
      'Wedding groom' => [
          'Contemporary wedding suit',
          'Elegant wedding suit',
          'Classic wedding suit',
          'Timeless wedding suit with a comfortable cut',
        ],
      'Wedding guest' => male
          ? [
              'Contemporary wedding-guest suit',
              'Elegant wedding-guest suit',
              'Classic wedding-guest suit',
              'Comfortable formal wedding-guest suit'
            ]
          : [
              'Contemporary wedding-guest dress',
              'Elegant wedding-guest dress',
              'Classic wedding-guest dress',
              'Timeless wedding-guest dress with comfortable coverage'
            ],
      'Eid' => [
          'Contemporary Eid outfit',
          'Elegant Eid outfit',
          'Classic Eid outfit',
          'Comfortable festive Eid outfit'
        ],
      'Graduation' => [
          'Contemporary graduation outfit',
          'Elegant graduation outfit',
          'Classic graduation outfit',
          'Comfortable formal graduation outfit'
        ],
      'Birthday' => [
          'Contemporary birthday outfit',
          'Elegant birthday outfit',
          'Classic birthday outfit',
          'Comfortable celebration outfit'
        ],
      'Work / formal event' => [
          'Contemporary tailored outfit',
          'Structured tailored outfit',
          'Classic tailored outfit',
          'Comfortable formal tailoring'
        ],
      'Sports / training' => [
          'Contemporary training outfit',
          'Performance training outfit',
          'Classic training outfit',
          'Comfortable easy-movement training outfit'
        ],
      _ => [
          'Contemporary everyday outfit',
          'Polished everyday outfit',
          'Classic everyday outfit',
          'Comfortable easy-movement everyday outfit'
        ],
    };
    final index =
        baseQuestions['Age group']!.indexOf(answers['Age group'] ?? '');
    return [variations[index < 0 ? 0 : index], 'No preference'];
  }

  Map<String, List<String>> get questions {
    final gender = answers['Gender / clothing style'];
    final type = answers['Outfit type'];
    final bridal = occasion == 'Bridal dress';
    final common = {
      'Gender / clothing style': baseQuestions['Gender / clothing style']!,
      'Age group': baseQuestions['Age group']!,
      'Occasion': occasions,
      if (gender == 'Male' || gender == 'Female') 'Outfit type': outfitTypes,
      'Skin tone (optional)': baseQuestions['Skin tone (optional)']!,
    };

    if (traditional) {
      return {
        ...common,
        if (male) ...{
          'Headwear': ['Kumma', 'Kumma with Mussar'],
          'Bisht (optional)': ['No bisht', 'Add bisht'],
        } else ...{
          'Dress embroidery': ['Subtle', 'Decorative'],
          'Lihaf colour (optional)': ['Match the dress', 'Contrasting colour'],
        },
        'Fabric': baseQuestions['Fabric']!,
        'Favourite colour': baseQuestions['Favourite colour']!,
      };
    }

    if (!male) {
      return {
        ...common,
        'Style': switch (occasion) {
          'Bridal dress' => [
              'Classic bridal',
              'Contemporary bridal',
              'Modest bridal',
              'No preference'
            ],
          'Work / formal event' => [
              'Tailored',
              'Classic formal',
              'Minimal',
              'No preference'
            ],
          'Everyday' => ['Casual', 'Minimal', 'Relaxed', 'No preference'],
          'Eid' => ['Festive', 'Classic festive', 'Elegant', 'No preference'],
          'Wedding guest' => [
              'Formal wedding guest',
              'Elegant wedding guest',
              'Modest wedding guest',
              'No preference'
            ],
          'Graduation' => [
              'Polished',
              'Classic formal',
              'Minimal',
              'No preference'
            ],
          _ => baseQuestions['Style']!,
        },
        'Outfit preference': ageOutfits,
        for (final key in [
          'Silhouette',
          'Length',
          'Neckline',
          'Sleeves',
          'Fit',
          'Fabric',
          'Favourite colour',
          'Details'
        ])
          key: bridal && key == 'Length'
              ? ['Floor length', 'Chapel train', 'No preference']
              : baseQuestions[key]!,
      };
    }
    return {
      ...common,
      'Style': switch (type) {
        'Sportswear' => ['Performance', 'Classic sportswear', 'No preference'],
        'Formal suit' => [
            'Classic formal',
            'Contemporary formal',
            'No preference'
          ],
        _ => ['Classic', 'Casual', 'Formal', 'No preference'],
      },
      'Outfit preference': ageOutfits,
      if (type == 'Formal suit') ...{
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

  void review() {
    if (!formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => reviewing = true);
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
        title: reviewing ? 'Your Clothing Design' : 'Design Clothes',
        child: Column(children: [
          const PrototypeLogo(width: 160, symbolOnly: true),
          const SizedBox(height: 16),
          PrototypePanel(
              radius: 30,
              padding: 20,
              child: reviewing ? summary() : questionnaire()),
          const SizedBox(height: 20),
          if (reviewing) ...[
            PrototypeButton('Create design', onPressed: () {
              final details = Map<String, String>.of(answers);
              final templates =
                  traditional ? omaniReferencePaths(male, details) : <String>[];
              final rules =
                  traditional ? omaniOutfitInstructions(male, details) : '';
              final selectedDress = traditional ? null : dressReference;
              final faceIndex =
                  templates.length + (selectedDress == null ? 0 : 1);
              final graduation = occasion == 'Graduation'
                  ? 'GRADUATION ATTIRE. Show one front-facing, full-body avatar. The '
                      'selected outfit is the focal point, clearly visible down to its hem. '
                      'Put a square black academic mortarboard with a tassel '
                      'on the avatar’s head and an open-front academic graduation gown '
                      'in plain matte black over the selected outfit. Wear the gown '
                      'unfastened, with its left and right panels falling behind both '
                      'arms like an open coat. Leave the neckline, bodice and front of '
                      'the outfit unobstructed. Preserve the chosen silhouette, colour, '
                      'fabric and embroidery on the outfit underneath. '
                      '${traditional && !male ? 'Wear the lihaf under the mortarboard, framing the visible face, with one end draped over a shoulder.' : ''}'
                  : '';
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AiGenerationScreen(
                            title: 'Design Clothes',
                            compactDesignResult: true,
                            personalPhoto: facePhoto,
                            dressReference: selectedDress,
                            outfitDetails: [
                              graduation,
                              if (traditional) rules,
                              if (selectedDress != null)
                                selectedDress.description,
                            ].join(' '),
                            photos: [
                              ...templates,
                              if (facePhoto != null) facePhoto!
                            ],
                            preferredColour: answers['Favourite colour'],
                            prompt:
                                '${selectedDress == null ? '' : 'The first image is the single selected garment reference: ${selectedDress.description}. Match its cut and details closely while applying the user preferences; output only one outfit. '} '
                                '${templates.isEmpty ? '' : 'Reference image 0 shows the Omani garment cut and embroidery. Use the other Omani clothing references to understand how the pieces are worn. Follow the user’s garment, colour and accessory choices. Ignore the reference models’ faces. '} '
                                '${facePhoto == null ? 'Create one full-body 3D-style adult avatar wearing the designed outfit. Use a smooth featureless mannequin head without eyes, nose or mouth.' : 'Use reference image $faceIndex only for the face. Show one full-body 3D-style avatar wearing the requested outfit, preserving the reference face. Ignore the clothes in the face photo.'} Output one combined dressed avatar. Apply the selected clothing preferences. Neutral studio background, head to feet visible, realistic fabric, no text. $ageGuidance Keep the outfit within the selected occasion. Design preferences: ${details.entries.map((e) => '${e.key}: ${e.value}').join('; ')}.',
                          )));
            }),
            const SizedBox(height: 12),
            PrototypeButton('Edit choices',
                onPressed: () => setState(() => reviewing = false)),
          ] else
            PrototypeButton('Review design', onPressed: review),
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
                                            : AppColors.field(context,
                                                const Color(0xFFF5F5F5)),
                                        foregroundColor: selected
                                            ? Colors.white
                                            : AppColors.ink(context,
                                                const Color(0xFF302B2A)),
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
                decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.field(context),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                hint: const Text('Select an option'),
                items: question.value
                    .map((value) =>
                        DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) => setState(() {
                  if (question.key == 'Gender / clothing style' &&
                      value != answers[question.key]) {
                    answers.remove('Outfit type');
                  }
                  if (value != null) answers[question.key] = value;
                  if (!outfitTypes.contains(answers['Outfit type'])) {
                    answers.remove('Outfit type');
                    if ((male ||
                            answers['Gender / clothing style'] == 'Female') &&
                        outfitTypes.length == 1) {
                      answers['Outfit type'] = outfitTypes.single;
                    }
                  }
                  if (rankedDressReferences(answers).isEmpty) {
                    dressReference = null;
                  }
                  if (question.key == 'Gender / clothing style' ||
                      question.key == 'Outfit type' ||
                      question.key == 'Age group' ||
                      question.key == 'Occasion') {
                    final valid = questions;
                    answers.removeWhere((key, value) =>
                        !valid.containsKey(key) ||
                        !valid[key]!.contains(value));
                    formRevision++;
                  }
                }),
                validator: (value) => question.key.contains('(optional)') ||
                        value != null ||
                        (answers['Style'] == 'No preference' &&
                            questions.keys.toList().indexOf(question.key) >
                                questions.keys.toList().indexOf('Style'))
                    ? null
                    : 'Please select an option',
              ),
            if (question.key == 'Outfit type' && traditional)
              Text(male
                  ? 'Ankle-length dishdasha and embroidered kumma'
                  : 'Below-knee dress, sirwal trousers and lihaf shawl'),
            const SizedBox(height: 18),
          ],
          PrototypePanel(
              child: Column(children: [
            const Text('Personal photo (optional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Text(
                'Add your face to the outfit preview. Without a photo, the face has no features.',
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
              const Text('Your selected photo is sent to Cloudflare AI.',
                  textAlign: TextAlign.center),
              TextButton(
                  onPressed: () => setState(() => facePhoto = null),
                  child: const Text('Remove face photo')),
            ],
            const SizedBox(height: 16),
          ])),
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
                    Text(answers[question] ?? 'Not specified'),
                  ])),
      ]);
}
