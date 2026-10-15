class OutfitReference {
  const OutfitReference(
      this.id, this.name, this.category, this.gender, this.details);
  final String id, name, category, gender, details;
  String get path => 'images/$id.png';
}

const outfitCategories = [
  'Traditional Clothes',
  'Wedding',
  'Professional Clothes'
];
const professionOptions = [
  'Engineer',
  'Doctor',
  'Nurse',
  'Chef',
  'Pilot',
  'Teacher',
  'Police officer',
  'Lawyer',
  'Judge',
  'Office employee',
  'Other',
];

final outfitReferences = <OutfitReference>[
  const OutfitReference('traditional_male', 'Omani dishdasha',
      'Traditional Clothes', 'Male', 'Collarless Omani dishdasha with tassel'),
  const OutfitReference(
      'traditional_female',
      'Omani women’s outfit',
      'Traditional Clothes',
      'Female',
      'Omani-inspired embroidered tunic and trousers'),
  const OutfitReference('wedding_male', 'Omani groom', 'Wedding', 'Male',
      'Omani dishdasha, wrapped Massar and gold-edged Bisht'),
  const OutfitReference('wedding_ballgown', 'Lace ball gown', 'Wedding',
      'Female', 'Full skirt, long lace sleeves, high neckline'),
  const OutfitReference('wedding_mermaid', 'Mermaid wedding dress', 'Wedding',
      'Female', 'Fitted mermaid silhouette, off-shoulder neckline'),
  const OutfitReference('wedding_aline', 'Satin A-line dress', 'Wedding',
      'Female', 'A-line satin skirt, long sleeves, V neckline'),
  for (final gender in ['Male', 'Female']) ...[
    OutfitReference(
        'engineer_${gender.toLowerCase()}',
        'Engineer',
        'Professional Clothes',
        gender,
        'Work shirt, trousers, safety vest and hard hat'),
    OutfitReference(
        'doctor_${gender.toLowerCase()}',
        'Doctor',
        'Professional Clothes',
        gender,
        'White lab coat, shirt, trousers and stethoscope'),
    OutfitReference('nurse_${gender.toLowerCase()}', 'Nurse',
        'Professional Clothes', gender, 'Scrub top and trousers'),
    OutfitReference(
        'chef_${gender.toLowerCase()}',
        'Chef',
        'Professional Clothes',
        gender,
        'Chef jacket, apron, trousers and chef hat'),
  ],
];
List<OutfitReference> outfitsFor(String category, String gender) =>
    outfitReferences
        .where((item) => item.category == category && item.gender == gender)
        .toList();
