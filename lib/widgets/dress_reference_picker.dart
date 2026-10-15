import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/dress_reference.dart';
import 'prototype_ui.dart';

class DressReferencePreview extends StatefulWidget {
  const DressReferencePreview(this.reference, {super.key});
  final DressReference reference;
  @override
  State<DressReferencePreview> createState() => _DressReferencePreviewState();
}

class _DressReferencePreviewState extends State<DressReferencePreview> {
  late Future<Uint8List> bytes;
  @override
  void initState() {
    super.initState();
    bytes = widget.reference.imageBytes();
  }

  @override
  void didUpdateWidget(covariant DressReferencePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reference.id != widget.reference.id) {
      bytes = widget.reference.imageBytes();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
      future: bytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Icon(Icons.broken_image_outlined);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Image.memory(snapshot.data!, fit: BoxFit.contain);
      });
}

Future<DressReference?> chooseDressReference(
    BuildContext context, Map<String, String> answers) async {
  final references = rankedDressReferences(answers);
  return showModalBottomSheet<DressReference>(
      context: context,
      isScrollControlled: true,
      backgroundColor: prototypeBackground,
      builder: (context) => SafeArea(
          child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .85,
              child: Column(children: [
                ListTile(
                    title: const Text('Dress reference library'),
                    subtitle: const Text(
                        'Closest choices first. Fabric and occasions are visual suggestions, not verified product details.'),
                    trailing: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close))),
                Expanded(
                    child: references.isEmpty
                        ? const Center(
                            child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                    'These references are women’s occasion dresses. Select Female and an appropriate occasion. No references are available here for children, teens or abayas.',
                                    textAlign: TextAlign.center)))
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: references.length,
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 280,
                                    mainAxisExtent: 410,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12),
                            itemBuilder: (context, i) {
                              final ref = references[i];
                              return Card(
                                  child: InkWell(
                                      onTap: () => Navigator.pop(context, ref),
                                      child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(children: [
                                            Expanded(
                                                child: DressReferencePreview(
                                                    ref,
                                                    key: ValueKey(ref.id))),
                                            Text('${ref.id} · ${ref.colour}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(
                                                '${ref.length} · ${ref.cut}\n${ref.neckline} · ${ref.sleeves}\n${ref.fabric} appearance · ${ref.style}',
                                                textAlign: TextAlign.center),
                                            const Text('Use reference',
                                                style: TextStyle(
                                                    color: prototypeBrown,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ]))));
                            },
                          )),
              ]))));
}
