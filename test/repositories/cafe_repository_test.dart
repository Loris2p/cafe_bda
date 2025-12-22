import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cafe_bda/repositories/cafe_repository.dart';
import 'package:cafe_bda/utils/constants.dart';
import '../mocks.mocks.dart';

void main() {
  late CafeRepository repository;
  late MockGoogleSheetsService mockSheetsService;

  setUp(() {
    mockSheetsService = MockGoogleSheetsService();
    repository = CafeRepository(mockSheetsService);
  });

  group('CafeRepository', () {
    test('getStudentsTable returns data from service', () async {
      final mockData = [
        ['Nom', 'Prenom'],
        ['Doe', 'John']
      ];
      when(mockSheetsService.readTable(AppConstants.studentsTable))
          .thenAnswer((_) async => mockData);

      final result = await repository.getStudentsTable(forceRefresh: true);

      expect(result, mockData);
      verify(mockSheetsService.readTable(AppConstants.studentsTable)).called(1);
    });

    test('getStudentsTable uses cache when available', () async {
      final mockData = [
        ['Nom', 'Prenom'],
        ['Doe', 'John']
      ];
      when(mockSheetsService.readTable(AppConstants.studentsTable))
          .thenAnswer((_) async => mockData);

      // First call to populate cache
      await repository.getStudentsTable(forceRefresh: true);
      
      // Second call should use cache
      final result = await repository.getStudentsTable(forceRefresh: false);

      expect(result, mockData);
      verify(mockSheetsService.readTable(AppConstants.studentsTable)).called(1); // Still called once
    });

    test('addStudent calculates row index and calls appendToTable', () async {
      final currentData = [
        ['Header'],
        ['Row 1']
      ]; // 2 rows total
      when(mockSheetsService.readTable(AppConstants.studentsTable))
          .thenAnswer((_) async => currentData);
      
      final formData = {
        'Nom': 'Smith',
        'Prenom': 'Jane',
        'Num etudiant': '12345',
        'Cycle + groupe': 'A1'
      };

      await repository.addStudent(formData);

      // Row index should be currentData.length + 1 = 3
      // We verify that appendToTable is called with a list containing the formula referencing row 3
      final verifyCall = verify(mockSheetsService.appendToTable(
        AppConstants.studentsTable, 
        captureAny, 
        valueInputOption: 'USER_ENTERED'
      ));
      
      final capturedRow = verifyCall.captured.first as List<dynamic>;
      expect(capturedRow[0], 'Smith');
      expect(capturedRow[4], contains('F3')); // Formula check
    });
  });
}
