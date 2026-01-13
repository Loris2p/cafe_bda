import 'package:cafe_bda/repositories/cafe_repository.dart';
import 'package:cafe_bda/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  late CafeRepository repository;
  late MockGoogleSheetsService mockSheetsService;

  setUp(() {
    mockSheetsService = MockGoogleSheetsService();
    repository = CafeRepository(mockSheetsService);
  });

  group('CafeRepository - Schema Compliance', () {
    
    // -------------------------------------------------------------------------
    // 1. Feuille ÉTUDIANTS (Formules et Structure)
    // -------------------------------------------------------------------------
    test('addStudent writes correct formulas for row indices', () async {
      // Setup: Mock existing data to determine "nextRow".
      // If there is 1 header + 1 data row, length is 2. Next row should be 3.
      final currentData = [
        ['Header'], // Row 1
        ['Data 1']  // Row 2
      ];
      when(mockSheetsService.readTable(AppConstants.studentsTable))
          .thenAnswer((_) async => currentData);

      final formData = {
        'Nom': 'Skywalker',
        'Prenom': 'Luke',
        'Num etudiant': '12345',
        'Cycle + groupe': 'Jedi 1'
      };

      await repository.addStudent(formData);

      final verifyCall = verify(mockSheetsService.appendToTable(
        AppConstants.studentsTable,
        captureAny,
        valueInputOption: 'USER_ENTERED',
      ));

      final capturedRow = verifyCall.captured.single as List<dynamic>;

      // Expected Row Index = 3 (Current length 2 + 1)
      const expectedRowIdx = 3;

      // Check Column Order & Values
      expect(capturedRow[0], 'Skywalker'); // A: Nom
      expect(capturedRow[1], 'Luke');      // B: Prenom
      expect(capturedRow[2], '12345');     // C: Num etudiant
      expect(capturedRow[3], 'Jedi 1');    // D: Cycle + groupe
      
      // Check Formulas (Must match SHEETS_SCHEMA.md EXACTLY)
      // E: Solde Restant = F - G + I
      expect(capturedRow[4], '=F$expectedRowIdx-G$expectedRowIdx+I$expectedRowIdx');
      
      // F: Total Crédité (SOMME.SI)
      expect(capturedRow[5], contains('SOMME.SI(Credit[Numéro étudiant];C$expectedRowIdx; Credit[Nb de Cafés])'));
      
      // G: Total Consommé sur Crédit (SOMME.SI.ENS ... "Crédit")
      expect(capturedRow[6], contains('SOMME.SI.ENS(Paiements[Nb de Cafés]; Paiements[Numéro étudiant]; C$expectedRowIdx; Paiements[Moyen Paiement]; "Crédit")'));
      
      // H: Total Payé Cash (SOMME.SI.ENS ... "<>Crédit")
      expect(capturedRow[7], contains('SOMME.SI.ENS(Paiements[Nb de Cafés]; Paiements[Numéro étudiant]; C$expectedRowIdx; Paiements[Moyen Paiement]; "<>Crédit")'));
      
      // I: Fidélité (ENT((G+H)/10))
      expect(capturedRow[8], '=ENT((G$expectedRowIdx+H$expectedRowIdx)/10)');
    });

    // -------------------------------------------------------------------------
    // 2. Feuille CREDITS (Historique Rechargements)
    // -------------------------------------------------------------------------
    test('addCreditRecord respects column order from Schema', () async {
      final formData = {
        'Date': '2023-10-27 10:00:00',
        'Responsable': 'Admin',
        'Numéro étudiant': '12345',
        'Nom': 'Kenobi',
        'Prenom': 'Obi-Wan',
        'Classe + Groupe': 'Jedi Master',
        'Valeur (€)': 10.0,
        'Nb de Cafés': 20,
        'Moyen Paiement': 'Lydia'
      };

      await repository.addCreditRecord(formData);

      final verifyCall = verify(mockSheetsService.appendToTable(
        AppConstants.creditsTable,
        captureAny,
        valueInputOption: 'USER_ENTERED',
      ));

      final capturedRow = verifyCall.captured.single as List<dynamic>;

      // Schema: Date, Resp, Num, Nom, Prenom, Classe, Valeur, NbCafes, MoyenPaiement
      expect(capturedRow[0], '2023-10-27 10:00:00');
      expect(capturedRow[1], 'Admin');
      expect(capturedRow[2], '12345');
      expect(capturedRow[3], 'Kenobi');
      expect(capturedRow[4], 'Obi-Wan');
      expect(capturedRow[5], 'Jedi Master');
      expect(capturedRow[6], 10.0);
      expect(capturedRow[7], 20);
      expect(capturedRow[8], 'Lydia');
    });

    // -------------------------------------------------------------------------
    // 3. Feuille PAIEMENTS (Historique Commandes)
    // -------------------------------------------------------------------------
    test('addOrderRecord respects column order from Schema', () async {
      final formData = {
        'Date': '2023-10-27 12:00:00',
        'Moyen Paiement': 'Crédit',
        'Nom de famille': 'Solo',
        'Prénom': 'Han',
        'Numéro étudiant': '999',
        'Nb de Cafés': 2,
        'Café pris': 'Espresso'
      };

      await repository.addOrderRecord(formData);

      final verifyCall = verify(mockSheetsService.appendToTable(
        AppConstants.paymentsTable,
        captureAny,
        valueInputOption: 'USER_ENTERED',
      ));

      final capturedRow = verifyCall.captured.single as List<dynamic>;

      // Schema: Date, Moyen Paiement, Nom, Prénom, Numéro, Nb Cafés, Café pris
      expect(capturedRow[0], '2023-10-27 12:00:00');
      expect(capturedRow[1], 'Crédit');
      expect(capturedRow[2], 'Solo');
      expect(capturedRow[3], 'Han');
      expect(capturedRow[4], '999');
      expect(capturedRow[5], 2);
      expect(capturedRow[6], 'Espresso');
    });

    // -------------------------------------------------------------------------
    // 4. Feuille STOCKS
    // -------------------------------------------------------------------------
    test('updateCellValue is used correctly for Stocks', () async {
      // This is a generic method, but we verify it can pass boolean values
      // which is critical for the "Disponible" column in Stocks.
      
      await repository.updateCellValue(AppConstants.stockTable, 5, 1, false);

      verify(mockSheetsService.updateCell(
        AppConstants.stockTable, 
        5, 
        1, 
        false
      )).called(1);
    });
  });
}
