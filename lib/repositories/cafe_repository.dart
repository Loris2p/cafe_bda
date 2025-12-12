import '../services/google_sheets_service.dart';
import '../utils/constants.dart';

/// The CafeRepository class is responsible for handling the business logic of the application.
///
/// It interacts with the [GoogleSheetsService] to perform CRUD operations on the Google Sheets document.
/// This separation of concerns makes the code more modular, easier to test, and easier to understand.
class CafeRepository {
  final GoogleSheetsService _sheetsService;

  CafeRepository(this._sheetsService);

  /// Adds a new student to the 'Étudiants' sheet.
  ///
  /// The [formData] is a map containing the student's information.
  /// This method calculates the next available row and then calls the [GoogleSheetsService]
  /// to add the student with the appropriate formulas.
  Future<void> addStudent(Map<String, dynamic> formData) async {
    final nextRow =
        await _sheetsService.getNextRowInNamedRange(AppConstants.studentsTable);
    await _sheetsService.addStudentWithFormulas(formData, nextRow);
  }

  /// Adds a credit record to the 'Credits' sheet.
  ///
  /// The [formData] is a map containing the credit information.
  Future<void> addCreditRecord(Map<String, dynamic> formData) async {
    await _sheetsService.addCreditRecord(formData);
  }

  /// Adds an order record to the 'Paiements' sheet.
  ///
  /// The [formData] is a map containing the order information.
  Future<void> addOrderRecord(Map<String, dynamic> formData) async {
    await _sheetsService.addOrderRecord(formData);
  }
}
