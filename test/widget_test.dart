import 'package:cafe_bda/providers/auth_provider.dart';
import 'package:cafe_bda/providers/cafe_data_provider.dart';
import 'package:cafe_bda/screens/google_sheets_screen.dart';
import 'package:cafe_bda/services/google_sheets_service.dart';
import 'package:cafe_bda/repositories/cafe_repository.dart';
import 'package:cafe_bda/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'mocks.mocks.dart';

// Manual Mock for AuthProvider as simpler alternative to generated one for this test
class MockAuthProvider extends Mock implements AuthProvider {
  @override
  bool get isAuthenticated => true;
  @override
  bool get isAuthenticating => false;
  @override
  String get errorMessage => '';
  @override
  Future<void> initialize() async {}
}

void main() {
  testWidgets('App smoke test - loads Dashboard', (WidgetTester tester) async {
    // Mocks
    final mockDataProvider = MockCafeDataProvider();
    final mockAuthProvider = MockAuthProvider();
    final mockSheetsService = MockGoogleSheetsService();
    final mockRepository = MockCafeRepository();

    // Stubs
    when(mockDataProvider.availableTables).thenReturn(['Étudiants']);
    when(mockDataProvider.selectedTable).thenReturn(AppConstants.studentsTable);
    when(mockDataProvider.isLoading).thenReturn(false);
    when(mockDataProvider.errorMessage).thenReturn('');
    when(mockDataProvider.sheetData).thenReturn([]);
    when(mockDataProvider.studentsData).thenReturn([]);
    when(mockDataProvider.columnVisibility).thenReturn({});
    when(mockDataProvider.paymentConfigs).thenReturn([]);
    when(mockDataProvider.initData()).thenAnswer((_) async {});
    when(mockDataProvider.loadStockData()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GoogleSheetsService>.value(value: mockSheetsService),
          Provider<CafeRepository>.value(value: mockRepository),
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider<CafeDataProvider>.value(value: mockDataProvider),
        ],
        child: const MaterialApp(
          home: GoogleSheetsScreen(),
        ),
      ),
    );

    // Verify Dashboard is shown
    expect(find.text('Bienvenue au Café BDA'), findsOneWidget);
  });
}
