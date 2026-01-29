import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_collections.dart';
import '../models/checklist_template_model.dart';
import '../models/checklist_record_model.dart';

/// Repository for checklist template and record operations
class ChecklistRepository {
  final FirebaseFirestore _firestore;

  ChecklistRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================
  // Template Operations (Multiple per Organization)
  // ============================================================

  /// Get all checklist templates for an organization
  Future<List<ChecklistTemplateModel>> getTemplates(String organizationId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.checklistTemplates)
        .where('organizationId', isEqualTo: organizationId)
        .get();

    final templates = snapshot.docs
        .map((doc) => ChecklistTemplateModel.fromMap(doc.data(), doc.id))
        .toList();
    
    // Sort client-side to avoid needing a composite index
    templates.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return templates;
  }

  /// Stream all templates for an organization (real-time updates)
  Stream<List<ChecklistTemplateModel>> getTemplatesStream(String organizationId) {
    return _firestore
        .collection(FirestoreCollections.checklistTemplates)
        .where('organizationId', isEqualTo: organizationId)
        .snapshots()
        .map((snapshot) {
          final templates = snapshot.docs
              .map((doc) => ChecklistTemplateModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort client-side to avoid needing a composite index
          templates.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return templates;
        });
  }


  /// Get a single template by ID
  Future<ChecklistTemplateModel?> getTemplateById(String templateId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.checklistTemplates)
        .doc(templateId)
        .get();

    if (doc.exists && doc.data() != null) {
      return ChecklistTemplateModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Create a new checklist template
  Future<void> createTemplate(ChecklistTemplateModel template) async {
    await _firestore
        .collection(FirestoreCollections.checklistTemplates)
        .doc(template.id)
        .set(template.toMap());
  }

  /// Update an existing checklist template
  Future<void> updateTemplate(ChecklistTemplateModel template) async {
    await _firestore
        .collection(FirestoreCollections.checklistTemplates)
        .doc(template.id)
        .update(template.toMap());
  }

  /// Delete a checklist template
  Future<void> deleteTemplate(String templateId) async {
    await _firestore
        .collection(FirestoreCollections.checklistTemplates)
        .doc(templateId)
        .delete();
  }

  // ============================================================
  // Record Operations (Per dayhome, per template, per day)
  // ============================================================

  /// Get checklist record for a specific date and template
  Future<ChecklistRecordModel?> getRecordForDate(
    String schoolId,
    String templateId,
    String date,
  ) async {
    final docId = ChecklistRecordModel.generateId(schoolId, templateId, date);
    final doc = await _firestore
        .collection(FirestoreCollections.checklistRecords)
        .doc(docId)
        .get();

    if (doc.exists && doc.data() != null) {
      return ChecklistRecordModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Get all records for a specific dayhome and month
  Future<List<ChecklistRecordModel>> getRecordsForMonth(
    String schoolId,
    String month,
  ) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.checklistRecords)
        .where('schoolId', isEqualTo: schoolId)
        .where('month', isEqualTo: month)
        .get();

    return snapshot.docs
        .map((doc) => ChecklistRecordModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Stream records for a specific month (real-time updates)
  Stream<List<ChecklistRecordModel>> getRecordsForMonthStream(
    String schoolId,
    String month,
  ) {
    return _firestore
        .collection(FirestoreCollections.checklistRecords)
        .where('schoolId', isEqualTo: schoolId)
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChecklistRecordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream records for a specific date (all templates)
  Stream<List<ChecklistRecordModel>> getRecordsForDateStream(
    String schoolId,
    String date,
  ) {
    return _firestore
        .collection(FirestoreCollections.checklistRecords)
        .where('schoolId', isEqualTo: schoolId)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChecklistRecordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Save checklist record (create or update)
  /// Automatically calculates isCompleted based on template items
  Future<void> saveRecord(
    ChecklistRecordModel record,
    ChecklistTemplateModel template,
  ) async {
    // Check if all items are completed
    final allCompleted = template.items.every(
      (item) => record.completedItems[item.id] == true,
    );

    final updatedRecord = record.copyWith(
      isCompleted: allCompleted,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(FirestoreCollections.checklistRecords)
        .doc(updatedRecord.id)
        .set(updatedRecord.toMap());
  }

  /// Get all submitted records for an organization in a given month
  Future<List<ChecklistRecordModel>> getSubmittedRecordsForOrg(
    String organizationId,
    String month,
  ) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.checklistRecords)
        .where('organizationId', isEqualTo: organizationId)
        .where('month', isEqualTo: month)
        .where('isSubmitted', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ChecklistRecordModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Get submitted records for a specific dayhome in a month
  Future<List<ChecklistRecordModel>> getSubmittedRecordsForDayhome(
    String schoolId,
    String month,
  ) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.checklistRecords)
        .where('schoolId', isEqualTo: schoolId)
        .where('month', isEqualTo: month)
        .where('isSubmitted', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ChecklistRecordModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
