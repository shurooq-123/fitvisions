import 'avatar_prompt.dart';

/// Garment catalogue category, not an inference about the wearer.
bool clothingCompatible(AvatarGender gender, String category) =>
    category == 'unisex' || category == gender.name;
String? clothingMismatch(AvatarGender gender, String category) {
  if (category == 'unknown')
    return 'Could not identify the clothing category. Choose a clearer clothing photo and try again.';
  if (!clothingCompatible(gender, category))
    return 'This clothing does not match the selected gender. Choose matching clothing or a unisex outfit.';
  return null;
}
