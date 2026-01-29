import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inner_garden/services/student_service.dart';
import 'package:inner_garden/repositories/student_repository.dart';

// Generate mocks for testing
@GenerateMocks([StudentRepository, FirebaseFirestore, CollectionReference, DocumentReference, DocumentSnapshot, QuerySnapshot, Query])
import 'student_service_test.mocks.dart';

void main() {
  group('StudentService', () {
    late StudentService studentService;
    late MockStudentRepository mockRepository;
    late MockFirebaseFirestore mockFirestore;

    setUp(() {
      mockRepository = MockStudentRepository();
      mockFirestore = MockFirebaseFirestore();
      studentService = StudentService(
        firestore: mockFirestore,
        repository: mockRepository,
      );
    });

    group('getTodayDate', () {
      test('should return date in YYYY-MM-DD format', () {
        final result = studentService.getTodayDate();
        
        // Verify format: YYYY-MM-DD
        expect(result, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
        
        // Verify it's today's date
        final now = DateTime.now();
        final expectedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        expect(result, equals(expectedDate));
      });
    });

    group('checkInStudent', () {
      test('should delegate to repository', () async {
        // Arrange
        const studentId = 'student123';
        const date = '2025-12-22';
        when(mockRepository.checkInStudent(studentId, date))
            .thenAnswer((_) async {});

        // Act
        await studentService.checkInStudent(studentId, date);

        // Assert
        verify(mockRepository.checkInStudent(studentId, date)).called(1);
      });
    });

    group('checkOutStudent', () {
      test('should delegate to repository', () async {
        // Arrange
        const studentId = 'student123';
        const date = '2025-12-22';
        when(mockRepository.checkOutStudent(studentId, date))
            .thenAnswer((_) async {});

        // Act
        await studentService.checkOutStudent(studentId, date);

        // Assert
        verify(mockRepository.checkOutStudent(studentId, date)).called(1);
      });
    });

    group('markAbsent', () {
      test('should delegate to repository', () async {
        // Arrange
        const studentId = 'student123';
        const date = '2025-12-22';
        when(mockRepository.markAbsent(studentId, date))
            .thenAnswer((_) async {});

        // Act
        await studentService.markAbsent(studentId, date);

        // Assert
        verify(mockRepository.markAbsent(studentId, date)).called(1);
      });
    });

    group('toggleMealStatus', () {
      test('should delegate to repository with correct parameters', () async {
        // Arrange
        const studentId = 'student123';
        const date = '2025-12-22';
        const currentValue = false;
        when(mockRepository.toggleMealStatus(studentId, date, currentValue))
            .thenAnswer((_) async {});

        // Act
        await studentService.toggleMealStatus(studentId, date, currentValue);

        // Assert
        verify(mockRepository.toggleMealStatus(studentId, date, currentValue)).called(1);
      });
    });

    group('toggleToiletStatus', () {
      test('should delegate to repository with correct parameters', () async {
        // Arrange
        const studentId = 'student123';
        const date = '2025-12-22';
        const currentValue = true;
        when(mockRepository.toggleToiletStatus(studentId, date, currentValue))
            .thenAnswer((_) async {});

        // Act
        await studentService.toggleToiletStatus(studentId, date, currentValue);

        // Assert
        verify(mockRepository.toggleToiletStatus(studentId, date, currentValue)).called(1);
      });
    });

    group('toggleSleepStatus', () {
      test('should delegate to repository with correct parameters', () async {
        // Arrange
        const studentId = 'student123';
        const date = '2025-12-22';
        const currentValue = false;
        when(mockRepository.toggleSleepStatus(studentId, date, currentValue))
            .thenAnswer((_) async {});

        // Act
        await studentService.toggleSleepStatus(studentId, date, currentValue);

        // Assert
        verify(mockRepository.toggleSleepStatus(studentId, date, currentValue)).called(1);
      });
    });
  });
}
