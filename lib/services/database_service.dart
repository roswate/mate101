import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // KULLANICIYI KAYDETME
  Future<void> saveUser(String uid, Map<String, dynamic> userData) async {
    await _db.collection('users').doc(uid).set(userData);
  }

  // KULLANICILARI ÇEKME
  Stream<QuerySnapshot> getUsers() {
    return _db.collection('users').snapshots();
  }
}