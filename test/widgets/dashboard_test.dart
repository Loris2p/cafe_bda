import 'package:cafe_bda/providers/auth_provider.dart';
import 'package:cafe_bda/providers/cafe_data_provider.dart';
import 'package:cafe_bda/screens/google_sheets_screen.dart';
import 'package:cafe_bda/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../mocks.mocks.dart';

// Create a MockAuthProvider manually since it's not in the main mocks file yet
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
  late MockCafeDataProvider mockDataProvider;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockDataProvider = MockCafeDataProvider();
    mockAuthProvider = MockAuthProvider();

    // Default stubs
    when(mockDataProvider.availableTables).thenReturn(['Étudiants', 'Stocks']);
    when(mockDataProvider.selectedTable).thenReturn(AppConstants.studentsTable);
    when(mockDataProvider.isLoading).thenReturn(false);
    when(mockDataProvider.errorMessage).thenReturn('');
    when(mockDataProvider.sheetData).thenReturn([]);
    when(mockDataProvider.studentsData).thenReturn([]);
    when(mockDataProvider.columnVisibility).thenReturn({});
    
    // Stub methods returning Futures
    when(mockDataProvider.initData()).thenAnswer((_) async {});
    when(mockDataProvider.loadStockData()).thenAnswer((_) async => []);
    when(mockDataProvider.fetchAllTableHeaders()).thenAnswer((_) => Future.value());
    when(mockDataProvider.tableHeaders).thenReturn({'DummyTable': ['Col1']});
    when(mockDataProvider.readTable(tableName: anyNamed('tableName')))
        .thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<CafeDataProvider>.value(value: mockDataProvider),
      ],
      child: const MaterialApp(
        home: GoogleSheetsScreen(),
      ),
    );
  }

  testWidgets('Dashboard displays welcome message and cards', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Flush future completion
    await tester.pumpAndSettle(); // Wait for animations/futures

    // Verify Welcome Text
    expect(find.text('Bienvenue au Café BDA'), findsOneWidget);

    // Verify Dashboard Cards
    expect(find.text('Étudiants'), findsOneWidget);
    expect(find.text('Stocks'), findsOneWidget);
    expect(find.text('Historique Paiements'), findsOneWidget);
  });

  testWidgets('Clicking on a dashboard card calls readTable', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Flush future completion
    await tester.pumpAndSettle();

    // Tap on Stocks card
    await tester.tap(find.text('Stocks'));
    
    verify(mockDataProvider.readTable(tableName: AppConstants.stockTable)).called(1);
  });
}
