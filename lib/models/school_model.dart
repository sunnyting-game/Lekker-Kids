import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a School (displayed as "Dayhome" in UI).
/// 
/// In the multi-tenant hierarchy:
/// - Organization (parent) → School (child sites)
/// - "School" is the internal/code term; "Dayhome" is the user-facing term
/// 
/// Stored in the `schools` Firestore collection.
class SchoolModel {
  final String id;
  final String name;
  final String? organizationId; // Parent organization this dayhome belongs to
  final SchoolConfig config;
  final SubscriptionStatus subscription;
  final DateTime createdAt;

  SchoolModel({
    required this.id,
    required this.name,
    this.organizationId,
    required this.config,
    required this.subscription,
    required this.createdAt,
  });

  factory SchoolModel.fromMap(Map<String, dynamic> map, String id) {
    return SchoolModel(
      id: id,
      name: map['name'] ?? '',
      organizationId: map['organizationId'],
      config: SchoolConfig.fromMap(map['config'] as Map<String, dynamic>? ?? {}),
      subscription: SubscriptionStatus.fromString(map['subscription']?['status']),
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (organizationId != null) 'organizationId': organizationId,
      'config': config.toMap(),
      'subscription': {'status': subscription.name},
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

  SchoolModel copyWith({
    String? id,
    String? name,
    String? organizationId,
    SchoolConfig? config,
    SubscriptionStatus? subscription,
    DateTime? createdAt,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      organizationId: organizationId ?? this.organizationId,
      config: config ?? this.config,
      subscription: subscription ?? this.subscription,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Configuration for a school (theme, features, etc.)
class SchoolConfig {
  final String? logoUrl;
  final String? themeColor;
  final Map<String, bool> features;

  SchoolConfig({
    this.logoUrl,
    this.themeColor,
    this.features = const {},
  });

  factory SchoolConfig.fromMap(Map<String, dynamic> map) {
    return SchoolConfig(
      logoUrl: map['logoUrl'],
      themeColor: map['themeColor'],
      features: Map<String, bool>.from(map['features'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (themeColor != null) 'themeColor': themeColor,
      'features': features,
    };
  }

  /// Check if a feature is enabled for this school.
  bool isFeatureEnabled(String featureName) {
    return features[featureName] ?? true; // Default to enabled if not specified
  }

  SchoolConfig copyWith({
    String? logoUrl,
    String? themeColor,
    Map<String, bool>? features,
  }) {
    return SchoolConfig(
      logoUrl: logoUrl ?? this.logoUrl,
      themeColor: themeColor ?? this.themeColor,
      features: features ?? this.features,
    );
  }
}

/// Subscription status for a school.
enum SubscriptionStatus {
  trial,
  active,
  pastDue,
  canceled;

  static SubscriptionStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'trial':
        return SubscriptionStatus.trial;
      case 'active':
        return SubscriptionStatus.active;
      case 'pastdue':
      case 'past_due':
        return SubscriptionStatus.pastDue;
      case 'canceled':
      case 'cancelled':
        return SubscriptionStatus.canceled;
      default:
        return SubscriptionStatus.trial;
    }
  }
}
