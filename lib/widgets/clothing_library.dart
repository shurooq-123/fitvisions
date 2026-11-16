// Keep these asset paths readable in older saved results.
import 'outfit_catalog.dart';

final clothingTemplates = <String, String>{
  for (final outfit in outfitReferences) outfit.path: outfit.name,
  'images/omani_men.png': 'Omani dishdasha',
  'images/omani_groom.png': 'Omani groom — Massar & Bisht',
  'images/omani_women.png': 'Omani-inspired women’s outfit',
  'images/bridal_lace.png': 'Lace wedding dress',
  'images/bridal_satin.png': 'Satin wedding dress',
};
