String avatarPrompt(Map<String, String> measurements,
        {bool clothing = false, bool person = false}) =>
    'A polished 3D-rendered full-body adult fashion avatar, a stylized digital character with smooth CGI materials and studio lighting, NOT a photograph of a real person. '
    'Standing head to feet, neutral background, fully clothed in a modest outfit. '
    'Approximate body proportions: ${measurements.entries.map((e) => '${e.key} ${e.value} ${e.key == 'Weight' ? 'kg' : 'cm'}').join(', ')}. '
    'Use these numbers as visual guidance, do not display numbers or text. '
    '${clothing ? 'Dress the avatar in the garment from reference image 0, keeping its design and colours.' : 'Use a simple neutral outfit.'} '
    '${person ? 'Use the appearance from reference image ${clothing ? 1 : 0}, translated into the 3D character style.' : 'Invent a neutral synthetic adult character, no real person identity or photograph.'}';
