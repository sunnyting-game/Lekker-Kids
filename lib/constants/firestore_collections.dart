/// Firestore collection name constants
/// Centralized to ensure consistency across the codebase
class FirestoreCollections {
  // Prevent instantiation
  FirestoreCollections._();

  static const String users = 'users';
  static const String banners = 'banners';
  static const String dailyStatus = 'dailyStatus';
  static const String photos = 'photos';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String weeklyPlans = 'weeklyPlans';
  static const String organizations = 'organizations';
  static const String schools = 'schools';
  static const String documents = 'documents';
  static const String signatureRequests = 'signature_requests';
  static const String checklistTemplates = 'checklist_templates';
  static const String checklistRecords = 'checklist_records';
}
