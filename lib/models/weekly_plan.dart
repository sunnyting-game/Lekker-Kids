import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyPlan {
  final String id;
  final String title;
  final String description;
  final int year;
  final int weekNumber;
  final String dayOfWeek; // 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'
  final String actualDate; // YYYY-MM-DD format
  final DateTime createdAt;

  WeeklyPlan({
    required this.id,
    required this.title,
    this.description = '',
    required this.year,
    required this.weekNumber,
    required this.dayOfWeek,
    required this.actualDate,
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'year': year,
      'weekNumber': weekNumber,
      'dayOfWeek': dayOfWeek,
      'actualDate': actualDate,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore document
  factory WeeklyPlan.fromMap(Map<String, dynamic> map, String id) {
    return WeeklyPlan(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      weekNumber: map['weekNumber'] ?? 1,
      dayOfWeek: map['dayOfWeek'] ?? '',
      actualDate: map['actualDate'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create a copy with updated values
  WeeklyPlan copyWith({
    String? id,
    String? title,
    String? description,
    int? year,
    int? weekNumber,
    String? dayOfWeek,
    String? actualDate,
    DateTime? createdAt,
  }) {
    return WeeklyPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      year: year ?? this.year,
      weekNumber: weekNumber ?? this.weekNumber,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      actualDate: actualDate ?? this.actualDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
