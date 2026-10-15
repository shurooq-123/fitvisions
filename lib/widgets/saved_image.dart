import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'clothing_library.dart';

class SavedImage extends StatefulWidget {
  const SavedImage(this.path,
      {super.key, this.width, this.height, this.fit = BoxFit.contain});
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  @override
  State<SavedImage> createState() => _SavedImageState();
}

class _SavedImageState extends State<SavedImage> {
  Future<Uint8List?>? image;
  void load() {
    image = widget.path.startsWith('gs://')
        ? FirebaseStorage.instance
            .refFromURL(widget.path)
            .getData(5 * 1024 * 1024)
        : null;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant SavedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) load();
  }

  Widget missing() =>
      const Center(child: Text('Image unavailable. Select it again.'));
  @override
  Widget build(BuildContext context) {
    if (clothingTemplates.containsKey(widget.path)) {
      return Image.asset(widget.path, width: widget.width,
          height: widget.height, fit: widget.fit);
    }
    if (image == null) {
      return Image.file(File(widget.path),
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (_, __, ___) => missing());
    }
    return FutureBuilder<Uint8List?>(
        future: image,
        builder: (context, snapshot) {
          if (snapshot.hasError) return missing();
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null) return missing();
          return Image.memory(snapshot.data!,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              errorBuilder: (_, __, ___) => missing());
        });
  }
}
