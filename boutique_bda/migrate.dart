import 'dart:io';
import 'package:firedart/firedart.dart';

// Configuration (Extraite de vos firebase_options.dart)
const String projectId = 'boutique-bda';

void main() async {
  print('🚀 Demarrage de la migration (Correction unites : Cafe -> Euro)...');

  Firestore.initialize(projectId);
  print('✅ Connexion a Firestore etablie.');

  try {
    await migrateStudents();
    print('\n✨ Migration terminee avec succes ! Les soldes sont maintenant en Euros.');
  } catch (e) {
    print('\n❌ Erreur pendant la migration : $e');
  }
}

Future<void> migrateStudents() async {
  print('\n👥 Migration des etudiants (Conversion : 1 cafe = 0.50€)...');
  final file = File('assets/csv migration/Café 2025-2026 - Étudiants.csv');
  
  if (!await file.exists()) {
    print('❌ Fichier Etudiants non trouve.');
    return;
  }

  final lines = await file.readAsLines();
  int count = 0;
  for (var i = 1; i < lines.length; i++) {
    final row = lines[i].split(',');
    if (row.length < 5) continue;

    final String studentId = row[2].trim();
    if (studentId.isEmpty) continue;
    
    // Conversion du solde : Nb Cafes * 0.50
    final double coffeeCount = double.tryParse(row[4].replaceAll(',', '.')) ?? 0.0;
    final double balanceInEuro = coffeeCount * 0.50;

    final data = {
      'lastName': row[0].trim(),
      'firstName': row[1].trim(),
      'studentId': studentId,
      'classGroup': row[3].trim(),
      'balance': balanceInEuro, // Stocké en Euros
      'loyaltyBonus': row.length > 8 ? (int.tryParse(row[8]) ?? 0) : 0,
      'totalBought': row.length > 9 ? (int.tryParse(row[9]) ?? 0) : 0,
      'lastTransactionAt': DateTime.now().toIso8601String(),
    };

    await Firestore.instance.collection('students').document(studentId).set(data);
    count++;
    stdout.write('\rEtudiants mis a jour : $count');
  }
  print('\n✅ $count etudiants mis a jour avec le solde en Euros.');
}
