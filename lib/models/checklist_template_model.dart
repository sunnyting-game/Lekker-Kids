import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single checklist item in a template
class ChecklistItem {
  final String id;
  final String label;
  final int order;

  ChecklistItem({
    required this.id,
    required this.label,
    required this.order,
  });

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'order': order,
    };
  }

  ChecklistItem copyWith({
    String? id,
    String? label,
    int? order,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      label: label ?? this.label,
      order: order ?? this.order,
    );
  }
}

/// Named checklist template belonging to an organization
/// Multiple templates can exist per organization
class ChecklistTemplateModel {
  final String id;  // Unique ID (auto-generated)
  final String name;  // Template name e.g., "Daily Safety Checklist"
  final String organizationId;
  final List<ChecklistItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChecklistTemplateModel({
    required this.id,
    required this.name,
    required this.organizationId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Generate a unique template ID
  static String generateId() => 'template_${DateTime.now().millisecondsSinceEpoch}';

  factory ChecklistTemplateModel.fromMap(Map<String, dynamic> map, String id) {
    final itemsList = (map['items'] as List<dynamic>?)
        ?.map((item) => ChecklistItem.fromMap(Map<String, dynamic>.from(item)))
        .toList() ?? [];
    
    // Sort by order
    itemsList.sort((a, b) => a.order.compareTo(b.order));

    return ChecklistTemplateModel(
      id: id,
      name: map['name'] ?? '',
      organizationId: map['organizationId'] ?? '',
      items: itemsList,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'organizationId': organizationId,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ChecklistTemplateModel copyWith({
    String? id,
    String? name,
    String? organizationId,
    List<ChecklistItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChecklistTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      organizationId: organizationId ?? this.organizationId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
