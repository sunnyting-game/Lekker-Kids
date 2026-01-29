/// Denormalized display status for student cards
/// Contains only the fields needed for display in the classroom list view
/// Full historical data remains in daily_status collection
class TodayDisplayStatus {
  final bool mealStatus;
  final bool toiletStatus;
  final bool sleepStatus;
  final int photosCount;
  final bool isAbsent;

  const TodayDisplayStatus({
    this.mealStatus = false,
    this.toiletStatus = false,
    this.sleepStatus = false,
    this.photosCount = 0,
    this.isAbsent = false,
  });

  /// Empty/default status for new day or stale data
  factory TodayDisplayStatus.empty() {
    return const TodayDisplayStatus();
  }

  /// Create from Firestore map
  factory TodayDisplayStatus.fromMap(Map<String, dynamic>? map) {
    if (map == null) return TodayDisplayStatus.empty();
    
    return TodayDisplayStatus(
      mealStatus: map['mealStatus'] ?? false,
      toiletStatus: map['toiletStatus'] ?? false,
      sleepStatus: map['sleepStatus'] ?? false,
      photosCount: map['photosCount'] ?? 0,
      isAbsent: map['isAbsent'] ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'mealStatus': mealStatus,
      'toiletStatus': toiletStatus,
      'sleepStatus': sleepStatus,
      'photosCount': photosCount,
      'isAbsent': isAbsent,
    };
  }

  /// Create a copy with updated values
  TodayDisplayStatus copyWith({
    bool? mealStatus,
    bool? toiletStatus,
    bool? sleepStatus,
    int? photosCount,
    bool? isAbsent,
  }) {
    return TodayDisplayStatus(
      mealStatus: mealStatus ?? this.mealStatus,
      toiletStatus: toiletStatus ?? this.toiletStatus,
      sleepStatus: sleepStatus ?? this.sleepStatus,
      photosCount: photosCount ?? this.photosCount,
      isAbsent: isAbsent ?? this.isAbsent,
    );
  }

  @override
  String toString() {
    return 'TodayDisplayStatus(meal: $mealStatus, toilet: $toiletStatus, sleep: $sleepStatus, photos: $photosCount, absent: $isAbsent)';
  }
}
