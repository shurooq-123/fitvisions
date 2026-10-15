import 'package:flutter/material.dart';

const prototypeBackground = Color(0xFFCED1C6);
const prototypeBrown = Color(0xFF574543);
const prototypeCard = Color(0xFFEFEFEF);

class PrototypeLogo extends StatelessWidget {
  const PrototypeLogo({super.key, this.width = 190, this.symbolOnly = false});
  final double width;
  final bool symbolOnly;
  @override
  Widget build(BuildContext context) => ClipRect(
      child: Align(
          alignment: Alignment.topCenter,
          heightFactor: symbolOnly ? .53 : 1,
          child: Image.asset('images/fv.png', width: width)));
}

class PrototypeButton extends StatelessWidget {
  const PrototypeButton(this.label, {super.key, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 145,
      height: 44,
      child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
              backgroundColor: prototypeBrown,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6))),
          child: Text(label,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))));
}

class PrototypeNav extends StatelessWidget {
  const PrototypeNav({super.key, this.index = 0});
  final int index;
  @override
  Widget build(BuildContext context) => BottomNavigationBar(
          currentIndex: index,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          onTap: (i) {
            final route = ['/home', '/profile', '/history'][i];
            if (ModalRoute.of(context)?.settings.name != route) {
              Navigator.pushNamed(context, route);
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Text('🏠', style: TextStyle(fontSize: 25)),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Text('👤', style: TextStyle(fontSize: 25)),
                label: 'Profile'),
            BottomNavigationBarItem(
                icon: Text('🕘', style: TextStyle(fontSize: 25)),
                label: 'History'),
          ]);
}

class PrototypePage extends StatelessWidget {
  const PrototypePage(
      {super.key,
      required this.child,
      this.title,
      this.nav = true,
      this.index = 0});
  final Widget child;
  final String? title;
  final bool nav;
  final int index;
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: prototypeBackground,
      body: SafeArea(
          child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                      child: Column(children: [
                        Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                                onPressed: () => Navigator.maybePop(context),
                                icon: const Icon(Icons.arrow_back_ios,
                                    size: 30))),
                        if (title != null) ...[
                          const SizedBox(height: 25),
                          Text(title!,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 28)
                        ],
                        child,
                      ]))))),
      bottomNavigationBar: nav ? PrototypeNav(index: index) : null);
}

class PrototypePanel extends StatelessWidget {
  const PrototypePanel(
      {super.key, required this.child, this.radius = 48, this.padding = 24});
  final Widget child;
  final double radius, padding;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
          color: prototypeCard, borderRadius: BorderRadius.circular(radius)),
      child: Material(type: MaterialType.transparency, child: child));
}
