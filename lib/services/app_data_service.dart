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

  static Future<void> saveMeasurements({
    required Map<String, dynamic> measurements,
  }) async {
    if (uid == null) return;

    await firestore.collection('measurements').add({
      'uid': uid,
      'email': email,
      ...measurements,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addHistory('Measurements submitted');
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

  static Stream<QuerySnapshot> usersStream() {
    return firestore.collection('users').snapshots();
  }

  static Stream<QuerySnapshot> paymentsStream() {
    return firestore.collection('payments').snapshots();
  }

  static Stream<QuerySnapshot> feedbackStream() {
    return firestore
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots();
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