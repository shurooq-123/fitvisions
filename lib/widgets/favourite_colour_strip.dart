import 'package:flutter/material.dart';

class FavouriteColourStrip extends StatelessWidget {
  const FavouriteColourStrip(
      {super.key, required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String> onChanged;
  static const colours = <String, Color>{
    'Black': Colors.black,
    'White': Colors.white,
    'Navy': Color(0xFF182B50),
    'Blue': Colors.blue,
    'Green': Colors.green,
    'Red': Colors.red,
    'Pink': Colors.pink,
    'Purple': Colors.purple,
    'Beige': Color(0xFFD8C4A4),
    'Brown': Colors.brown,
    'Grey': Colors.grey,
    'Teal': Colors.teal,
    'Gold': Color(0xFFD4AF37),
  };
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Swipe to see more colours',
              style: TextStyle(fontSize: 12)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final entry in colours.entries)
                Semantics(
                    button: true,
                    selected: selected == entry.key,
                    label: entry.key,
                    child: Tooltip(
                        message: entry.key,
                        child: SizedBox(
                          width: 48,
                          height: 52,
                          child: InkWell(
                            key: ValueKey('colour-swatch-${entry.key}'),
                            borderRadius: BorderRadius.circular(26),
                            onTap: () => onChanged(entry.key),
                            child: Center(
                                child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: entry.value,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: selected == entry.key
                                          ? const Color(0xFF51227D)
                                          : Colors.black26,
                                      width: selected == entry.key ? 3 : 1)),
                              child: selected == entry.key
                                  ? Icon(Icons.check,
                                      size: 23,
                                      color:
                                          entry.value.computeLuminance() > .45
                                              ? Colors.black
                                              : Colors.white)
                                  : null,
                            )),
                          ),
                        ))),
            ]),
          ),
          const SizedBox(height: 8),
        ],
      );
}
