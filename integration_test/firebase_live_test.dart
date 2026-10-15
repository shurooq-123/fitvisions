import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Live Firebase project and server connectivity', (tester) async {
    await Firebase.initializeApp();
    expect(Firebase.app().options.projectId, 'fitvisions-33e6d');
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await FirebaseFirestore.instance.collection('users').doc(user.uid)
          .get(const GetOptions(source: Source.server)).timeout(const Duration(seconds: 30));
      expect(profile.exists, isTrue);
      expect(['user','admin'], contains(profile.data()?['role']));
      print('FIREBASE_PROFILE_SERVER_READ_OK');
    } else {
      try {
        await FirebaseFirestore.instance.collection('users').doc('connectivity-probe')
            .get(const GetOptions(source: Source.server)).timeout(const Duration(seconds: 30));
        fail('Unauthenticated private read unexpectedly allowed');
      } on FirebaseException catch (e) {
        expect(e.code, 'permission-denied');
        print('FIREBASE_SERVER_REACHABLE_SIGN_IN_REQUIRED');
      }
    }
  });
}
