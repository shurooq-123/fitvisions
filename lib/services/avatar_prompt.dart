import 'measurement_avatar.dart';

enum AvatarGender {
  female('woman'),
  male('man');

  const AvatarGender(this.subject);
  final String subject;
}

enum AvatarViewAngle {
  front('Front', 'straight from the front, with both shoulders facing camera'),
  right('Right',
      'in a true right-side profile, turned 90 degrees from the front'),
  back('Back',
      'straight from the back, turned 180 degrees away from the camera'),
  left('Left', 'in a true left-side profile, turned 90 degrees from the front');

  const AvatarViewAngle(this.label, this.direction);
  final String label;
  final String direction;
}

const _blankAvatarFace =
    'Keep the complete human head, with a smooth, blank face in the same skin tone. '
    'No visible eyes, eyebrows, nose, mouth, facial hair, blur or mask.';

String cloudAvatarAnglePrompt(AvatarViewAngle angle,
        {required bool hasPortrait}) =>
    'Show the same full-body avatar in reference image 0 ${angle.direction}. '
    'Change only the camera viewpoint. Preserve the head, body size, abdomen, '
    'shoulder width, proportions, outfit cut, sleeves, hem, color and fabric. '
    'Keep both feet and the entire head visible against the same plain background. '
    '${angle == AvatarViewAngle.back ? 'Show the back of the head and outfit; the face and front neckline must be out of view. ' : ''}'
    '${hasPortrait ? 'Preserve the avatar’s facial features wherever visible from this angle.' : _blankAvatarFace} '
    'One avatar, no labels and no extra objects.';

String avatarPrompt(Map<String, String> measurements,
        {bool clothing = false, bool person = false}) =>
    'A polished 3D-rendered full-body adult fashion avatar, a stylized digital character with smooth CGI materials and studio lighting, NOT a photograph of a real person. '
    'Standing head to feet, neutral background, fully clothed in a modest outfit. '
    'Approximate body proportions: ${measurements.entries.map((e) => '${e.key} ${e.value} ${e.key == 'Weight' ? 'kg' : 'cm'}').join(', ')}. '
    'Use these numbers as visual guidance, do not display numbers or text. '
    '${clothing ? 'Dress the avatar in the garment from reference image 0, keeping its design and colours.' : 'Use a simple neutral outfit.'} '
    '${person ? 'Use the appearance from reference image ${clothing ? 1 : 0}, translated into the 3D character style.' : 'Invent a neutral synthetic adult character, no real person identity or photograph.'}';
String cloudMeasuredAvatarPrompt(
  Map<String, String> measurements, {
  required AvatarGarment? garment,
  required bool hasClothing,
  required bool hasPortrait,
  AvatarGender? gender,
  bool hasMeasurementGuide = false,
  bool bodyReference = false,
  String? size,
  String changes = '',
}) {
  final height = double.parse(measurements['Height']!);
  final chest = double.parse(measurements['Chest']!);
  final waist = double.parse(measurements['Waist']!);
  final hips = double.parse(measurements['Hips']!);
  final shoulder = measurements['Shoulders'];
  final build = switch (waist) {
    >= 122 =>
      'A distinctly very full build with a large abdomen, broad chest and shoulders, full hips, upper arms and thighs, matching the reference silhouette.',
    >= 114 =>
      'A very full build with a prominent abdomen in profile, a broad chest, wide rounded hips and thick thighs and calves.',
    >= 106 =>
      'A visibly full build with a strongly rounded abdomen, full chest, broad hips and thick legs.',
    >= 98 =>
      'A full build with a clearly projecting abdomen, a full chest, rounded hips and substantial upper legs.',
    >= 90 =>
      'A moderately full build with a visibly rounded abdomen, fuller chest and hips, and broader thighs.',
    >= 82 =>
      'A slightly full build with a gently rounded abdomen and subtle fullness through the chest, hips and thighs.',
    >= 72 => 'A medium build with the given torso proportions.',
    _ => 'A slimmer build with the given torso proportions.',
  };
  final stature = switch (height) {
    < 145 => 'A very short adult with visibly short stature and shorter limbs.',
    < 160 => 'A short adult with proportionately shorter limbs.',
    < 180 => 'An adult of medium stature.',
    < 195 => 'A tall adult with visibly longer limbs.',
    _ =>
      'A very tall adult with long legs and an elongated full-body silhouette.',
  };
  // The shape guide uses a fixed 250 cm frame with an 86% vertical drawing area.
  final framePercent = (height * .86 / 250 * 100).round();
  final framing = 'Use a consistent full-body camera scale and ground line. '
      'From crown to soles the subject should occupy about $framePercent% of the image height. '
      'Keep the surrounding blank space and do not crop or enlarge short subjects to fill the frame. ';
  final outfit = switch (garment) {
    AvatarGarment.separates =>
      'A separate shirt and trousers, with two distinct trouser legs.',
    AvatarGarment.dress =>
      'A knee-length dress with one continuous skirt. No trouser legs.',
    AvatarGarment.longDress =>
      'A full-length dress with one continuous skirt from waist to hem. No trouser legs.',
    AvatarGarment.robe =>
      'A full-length robe or abaya with one continuous body panel. No trouser legs.',
    null =>
      'Read the garment type and length from the outfit photo. Match the construction and hem. Keep a dress or robe as one continuous skirt or panel; reproduce shorts or trousers only when the outfit includes them.',
  };
  final syntheticIdentity = gender != null
      ? 'Use a realistic fictional adult ${gender.subject} with natural visible facial features.'
      : !hasPortrait &&
              (garment == AvatarGarment.dress ||
                  garment == AvatarGarment.longDress)
          ? 'Use a synthetic adult woman for this dress fitting. $_blankAvatarFace'
          : _blankAvatarFace;
  String relative(double value) => (100 * value / height).toStringAsFixed(1);
  if (bodyReference) {
    return 'Generate ONE realistic full-body adult ${gender?.subject ?? 'human'} for a fashion fitting. '
        '${hasMeasurementGuide ? 'Reference image ${hasPortrait ? 1 : 0} is the measured body-shape guide with front and side views of the same body. Use both as geometry references, particularly the abdomen depth in profile. Output one front-facing person only. ' : ''}'
        '$stature $framing'
        '$build The large body proportions must be immediately visible when the measurements call for them. '
        'Show the natural abdomen shape and waist width in a straight front pose, '
        'with both arms relaxed away from the sides. Wear a plain fitted charcoal T-shirt and trousers. '
        'Head to toe, plain background, no text. Entered measurements: height $height cm, '
        'chest circumference $chest cm, waist and abdomen circumference $waist cm, '
        'hip circumference $hips cm, '
        '${shoulder == null ? 'shoulder width proportional to the chest' : 'shoulder width across the back $shoulder cm'}. '
        '${size == null ? '' : 'Chart size $size. The measurements take priority. '}'
        'Preserve the measured proportions. No slimming, cinched waist, shaping garments, or stylization. '
        '${hasPortrait ? 'Reference image 0 is the face only. Preserve its recognizable facial features and skin tone. Ignore its clothing, pose and body shape.' : syntheticIdentity}';
  }
  final garmentReplacement = hasClothing && garment == null
      ? 'VIRTUAL TRY-ON. Image 0 supplies the person and exact body shape only. '
          'Image 1 supplies the entire visible outfit and garment silhouette. '
          'Replace every visible garment from image 0 with the complete outfit in image 1. '
          'Copy where the garment begins and ends on the body. '
          'If image 1 shows one long garment with an unbroken hem across both legs, '
          'keep that single continuous panel all the way to its original hem. '
          'There must be no visible trouser seams, separate legs, drawstring, or waistband from the fitting outfit. '
          'If image 1 actually shows trousers or shorts, copy those instead. '
          'Do not merely recolour or redraw the fitting clothes. '
      : '';
  return '${garmentReplacement}Edit reference image 0 in place. It shows the complete person to dress. '
      'Preserve the person’s face, pose, shoulder width, chest volume, abdominal depth, hip width and leg fullness. '
      'Change only the clothes, leaving the same body underneath. '
      '$stature $framing'
      'Retain the complete outfit and both feet in frame. '
      'Return one realistic full-body adult fashion avatar wearing the outfit, '
      'seen from head to toe straight from the front, arms relaxed '
      'and away from the waist. Plain background, consistent lighting and no text. '
      'Fit the body to these input measurements in centimeters. '
      'Height $height cm. Chest circumference $chest cm. '
      'Waist and abdomen circumference $waist cm. Hip circumference $hips cm. '
      '${shoulder == null ? 'Keep the shoulders consistent with the chest.' : 'Shoulder width across the back $shoulder cm.'} '
      'Chest, waist and hip circumferences are ${relative(chest)}%, ${relative(waist)}%, and ${relative(hips)}% of the height. '
      'These are circumferences, not widths across the front. '
      '${size == null ? '' : 'Selected chart size $size. The entered numbers take priority over the label. '}'
      '$build Preserve those proportions under the clothing and in the silhouette. '
      'Do not slim the body, pull in the abdomen, narrow the shoulders, or hide the torso in a baggy garment. '
      '$outfit '
      '${hasClothing ? 'Reference image 1 is the outfit only. Preserve its color, pattern, neckline, sleeves, and hem. Ignore any person or body in that reference.' : 'Use a simple neutral outfit.'} '
      '${hasPortrait || gender != null ? 'Preserve the facial features already present on reference image 0.' : _blankAvatarFace} '
      '${changes.isEmpty ? '' : 'Requested garment changes: $changes.'}';
}
