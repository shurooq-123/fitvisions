import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AppDataService {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static const cloudImagesEnabled =
      bool.fromEnvironment('FIREBASE_STORAGE_ENABLED');
  static String? get uid => auth.currentUser?.uid;
  static String? get email => auth.currentUser?.email;

  static User requireUser() {
    final user = auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
          code: 'unauthenticated', message: 'Please sign in again.');
    }
    return user;
  }

  static Map<String, dynamic> _identity(User user) =>
      {'uid': user.uid, 'email': user.email};
  static void _history(WriteBatch batch, User user, String title) {
    batch.set(firestore.collection('history').doc(), {
      ..._identity(user),
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> addHistory(String title) async {
    final user = requireUser();
    final batch = firestore.batch();
    _history(batch, user, title);
    await batch.commit();
  }

  static Future<void> saveGeneration(
      String title, Uint8List bytes, String kind) async {
    final user = requireUser();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 320);
    final frame = await codec.getNextFrame();
    final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    if (png == null) throw StateError('Preview unavailable');
    final preview = base64Encode(png.buffer.asUint8List());
    if (preview.length > 700000) throw StateError('Preview too large');
    await firestore.collection('history').add({
      ..._identity(user),
      'title': title.length > 500 ? title.substring(0, 500) : title,
      'kind': kind,
      'previewBase64': preview,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveOrUpdateMeasurements(
      {required Map<String, dynamic> measurements}) async {
    final user = requireUser();
    final batch = firestore.batch();
    batch.set(firestore.collection('measurements').doc(user.uid), {
      ...measurements,
      ..._identity(user),
      'imageStorage': cloudImagesEnabled ? 'firebase_storage' : 'local_only',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _history(batch, user, 'Measurements saved / updated');
    await batch.commit();
  }

  static Future<String> saveUploadedClothPath(String imagePath) =>
      saveImage(imagePath, 'cloth');

  static Future<String> saveImage(String imagePath, String kind) async {
    final user = requireUser();
    if (kind != 'cloth' && kind != 'personal') {
      throw ArgumentError('Unknown image type');
    }
    var savedPath = imagePath;
    if (cloudImagesEnabled) {
      final file = File(imagePath);
      if (await file.length() >= 5 * 1024 * 1024) {
        throw Exception('Choose an image smaller than 5 MB.');
      }
      final extension = imagePath.split('.').last.toLowerCase();
      final mime = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp'
      }[extension];
      if (mime == null) throw Exception('Choose a JPEG, PNG or WebP image.');
      final ref = FirebaseStorage.instance.ref(
          'users/${user.uid}/$kind/${DateTime.now().microsecondsSinceEpoch}.$extension');
      await ref.putFile(file, SettableMetadata(contentType: mime));
      // Store an authenticated storage reference, not a public download token.
      savedPath = 'gs://${ref.bucket}/${ref.fullPath}';
    }
    final batch = firestore.batch();
    batch.set(
        firestore.collection('user_uploads').doc(user.uid),
        {
          ..._identity(user),
          kind == 'cloth' ? 'clothImagePath' : 'personalImagePath': savedPath,
          'imageStorage':
              cloudImagesEnabled ? 'firebase_storage' : 'local_only',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
    _history(
        batch,
        user,
        cloudImagesEnabled
            ? '$kind image uploaded'
            : '$kind image selected (stored on this device)');
    await batch.commit();
    return savedPath;
  }

  static Future<String> saveSubscription({required String planId}) async {
    final user = requireUser();
    final plan = (await firestore
            .collection('plans')
            .doc(planId)
            .get(const GetOptions(source: Source.server)))
        .data();
    if (plan == null) throw Exception('This plan is no longer available.');
    final ref = firestore.collection('subscriptions').doc();
    final batch = firestore.batch();
    batch.set(ref, {
      ..._identity(user),
      'planId': planId,
      'plan': plan['name'],
      'price': plan['price'],
      'status': 'selected',
      'createdAt': FieldValue.serverTimestamp()
    });
    _history(batch, user, 'Subscription selected: ${plan['name']}');
    await batch.commit();
    return ref.id;
  }

  static Future<void> savePayment({required String subscriptionId}) async {
    final user = requireUser();
    final sub = (await firestore
            .collection('subscriptions')
            .doc(subscriptionId)
            .get(const GetOptions(source: Source.server)))
        .data();
    if (sub == null || sub['uid'] != user.uid) {
      throw Exception('Choose a subscription first.');
    }
    final plan = (await firestore
            .collection('plans')
            .doc(sub['planId'] as String)
            .get(const GetOptions(source: Source.server)))
        .data();
    if (plan == null) throw Exception('This plan is no longer available.');
    final payment = firestore.collection('payments').doc(subscriptionId);
    // One request per subscription; an interrupted retry does not duplicate it.
    if ((await payment.get(const GetOptions(source: Source.server))).exists) {
      return;
    }
    final batch = firestore.batch();
    batch.set(payment, {
      ..._identity(user),
      'subscriptionId': subscriptionId,
      'planId': sub['planId'],
      'plan': plan['name'],
      'amount': plan['price'],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp()
    });
    _history(batch, user, 'Payment request submitted (not charged)');
    await batch.commit();
  }

  static Future<void> sendFeedback(String message,
      {required int rating}) async {
    final user = requireUser();
    if (rating < 1 ||
        rating > 5 ||
        message.trim().isEmpty ||
        message.trim().length > 4000) {
      throw ArgumentError('Enter feedback and a rating from 1 to 5.');
    }
    final batch = firestore.batch();
    batch.set(firestore.collection('feedback').doc(), {
      ..._identity(user),
      'message': message.trim(),
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp()
    });
    _history(batch, user, 'Feedback sent');
    await batch.commit();
  }

  static Stream<QuerySnapshot> userHistoryStream() {
    final user = requireUser();
    return firestore
        .collection('history')
        .where('uid', isEqualTo: user.uid)
        .snapshots();
  }
}
