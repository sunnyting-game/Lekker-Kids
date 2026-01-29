import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/weekly_plan.dart';
import '../constants/firestore_collections.dart';
import 'package:flutter/foundation.dart';

class WeeklyPlanService {
  final FirebaseFirestore _firestore;

  WeeklyPlanService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get weekly plans for a specific week and year (raw list)
  Stream<List<WeeklyPlan>> getWeeklyPlansStream(int year, int weekNumber) {
    return _firestore
        .collection(FirestoreCollections.weeklyPlans)
        .where('year', isEqualTo: year)
        .where('weekNumber', isEqualTo: weekNumber)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return WeeklyPlan.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Add a new weekly plan
  Future<void> addWeeklyPlan({
    required String title,
    required String description,
    required int year,
    required int weekNumber,
    required String dayOfWeek,
    required String actualDate,
  }) async {
    try {
      await _firestore.collection(FirestoreCollections.weeklyPlans).add({
        'title': title,
        'description': description,
        'year': year,
        'weekNumber': weekNumber,
        'dayOfWeek': dayOfWeek,
        'actualDate': actualDate,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding weekly plan: $e');
      rethrow;
    }
  }

  // Delete a weekly plan
  Future<void> deleteWeeklyPlan(String planId) async {
    try {
      await _firestore.collection(FirestoreCollections.weeklyPlans).doc(planId).delete();
    } catch (e) {
      debugPrint('Error deleting weekly plan: $e');
      rethrow;
    }
  }

  // Update a weekly plan
  Future<void> updateWeeklyPlan({
    required String planId,
    required String title,
    required String description,
    required int year,
    required int weekNumber,
    required String dayOfWeek,
    required String actualDate,
  }) async {
    try {
      await _firestore.collection(FirestoreCollections.weeklyPlans).doc(planId).update({
        'title': title,
        'description': description,
        'year': year,
        'weekNumber': weekNumber,
        'dayOfWeek': dayOfWeek,
        'actualDate': actualDate,
      });
    } catch (e) {
      debugPrint('Error updating weekly plan: $e');
      rethrow;
    }
  }
}
