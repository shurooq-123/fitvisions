import '../services/app_language.dart';
import 'custom_back_button.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

const prototypeBackground = Color(0xFFCED1C6);
const prototypeBrown = Color(0xFF574543);
const prototypeCard = Color(0xFFEFEFEF);
const prototypeFieldBorder =
    OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)));
const prototypeFieldPadding =
    EdgeInsets.symmetric(horizontal: 14, vertical: 12);

class PrototypeLogo extends StatelessWidget {
  const PrototypeLogo({super.key, this.width = 190, this.symbolOnly = false});
  final double width;
  final bool symbolOnly;
  @override
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => ClipRect(
          child: Align(
              alignment: Alignment.topCenter,
              heightFactor: symbolOnly ? .53 : 1,
              child: Image.asset('images/fv.png', width: width))));
}

class PrototypeButton extends StatelessWidget {
  const PrototypeButton(this.label, {super.key, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 145, minHeight: 48),
          child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                  backgroundColor: prototypeBrown,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 44),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: AppText(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)))));
}

class PrototypeNav extends StatelessWidget {
  const PrototypeNav({super.key, this.index = 0});
  final int index;
  @override
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => BottomNavigationBar(
              currentIndex: index,
              backgroundColor: AppColors.panel(context, Colors.white),
              elevation: 0,
              selectedItemColor: AppColors.ink(context, prototypeBrown),
              unselectedItemColor: AppColors.muted(context, prototypeBrown),
              selectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              type: BottomNavigationBarType.fixed,
              onTap: (i) {
                final route = ['/home', '/profile', '/history'][i];
                if (ModalRoute.of(context)?.settings.name != route) {
                  if (route == '/home') {
                    Navigator.pushNamedAndRemoveUntil(
                        context, route, (r) => false);
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                        context, route, (r) => r.settings.name == '/home');
                  }
                }
              },
              items: [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined, size: 26),
                    label: tr('Home')),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline, size: 26),
                    label: tr('Profile')),
                BottomNavigationBarItem(
                    icon: Icon(Icons.history, size: 26), label: tr('History')),
              ]));
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
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => Scaffold(
          backgroundColor: AppColors.page(context),
          body: SafeArea(
              child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 390),
                      child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                              MediaQuery.sizeOf(context).width <= 340 ? 16 : 20,
                              8,
                              MediaQuery.sizeOf(context).width <= 340 ? 16 : 20,
                              24),
                          child: Column(children: [
                            const CustomBackButton(),
                            if (title != null) ...[
                              const SizedBox(height: 16),
                              AppText(title!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20)
                            ],
                            child,
                          ]))))),
          bottomNavigationBar: nav ? PrototypeNav(index: index) : null));
}

class PrototypePanel extends StatelessWidget {
  const PrototypePanel(
      {super.key, required this.child, this.radius = 48, this.padding = 24});
  final Widget child;
  final double radius, padding;
  @override
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => Container(
          width: double.infinity,
          padding: EdgeInsets.all(
              padding > 18 && MediaQuery.sizeOf(context).width <= 340
                  ? 18
                  : padding),
          decoration: BoxDecoration(
              color: AppColors.panel(context),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                  color: AppColors.adaptive(
                      context, Colors.white70, const Color(0xFF464B40))),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x12574543),
                    blurRadius: 14,
                    offset: Offset(0, 4))
              ]),
          child: Material(type: MaterialType.transparency, child: child)));
}
