import 'package:flutter/material.dart';

/// Decorative only: never handles input or changes page layout/navigation.
class FashionBackdrop extends StatelessWidget {
  const FashionBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(fit: StackFit.expand, children: [
      Positioned.fill(
          child:
              IgnorePointer(child: CustomPaint(painter: _RoseBackdrop(dark)))),
      child,
    ]);
  }
}

class _RoseBackdrop extends CustomPainter {
  const _RoseBackdrop(this.dark);
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: dark
                      ? const [Color(0xFF211A20), Color(0xFF2C2029)]
                      : const [
                          Color(0xFFFFF7F6),
                          Color(0xFFFAEDF1),
                          Color(0xFFF5E4E9)
                        ])
              .createShader(rect));
    final paint = Paint()
      ..color = dark ? const Color(0x0FFFFFFF) : const Color(0x1685465F);
    final wave = Path()
      ..moveTo(size.width * .62, size.height)
      ..cubicTo(size.width * .84, size.height * .83, size.width * .88,
          size.height * .93, size.width, size.height * .74)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(wave, paint);
    canvas.drawOval(
        Rect.fromLTWH(size.width * .72, -70, size.width * .65, 210),
        Paint()
          ..color = dark ? const Color(0x0885465F) : const Color(0x0F85465F));
  }

  @override
  bool shouldRepaint(covariant _RoseBackdrop oldDelegate) =>
      oldDelegate.dark != dark;
}
