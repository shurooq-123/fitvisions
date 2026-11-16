import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

List<Map<String, dynamic>> mergeHistory(List<Map<String, dynamic>> history,
    List<Map<String, dynamic>> subscriptions) {
  final plans = subscriptions.map((s) => s['plan']).toSet();
  final items = [
    ...history.where((h) =>
        !plans.any((plan) => h['title'] == 'Subscription selected: $plan')),
    ...subscriptions.map((s) => <String, dynamic>{
          ...s,
          'kind': 'subscription',
          'title': "Subscription: ${s['plan']}"
        }),
  ];
  items.sort((a, b) =>
      ((a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0).compareTo(
          (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0));
  return items;
}

Stream<List<Map<String, dynamic>>> historyFeed(
    Stream<QuerySnapshot> history, Stream<QuerySnapshot> subscriptions) {
  late StreamController<List<Map<String, dynamic>>> controller;
  StreamSubscription<QuerySnapshot>? hSub, sSub;
  List<Map<String, dynamic>>? h, s;
  void emit() {
    if (h != null && s != null) controller.add(mergeHistory(h!, s!));
  }

  controller = StreamController(onListen: () {
    hSub = history.listen((snapshot) {
      h = snapshot.docs.map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id}).toList();
      emit();
    }, onError: controller.addError);
    sSub = subscriptions.listen((snapshot) {
      s = snapshot.docs.map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id}).toList();
      emit();
    }, onError: controller.addError);
  }, onCancel: () async {
    await hSub?.cancel();
    await sSub?.cancel();
  });
  return controller.stream;
}
