const traditionalOmaniClothes = 'Traditional Omani clothes';

List<String> omaniReferencePaths(bool male, Map<String, String> answers) {
  if (!male) {
    return ['images/omani_women.png', 'images/omani_female_worn.jpg'];
  }
  return [
    'images/omani_men.png',
    'images/omani_male_worn.jpg',
    if (answers['Headwear'] == 'Kumma with Mussar' &&
        answers['Bisht (optional)'] == 'Add bisht')
      'images/omani_groom.png',
  ];
}

String omaniOutfitInstructions(bool male, Map<String, String> answers) {
  if (!male) {
    final contrasting =
        answers['Lihaf colour (optional)'] == 'Contrasting colour';
    return 'TRADITIONAL OMANI WOMEN’S OUTFIT. Show all three pieces worn together: '
        'an embroidered Omani dress with long sleeves ending below the knees '
        'and above the ankles, separate sirwal trousers visible below the dress '
        'with embroidered cuffs, and a lihaf shawl worn on the head and draped over '
        'the shoulders as one continuous piece. No second scarf. '
        '${contrasting ? 'Use one contrasting colour for the whole lihaf.' : 'Use one matching colour for the whole lihaf.'} '
        'Keep the head, dress hem, trousers and feet in frame. '
        'Do not substitute a floor-length gown, plain abaya, or modern top and trousers.';
  }
  final mussar = answers['Headwear'] == 'Kumma with Mussar';
  final bisht = answers['Bisht (optional)'] == 'Add bisht';
  return 'TRADITIONAL OMANI MEN’S OUTFIT. The two core pieces are a long-sleeved, '
      'ankle-length, collarless Omani dishdasha with a short neck tassel and an '
      'embroidered Omani kumma cap worn on the head. '
      '${mussar ? 'Wrap an Omani mussar around the kumma as traditional headwear.' : 'Keep the embroidered kumma clearly visible, with no wrapped headwear.'} '
      '${bisht ? 'Add an open bisht over the dishdasha, keeping the dishdasha visible underneath.' : 'Wear the dishdasha without a bisht.'} '
      'Keep the head and ankle-length hem in frame. '
      'Do not replace the dishdasha with a shirt, visible trousers, a suit, or a different regional robe.';
}
