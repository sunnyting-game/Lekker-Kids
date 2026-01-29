import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single attendance session (check-in to check-out).
class AttendanceSession {
  final DateTime checkIn;
  final DateTime? checkOut;

  AttendanceSession({
    required this.checkIn,
    this.checkOut,
  });

  Map<String, dynamic> toMap() {
    return {
      'checkIn': checkIn.toIso8601String(),
      if (checkOut != null) 'checkOut': checkOut!.toIso8601String(),
    };
  }

  factory AttendanceSession.fromMap(Map<String, dynamic> map) {
    return AttendanceSession(
      checkIn: _parseTimestamp(map['checkIn']) ?? DateTime.now(),
      checkOut: _parseTimestamp(map['checkOut']),
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return null;
  }

  /// Calculate duration of this session. Returns Duration.zero if not checked out.
  Duration get duration {
    if (checkOut == null) return Duration.zero;
    return checkOut!.difference(checkIn);
  }

  AttendanceSession copyWith({
    DateTime? checkIn,
    DateTime? checkOut,
  }) {
    return AttendanceSession(
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
    );
  }
}

class DailyStatus {
  final String studentId;
  final String date; // Format: YYYY-MM-DD
  final bool mealStatus;
  final bool toiletStatus;
  final bool sleepStatus;
  final bool attendance;
  final List<Map<String, dynamic>> photos;
  final DateTime? checkInTime;  // Latest check-in time (for UI display)
  final DateTime? checkOutTime; // Latest check-out time (for UI display)
  final bool isAbsent;
  final List<AttendanceSession> sessions; // All sessions for accurate time tracking

  DailyStatus({
    required this.studentId,
    required this.date,
    this.mealStatus = false,
    this.toiletStatus = false,
    this.sleepStatus = false,
    this.attendance = false,
    this.photos = const [],
    this.checkInTime,
    this.checkOutTime,
    this.isAbsent = false,
    this.sessions = const [],
  });

  // Document ID format: {studentId}_{date}
  String get documentId => '${studentId}_$date';

  /// Calculate total attendance duration for the day.
  Duration get totalDuration {
    return sessions.fold(Duration.zero, (total, session) => total + session.duration);
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'date': date,
      'mealStatus': mealStatus,
      'toiletStatus': toiletStatus,
      'sleepStatus': sleepStatus,
      'attendance': attendance,
      'photos': photos,
      if (checkInTime != null) 'checkInTime': checkInTime!.toIso8601String(),
      if (checkOutTime != null) 'checkOutTime': checkOutTime!.toIso8601String(),
      'isAbsent': isAbsent,
      'sessions': sessions.map((s) => s.toMap()).toList(),
    };
  }

  // Create from Firestore document
  factory DailyStatus.fromMap(Map<String, dynamic> map) {
    return DailyStatus(
      studentId: map['studentId'] ?? '',
      date: map['date'] ?? '',
      mealStatus: map['mealStatus'] ?? false,
      toiletStatus: map['toiletStatus'] ?? false,
      sleepStatus: map['sleepStatus'] ?? false,
      attendance: map['attendance'] ?? false,
      photos: List<Map<String, dynamic>>.from(map['photos'] ?? []),
      checkInTime: _parseTimestamp(map['checkInTime']),
      checkOutTime: _parseTimestamp(map['checkOutTime']),
      isAbsent: map['isAbsent'] ?? false,
      sessions: _parseSessions(map['sessions']),
    );
  }

  static List<AttendanceSession> _parseSessions(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((item) => AttendanceSession.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
    return null;
  }

  // Create a copy with updated values
  DailyStatus copyWith({
    String? studentId,
    String? date,
    bool? mealStatus,
    bool? toiletStatus,
    bool? sleepStatus,
    bool? attendance,
    List<Map<String, dynamic>>? photos,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    bool? isAbsent,
    List<AttendanceSession>? sessions,
  }) {
    return DailyStatus(
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      mealStatus: mealStatus ?? this.mealStatus,
      toiletStatus: toiletStatus ?? this.toiletStatus,
      sleepStatus: sleepStatus ?? this.sleepStatus,
      attendance: attendance ?? this.attendance,
      photos: photos ?? this.photos,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      isAbsent: isAbsent ?? this.isAbsent,
      sessions: sessions ?? this.sessions,
    );
  }
}
