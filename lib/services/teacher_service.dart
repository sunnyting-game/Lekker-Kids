import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/firestore_collections.dart';

class TeacherService {
  final FirebaseFirestore _firestore;

  TeacherService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get stream of all teachers
  Stream<List<UserModel>> getTeachersStream() {
    return _firestore
        .collection(FirestoreCollections.users)
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get a single teacher by ID
  Future<UserModel?> getTeacherById(String teacherId) async {
    try {
      final doc = await _firestore.collection(FirestoreCollections.users).doc(teacherId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get teacher: $e');
    }
  }
}
