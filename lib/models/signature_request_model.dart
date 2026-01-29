import 'package:cloud_firestore/cloud_firestore.dart';

enum SignatureStatus { pending, signed }

class SignatureRequestModel {
  final String id;
  final String documentId;
  final String userId;
  final String schoolId; // For easy filtering by Admin
  final SignatureStatus status;
  final DateTime? signedAt;
  final DateTime createdAt;

  SignatureRequestModel({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.schoolId,
    required this.status,
    this.signedAt,
    required this.createdAt,
  });

  factory SignatureRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return SignatureRequestModel(
      id: id,
      documentId: map['documentId'] ?? '',
      userId: map['userId'] ?? '',
      schoolId: map['schoolId'] ?? '',
      status: SignatureStatus.values.firstWhere(
        (e) => e.toString() == 'SignatureStatus.${map['status']}',
        orElse: () => SignatureStatus.pending,
      ),
      signedAt: map['signedAt'] != null 
          ? (map['signedAt'] as Timestamp).toDate() 
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'userId': userId,
      'schoolId': schoolId,
      'status': status.toString().split('.').last,
      'signedAt': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
