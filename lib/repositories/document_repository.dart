import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/firestore_collections.dart';
import '../models/document_model.dart';
import '../models/signature_request_model.dart';

class DocumentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // 1. Upload & Create Document Record
  Future<DocumentModel> uploadAndCreate({
    required PlatformFile file,
    required String title,
    required String organizationId,
    required String uploadedBy,
  }) async {
    // a. Upload file to Firebase Storage
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = file.extension != null ? '.${file.extension}' : '.pdf';
    final fileName = '$timestamp$extension';
    final storagePath = 'organizations/$organizationId/documents/$fileName';
    
    final ref = _storage.ref().child(storagePath);
    
    if (kIsWeb) {
      if (file.bytes == null) {
        throw Exception('File bytes are missing on Web');
      }
      final metadata = SettableMetadata(contentType: 'application/pdf');
      await ref.putData(file.bytes!, metadata);
    } else {
      if (file.path == null) {
        throw Exception('File path is missing on Native');
      }
      await ref.putFile(File(file.path!));
    }
    
    final url = await ref.getDownloadURL();

    // b. Create Document record in Firestore
    final docRef = _firestore.collection(FirestoreCollections.documents).doc();
    final document = DocumentModel(
      id: docRef.id,
      url: url,
      title: title,
      organizationId: organizationId,
      createdAt: DateTime.now(),
      uploadedBy: uploadedBy,
    );

    await docRef.set(document.toMap());
    return document;
  }

  // 2. Bulk Assign (Create Signature Requests)
  Future<void> assignToUsers({
    required String documentId,
    required List<String> userIds,
    required String schoolId,
  }) async {
    // Determine how many batches needed (500 ops limit)
    // Each user needs 1 set op.
    final batchSize = 500;
    
    for (var i = 0; i < userIds.length; i += batchSize) {
      final batch = _firestore.batch();
      final end = (i + batchSize < userIds.length) ? i + batchSize : userIds.length;
      final chunk = userIds.sublist(i, end);

      for (var userId in chunk) {
        final reqRef = _firestore.collection(FirestoreCollections.signatureRequests).doc();
        final request = SignatureRequestModel(
          id: reqRef.id,
          documentId: documentId,
          userId: userId,
          schoolId: schoolId,
          status: SignatureStatus.pending,
          createdAt: DateTime.now(),
        );
        batch.set(reqRef, request.toMap());
      }
      await batch.commit();
    }
  }

  // 3. User Signing
  Future<void> signDocument(String requestId) async {
    await _firestore
        .collection(FirestoreCollections.signatureRequests)
        .doc(requestId)
        .update({
      'status': 'signed',
      'signedAt': Timestamp.now(),
    });
  }

  // 4. Get Requests for User (Future - more efficient for infrequent access)
  Future<List<SignatureRequestModel>> getRequestsForUser(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.signatureRequests)
        .where('userId', isEqualTo: userId)
        .get();
    
    final results = snapshot.docs
        .map((doc) => SignatureRequestModel.fromMap(doc.data(), doc.id))
        .toList();
    
    // Sort in memory instead of requiring an index
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  // 5. Get Document Details
  Future<DocumentModel?> getDocumentById(String documentId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.documents)
        .doc(documentId)
        .get();
    
    if (doc.exists && doc.data() != null) {
      return DocumentModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
  // 6. Get Documents for Organization
  Stream<List<DocumentModel>> getDocumentsByOrgStream(String organizationId) {
    return _firestore
        .collection(FirestoreCollections.documents)
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 7. Get All Signature Requests for a Document
  Stream<List<SignatureRequestModel>> getSignatureRequestsForDocumentStream(String documentId) {
    return _firestore
        .collection(FirestoreCollections.signatureRequests)
        .where('documentId', isEqualTo: documentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SignatureRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
