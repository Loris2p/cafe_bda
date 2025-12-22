import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cafe_bda/providers/cafe_data_provider.dart';
import 'package:cafe_bda/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks.mocks.dart';

void main() {
  late CafeDataProvider provider;
  late MockCafeRepository mockRepository;
  late MockGoogleSheetsService mockSheetsService;

  setUp(() {
    SharedPreferences.setMockInitialValues({}); // Mock SharedPreferences
    mockRepository = MockCafeRepository();
    mockSheetsService = MockGoogleSheetsService();
    provider = CafeDataProvider(mockRepository, mockSheetsService);
  });

  group('CafeDataProvider', () {
    test('readTable loads students data correctly', () async {
      final mockData = [
        ['Nom', 'Prenom'],
        ['Alice', 'Bob']
      ];
      when(mockRepository.getStudentsTable(forceRefresh: anyNamed('forceRefresh')))
          .thenAnswer((_) async => mockData);

      await provider.readTable(tableName: AppConstants.studentsTable);

      expect(provider.sheetData, mockData);
      expect(provider.studentsData, mockData);
      expect(provider.selectedTable, AppConstants.studentsTable);
    });

    test('searchStudent filters data correctly', () async {
      // Setup initial data manually since we can't easily mock the internal state
      // But we can rely on readTable to set it up.
      final mockData = [
        ['Nom', 'Prenom', 'Num'],
        ['Doe', 'John', '123'],
        ['Smith', 'Jane', '456']
      ];
      when(mockRepository.getStudentsTable(forceRefresh: anyNamed('forceRefresh')))
          .thenAnswer((_) async => mockData);
      
      await provider.readTable(tableName: AppConstants.studentsTable);

      final results = await provider.searchStudent('Jane');
      
      expect(results.length, 1);
      expect(results.first[1], 'Jane');
    });

    test('sortData sorts numbers correctly', () {
      // Inject data directly via readTable mock
      final mockData = [
        ['Name', 'Score'],
        ['A', '10'],
        ['B', '2']
      ];
       when(mockRepository.getStudentsTable(forceRefresh: anyNamed('forceRefresh')))
          .thenAnswer((_) async => mockData);
      
      provider.readTable(tableName: AppConstants.studentsTable).then((_) {
         provider.sortData(1); // Sort by Score
         
         // After sort (ascending): '2' should come before '10' numerically
         expect(provider.sheetData[1][1], '2');
         expect(provider.sheetData[2][1], '10');
      });
    });
  });
}
