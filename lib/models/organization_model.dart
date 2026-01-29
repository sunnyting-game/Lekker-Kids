import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an Organization (top-level tenant in multi-tenant hierarchy).
/// 
/// In the multi-tenant hierarchy:
/// - Organization (this) → manages multiple Schools (Dayhomes)
/// - Each School belongs to exactly one Organization
/// 
/// Stored in the `organizations` Firestore collection.
class OrganizationModel {
  final String id;
  final String name;
  final DateTime createdAt;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory OrganizationModel.fromMap(Map<String, dynamic> map, String id) {
    return OrganizationModel(
      id: id,
      name: map['name'] ?? '',
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  OrganizationModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
