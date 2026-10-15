import 'package:flutter_test/flutter_test.dart';
import 'package:fitvisions/services/design_edit_prompt.dart';

void main() {
  test('Description and colour edit do not lock the garment structure', () {
    final prompt = designEditInstructions(
        'Add long sleeves and replace embroidery', {'Main garment': 'Blue'});
    expect(prompt, contains('Add long sleeves and replace embroidery'));
    expect(prompt, contains('Main garment colour to Blue'));
    expect(prompt, contains('description takes priority'));
    expect(prompt, isNot(contains('colour-only')));
    expect(prompt, isNot(contains('Preserve the person')));
  });
  test('Colour-only edits preserve structure; empty edits stay empty', () {
    expect(designEditInstructions('', {'Main garment': 'Red'}),
        contains('colour-only'));
    expect(designEditInstructions('  ', {}), isEmpty);
    expect(designEditInstructions('Add sleeves', {}), contains('Add sleeves'));
  });
}
