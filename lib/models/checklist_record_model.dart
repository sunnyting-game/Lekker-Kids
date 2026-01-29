import 'package:cloud_firestore/cloud_firestore.dart';

/// Daily checklist record for a specific dayhome and template
/// Document ID format: {schoolId}_{templateId}_{date}
class ChecklistRecordModel {
  final String id;
  final String schoolId;
  final String organizationId;
  final String templateId;    // Which template was used
  final String templateName;  // Denormalized for display
  final String date;  // YYYY-MM-DD
  final String month; // YYYY-MM (for querying)
  final Map<String, bool> completedItems; // itemId -> checked
  final bool isCompleted;   // All items checked
  final bool isSubmitted;   // Locked after month-end submission
  final DateTime? submittedAt;
  final String? submittedBy; // "system" for auto-submit
  final DateTime createdAt;
  final DateTime updatedAt;

  ChecklistRecordModel({
    required this.id,
    required this.schoolId,
    required this.organizationId,
    required this.templateId,
    required this.templateName,
    required this.date,
    required this.month,
    required this.completedItems,
    required this.isCompleted,
    required this.isSubmitted,
    this.submittedAt,
    this.submittedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Generate document ID from schoolId, templateId and date
  static String generateId(String schoolId, String templateId, String date) => 
      '${schoolId}_${templateId}_$date';

  /// Extract month from date (YYYY-MM-DD -> YYYY-MM)
  static String extractMonth(String date) => date.substring(0, 7);

  factory ChecklistRecordModel.fromMap(Map<String, dynamic> map, String id) {
    final completedItemsRaw = map['completedItems'] as Map<String, dynamic>?;
    final completedItems = completedItemsRaw?.map(
      (key, value) => MapEntry(key, value as bool),
    ) ?? {};

    return ChecklistRecordModel(
      id: id,
      schoolId: map['schoolId'] ?? '',
      organizationId: map['organizationId'] ?? '',
      templateId: map['templateId'] ?? '',
      templateName: map['templateName'] ?? '',
      date: map['date'] ?? '',
      month: map['month'] ?? '',
      completedItems: completedItems,
      isCompleted: map['isCompleted'] ?? false,
      isSubmitted: map['isSubmitted'] ?? false,
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate(),
      submittedBy: map['submittedBy'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'organizationId': organizationId,
      'templateId': templateId,
      'templateName': templateName,
      'date': date,
      'month': month,
      'completedItems': completedItems,
      'isCompleted': isCompleted,
      'isSubmitted': isSubmitted,
      if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
      if (submittedBy != null) 'submittedBy': submittedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ChecklistRecordModel copyWith({
    String? id,
    String? schoolId,
    String? organizationId,
    String? templateId,
    String? templateName,
    String? date,
    String? month,
    Map<String, bool>? completedItems,
    bool? isCompleted,
    bool? isSubmitted,
    DateTime? submittedAt,
    String? submittedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChecklistRecordModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      organizationId: organizationId ?? this.organizationId,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      date: date ?? this.date,
      month: month ?? this.month,
      completedItems: completedItems ?? this.completedItems,
      isCompleted: isCompleted ?? this.isCompleted,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedBy: submittedBy ?? this.submittedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
