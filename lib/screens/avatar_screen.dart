import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../services/app_data_service.dart';
import '../widgets/prototype_ui.dart';
import '../widgets/saved_image.dart';

class AvatarScreen extends StatefulWidget {
  const AvatarScreen({super.key, this.measurements});
  final Future<DocumentSnapshot>? measurements;
  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  final previewKey = GlobalKey();
  late final Future<DocumentSnapshot>? measurements;
  bool downloading = false;
  @override
  void initState() {
    super.initState();
    if (widget.measurements != null) {
      measurements = widget.measurements;
      return;
    }
    final uid = AppDataService.uid;
    measurements = uid == null
        ? null
        : FirebaseFirestore.instance.collection('measurements').doc(uid).get();
  }

  Future<void> download() async {
    if (downloading) return;
    setState(() => downloading = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = previewKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('No image');
      await const MethodChannel('fitvisions/downloads')
          .invokeMethod<String>('savePreview', data.buffer.asUint8List());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Preview saved to Downloads / FitVisions.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not download the preview on this device.')));
      }
    } finally {
      if (mounted) setState(() => downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) => PrototypePage(
      child: measurements == null
          ? const Text('Please sign in to view your avatar.')
          : FutureBuilder<DocumentSnapshot>(
              future: measurements,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                      'Could not load your saved photos. Please try again.');
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const CircularProgressIndicator();
                }
                final data =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final personal =
                    data['personalImagePath'] ?? data['personImagePath'];
                final cloth = data['clothImagePath'];
                return Column(children: [
                  const PrototypeLogo(width: 195, symbolOnly: true),
                  const SizedBox(height: 16),
                  const Text('Avatar Preview',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  RepaintBoundary(
                      key: previewKey,
                      child: AvatarPreview(personal: personal, cloth: cloth)),
                  const SizedBox(height: 10),
                  const Text(
                      'Photo preview • AI generation will be connected later',
                      style: TextStyle(fontSize: 11, color: Colors.black54)),
                  const SizedBox(height: 22),
                  Row(children: [
                    Expanded(
                        child: PrototypeButton('Edit',
                            onPressed: () => Navigator.pushNamed(
                                context, '/generateAvatar'))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: PrototypeButton(
                            downloading ? 'Saving...' : 'Download',
                            onPressed: downloading ? null : download))
                  ]),
                  const SizedBox(height: 18),
                  PrototypeButton('Continue',
                      onPressed: () =>
                          Navigator.pushNamed(context, '/subscription')),
                ]);
              }));
}

class AvatarPreview extends StatelessWidget {
  const AvatarPreview({super.key, this.personal, this.cloth});
  final String? personal, cloth;
  @override
  Widget build(BuildContext context) => Container(
      height: 300,
      width: double.infinity,
      color: prototypeBackground,
      child: Stack(alignment: Alignment.center, children: [
        if (personal != null && personal!.isNotEmpty)
          SavedImage(personal!, height: 300, fit: BoxFit.contain)
        else
          Image.asset('images/fv1.png', height: 300, fit: BoxFit.contain),
        if (cloth != null && cloth!.isNotEmpty)
          Positioned(
              top: 70,
              child: SavedImage(cloth!,
                  width: 135, height: 160, fit: BoxFit.contain)),
        if (personal == null || personal!.isEmpty)
          const Positioned(
              top: 4,
              right: 4,
              child: Text('Sample avatar', style: TextStyle(fontSize: 10))),
        const Positioned(
            bottom: 4,
            left: 8,
            child: Icon(Icons.smart_toy_outlined,
                color: Color(0xFF51227D), size: 44)),
      ]));
}
