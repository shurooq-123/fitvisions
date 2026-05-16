import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDataService {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;

  static String? get uid => auth.currentUser?.uid;
  static String? get email => auth.currentUser?.email;

  static Future<void> addHistory(String title) async {
    if (uid == null) return;

    await firestore.collection('history').add({
      'uid': uid,
      'email': email,
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveOrUpdateMeasurements({
    required Map<String, dynamic> measurements,
  }) async {
    if (uid == null) return;

    await firestore.collection('measurements').doc(uid).set({
      'uid': uid,
      'email': email,
      ...measurements,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await addHistory('Measurements saved / updated');
  }

  static Future<void> saveUploadedClothPath(String imagePath) async {
    if (uid == null) return;

    await firestore.collection('user_uploads').doc(uid).set({
      'uid': uid,
      'email': email,
      'clothImagePath': imagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await addHistory('Cloth image uploaded');
  }

  static Future<void> saveSubscription({
    required String plan,
    required double price,
  }) async {
    if (uid == null) return;

    await firestore.collection('subscriptions').add({
      'uid': uid,
      'email': email,
      'plan': plan,
      'price': price,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addHistory('Subscription selected: $plan');
  }

  static Future<void> savePayment({
    required String plan,
    required double amount,
  }) async {
    if (uid == null) return;

    await firestore.collection('payments').add({
      'uid': uid,
      'email': email,
      'plan': plan,
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addHistory('Payment completed: $amount OMR');
  }

  static Future<void> sendFeedback(String message) async {
    if (uid == null) return;

    await firestore.collection('feedback').add({
      'uid': uid,
      'email': email,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addHistory('Feedback sent');
  }

  static Stream<QuerySnapshot> userHistoryStream() {
    if (uid == null) {
      return const Stream.empty();
    }

    return firestore
        .collection('history')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }
}