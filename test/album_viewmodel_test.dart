import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:inner_garden/viewmodels/album_viewmodel.dart';
import 'package:inner_garden/services/photo_service.dart';

// Generate mocks for testing
@GenerateMocks([PhotoService])
import 'album_viewmodel_test.mocks.dart';

void main() {
  group('AlbumViewModel', () {
    late AlbumViewModel viewModel;
    late MockPhotoService mockPhotoService;
    const testUserId = 'test_user_123';

    setUp(() {
      mockPhotoService = MockPhotoService();
      
      // Default stub to prevent MissingStubError during ViewModel init
      when(mockPhotoService.getPhotosByDateStream(
        studentId: anyNamed('studentId'),
        daysBack: anyNamed('daysBack'),
      )).thenAnswer((_) => Stream.value({}));
      
      viewModel = AlbumViewModel(
        photoService: mockPhotoService,
        userId: testUserId,
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('initial state should be loaded (stream completes immediately)', () async {
      // Allow microtasks to settle
      await Future.delayed(Duration.zero);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.photosByDate, isEmpty);
      expect(viewModel.errorMessage, isNull);
    });

    test('loadPhotos should fetch and cache data successfully', () async {
      // Arrange
      final mockData = {
        '2025-12-21': [
          {'url': 'https://example.com/photo1.jpg', 'timestamp': '2025-12-21T10:00:00Z'},
        ],
        '2025-12-20': [
          {'url': 'https://example.com/photo2.jpg', 'timestamp': '2025-12-20T15:30:00Z'},
        ],
      };

      when(mockPhotoService.getPhotosByDateStream(
        studentId: testUserId,
        daysBack: 14,
      )).thenAnswer((_) => Stream.value(mockData));

      // Act
      await viewModel.loadPhotos();

      // Assert
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.photosByDate, equals(mockData));
      expect(viewModel.errorMessage, isNull);
      // Called once in constructor + once manually
      verify(mockPhotoService.getPhotosByDateStream(
        studentId: testUserId,
        daysBack: 14,
      )).called(2);
    });

    test('loadPhotos should not refetch if already loaded today', () async {
      // Arrange
      final mockData = {
        '2025-12-21': [
          {'url': 'https://example.com/photo1.jpg'},
        ],
      };

      when(mockPhotoService.getPhotosByDateStream(
        studentId: testUserId,
        daysBack: 14,
      )).thenAnswer((_) => Stream.value(mockData));

      // Act - First load (manual)
      await viewModel.loadPhotos();
      
      // Act - Second load (same day)
      await viewModel.loadPhotos();

      // Assert - Should only call service twice (constructor + first manual load)
      verify(mockPhotoService.getPhotosByDateStream(
        studentId: testUserId,
        daysBack: 14,
      )).called(2);
    });

    test('refresh should force reload regardless of cache', () async {
      // Arrange
      final mockData1 = {
        '2025-12-21': [
          {'url': 'https://example.com/photo1.jpg'},
        ],
      };
      final mockData2 = {
        '2025-12-21': [
          {'url': 'https://example.com/photo1.jpg'},
          {'url': 'https://example.com/photo2.jpg'},
        ],
      };

      when(mockPhotoService.getPhotosByDateStream(
        studentId: testUserId,
        daysBack: 14,
      )).thenAnswer((_) => Stream.value(mockData1));

      // Act - First load
      await viewModel.loadPhotos();
      
      // Change the mock response
      when(mockPhotoService.getPhotosByDateStream(
        studentId: testUserId,
        daysBack: 14,
      )).thenAnswer((_) => Stream.value(mockData2));

      // Act - Refresh
      await viewModel.refresh();

      // Assert - Constructor + First Load + Refresh = 3 calls
      verify(mockPhotoService.getPhotosByDateStream(
        studentId: testUserId,
        daysBack: 14,
      )).called(3);
      expect(viewModel.photosByDate, equals(mockData2));
    });

    test('loadPhotos should handle errors gracefully', () async {
      // Arrange
      when(mockPhotoService.getPhotosByDateStream(
        studentId: testUserId,
        daysBack: 14,
      )).thenAnswer((_) => Stream.error('Network error'));

      // Act
      await viewModel.loadPhotos();

      // Assert
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.photosByDate, isEmpty);
      expect(viewModel.errorMessage, contains('Failed to load photos'));
    });

    test('clearError should remove error message', () async {
      // Arrange - Cause an error
      when(mockPhotoService.getPhotosByDateStream(
        studentId: testUserId,
        daysBack: 14,
      )).thenAnswer((_) => Stream.error('Network error'));

      await viewModel.loadPhotos();
      expect(viewModel.errorMessage, isNotNull);

      // Act
      viewModel.clearError();

      // Assert
      expect(viewModel.errorMessage, isNull);
    });
  });
}
