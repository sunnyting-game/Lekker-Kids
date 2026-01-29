import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String url;
  final String title;
  final String organizationId;
  final DateTime createdAt;
  final String uploadedBy;

  DocumentModel({
    required this.id,
    required this.url,
    required this.title,
    required this.organizationId,
    required this.createdAt,
    required this.uploadedBy,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> map, String id) {
    return DocumentModel(
      id: id,
      url: map['url'] ?? '',
      title: map['title'] ?? '',
      organizationId: map['organizationId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      uploadedBy: map['uploadedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'title': title,
      'organizationId': organizationId,
      'createdAt': Timestamp.fromDate(createdAt),
      'uploadedBy': uploadedBy,
    };
  }
}
