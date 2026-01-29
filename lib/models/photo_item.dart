import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain model representing a photo item
/// Encapsulates photo data to decouple View layer from Firestore implementation
class PhotoItem {
  final String url;
  final DateTime timestamp;
  final String? caption;
  final String? storagePath; // Storage path for deletion

  PhotoItem({
    required this.url,
    required this.timestamp,
    this.caption,
    this.storagePath,
  });

  /// Create PhotoItem from Firestore Map
  /// Handles both Firestore Timestamp and String timestamp formats
  factory PhotoItem.fromMap(Map<String, dynamic> map) {
    DateTime parsedTimestamp;
    
    // Handle timestamp field - can be Firestore Timestamp or String
    final timestampValue = map['timestamp'];
    if (timestampValue is Timestamp) {
      // Firestore Timestamp object
      parsedTimestamp = timestampValue.toDate();
    } else if (timestampValue is String) {
      // String in ISO8601 format
      parsedTimestamp = DateTime.parse(timestampValue);
    } else {
      // Fallback to current time if timestamp is missing or invalid
      parsedTimestamp = DateTime.now();
    }
    
    return PhotoItem(
      url: map['url'] as String,
      timestamp: parsedTimestamp,
      caption: map['caption'] as String?,
      storagePath: map['storagePath'] as String?,
    );
  }

  /// Convert PhotoItem to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'timestamp': timestamp.toIso8601String(),
      if (caption != null) 'caption': caption,
      if (storagePath != null) 'storagePath': storagePath,
    };
  }
}
