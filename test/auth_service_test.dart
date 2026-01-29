import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inner_garden/services/auth_service.dart';

// Generate mocks for testing
@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  User,
  UserCredential,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      authService = AuthService(
        auth: mockAuth,
        firestore: mockFirestore,
      );
    });

    group('signInWithUsername', () {
      test('should convert username to email and sign in', () async {
        // Arrange
        const username = 'TestUser';
        const password = 'password123';
        const expectedEmail = 'testuser@daycare.local';
        const uid = 'user123';

        final mockUser = MockUser();
        final mockCredential = MockUserCredential();
        final mockCollection = MockCollectionReference<Map<String, dynamic>>();
        final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
        final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

        when(mockUser.uid).thenReturn(uid);
        when(mockCredential.user).thenReturn(mockUser);
        
        when(mockAuth.signInWithEmailAndPassword(
          email: expectedEmail,
          password: password,
        )).thenAnswer((_) async => mockCredential);

        when(mockFirestore.collection(any)).thenReturn(mockCollection);
        when(mockCollection.doc(uid)).thenReturn(mockDocRef);
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn({
          'username': 'testuser',
          'role': 'teacher',
          'createdAt': DateTime.now().toIso8601String(),
        });

        // Act
        final result = await authService.signInWithUsername(username, password);

        // Assert
        verify(mockAuth.signInWithEmailAndPassword(
          email: expectedEmail,
          password: password,
        )).called(1);
        expect(result, isNotNull);
        expect(result!.username, equals('testuser'));
      });

      test('should return null when user is null after sign in', () async {
        // Arrange
        const username = 'TestUser';
        const password = 'password123';

        final mockCredential = MockUserCredential();
        when(mockCredential.user).thenReturn(null);
        
        when(mockAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockCredential);

        // Act
        final result = await authService.signInWithUsername(username, password);

        // Assert
        expect(result, isNull);
      });
    });

    group('signOut', () {
      test('should call Firebase signOut', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
      });
    });

    group('currentUser', () {
      test('should return current user from FirebaseAuth', () {
        // Arrange
        final mockUser = MockUser();
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        final result = authService.currentUser;

        // Assert
        expect(result, equals(mockUser));
      });

      test('should return null when no user is signed in', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = authService.currentUser;

        // Assert
        expect(result, isNull);
      });
    });
  });
}
