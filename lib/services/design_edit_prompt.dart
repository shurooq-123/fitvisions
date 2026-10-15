String designEditInstructions(String description, Map<String, String> colours) {
  final requested = description.trim();
  return [
    if (requested.isNotEmpty)
      'Apply these requested visual changes to the image: $requested.',
    for (final entry in colours.entries)
      'Set the ${entry.key} colour to ${entry.value}.',
    if (requested.isNotEmpty)
      'Apply the described changes as well as any selected colour. The description takes priority if they conflict. Preserve only details that are not affected by the requested changes.',
    if (requested.isEmpty && colours.isNotEmpty)
      'This is a colour-only edit. Preserve the person, face, skin tone, body proportions, garment cut, fabric texture, embroidery and background. Keep unselected garments unchanged; do not add missing garments.',
  ].join(' ');
}
