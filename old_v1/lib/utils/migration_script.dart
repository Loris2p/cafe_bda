import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/google_sheets_service.dart';
import '../utils/constants.dart';
import 'dart:developer' as developer;

class MigrationScript {
  final GoogleSheetsService _sheetsService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MigrationScript(this._sheetsService);

  /// Migre uniquement la table des étudiants de Google Sheets vers Firestore.
  Future<void> migrateStudents() async {
    developer.log('🚀 MIGRATION: Début du script', name: 'Migration');

    try {
      // 1. Récupération des données brutes
      developer.log('📊 MIGRATION: Lecture du Google Sheet...', name: 'Migration');
      final data = await _sheetsService.readTable(AppConstants.studentsTable);
      
      if (data == null || data.isEmpty) {
        developer.log('❌ MIGRATION: Aucune donnée trouvée ou erreur de lecture.', name: 'Migration');
        throw Exception('Impossible de lire les données du Google Sheet.');
      }

      final studentRows = data.skip(1).toList();
      developer.log('📈 MIGRATION: ${studentRows.length} étudiants trouvés.', name: 'Migration');

      // 2. Préparation du batch Firestore
      WriteBatch batch = _firestore.batch();
      int count = 0;
      int totalMigrated = 0;

      for (var row in studentRows) {
        if (row.length < 3) continue;

        final String studentId = row[2].toString().trim();
        if (studentId.isEmpty) continue;

        final docRef = _firestore.collection('students').doc(studentId);

        final Map<String, dynamic> studentData = {
          'lastName': _parseString(row, 0),
          'firstName': _parseString(row, 1),
          'studentId': studentId,
          'classGroup': _parseString(row, 3),
          'balance': _parseDouble(row, 4),
          'totalCredited': _parseDouble(row, 5),
          'totalConsumedOnCredit': _parseDouble(row, 6),
          'totalPaidCash': _parseDouble(row, 7),
          'loyaltyBonus': _parseInt(row, 8),
          'lastUpdated': FieldValue.serverTimestamp(),
          'migrationDate': FieldValue.serverTimestamp(),
        };

        batch.set(docRef, studentData);
        count++;
        totalMigrated++;

        if (count == 500) {
          developer.log('💾 MIGRATION: Envoi d\'un batch de 500...', name: 'Migration');
          await batch.commit().timeout(const Duration(seconds: 30));
          batch = _firestore.batch();
          count = 0;
        }
      }

      if (count > 0) {
        developer.log('💾 MIGRATION: Envoi du dernier batch ($count)...', name: 'Migration');
        await batch.commit().timeout(const Duration(seconds: 30));
      }

      developer.log('✅ MIGRATION: Succès ! $totalMigrated étudiants migrés.', name: 'Migration');
    } catch (e) {
      developer.log('🚨 MIGRATION: Erreur fatale : $e', name: 'Migration', error: e);
      rethrow;
    }
  }

  String _parseString(List<dynamic> row, int index) {
    if (index >= row.length) return '';
    return row[index]?.toString() ?? '';
  }

  double _parseDouble(List<dynamic> row, int index) {
    if (index >= row.length) return 0.0;
    final val = row[index]?.toString().replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '') ?? '0.0';
    return double.tryParse(val) ?? 0.0;
  }

  int _parseInt(List<dynamic> row, int index) {
    if (index >= row.length) return 0;
    final val = row[index]?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0';
    return int.tryParse(val) ?? 0;
  }
}
