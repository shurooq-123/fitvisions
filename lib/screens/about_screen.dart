import 'package:flutter/material.dart';
import '../widgets/prototype_ui.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => const PrototypePage(
      nav: false,
      child: Column(children: [
        PrototypeLogo(width: 300, symbolOnly: true),
        SizedBox(height: 20),
        Text('About Us',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        PrototypePanel(
            radius: 30,
            child: Text(
                'FitVisions is a virtual try-on application designed to help users preview outfits before making a purchase. The app uses body measurements and photos to explore how clothes might look.\n\nIt helps users choose the right size and style more easily, making online shopping faster and more reliable. FitVisions aims to improve the shopping experience by giving users more confidence when selecting outfits.\n\nThis version provides a photo preview. Subscriptions and payments are demonstrations.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'serif', fontSize: 18, height: 1.15))),
      ]));
}
