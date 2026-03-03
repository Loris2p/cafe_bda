import 'dart:io';
import 'package:firedart/firedart.dart';

// Configuration (Extraite de vos firebase_options.dart)
const String projectId = 'boutique-bda';

void main() async {
  print('🚀 Demarrage de la migration (Version simplifiee)...');

  Firestore.initialize(projectId);
  print('✅ Connexion a Firestore etablie.');

  try {
    await migrateStudents();
    await migrateProducts();
    print('\n✨ Migration terminee avec succes !');
  } catch (e) {
    print('\n❌ Erreur pendant la migration : $e');
  }
}

Future<void> migrateStudents() async {
  print('\n👥 Migration des etudiants...');
  final file = File('assets/csv migration/Café 2025-2026 - Étudiants.csv');
  
  if (!await file.exists()) {
    print('❌ Fichier Etudiants non trouve : ${file.path}');
    return;
  }

  final lines = await file.readAsLines();
  if (lines.isEmpty) return;

  int count = 0;
  // On ignore l'en-tête (ligne 0)
  for (var i = 1; i < lines.length; i++) {
    final row = lines[i].split(',');
    if (row.length < 5) continue;

    final String studentId = row[2].trim();
    if (studentId.isEmpty) continue;
    
    final data = {
      'lastName': row[0].trim(),
      'firstName': row[1].trim(),
      'studentId': studentId,
      'classGroup': row[3].trim(),
      'balance': double.tryParse(row[4].replaceAll(',', '.')) ?? 0.0,
      'loyaltyBonus': row.length > 8 ? (int.tryParse(row[8]) ?? 0) : 0,
      'totalBought': row.length > 9 ? (int.tryParse(row[9]) ?? 0) : 0,
      'lastTransactionAt': DateTime.now().toIso8601String(),
    };

    await Firestore.instance.collection('students').document(studentId).set(data);
    count++;
    stdout.write('\rEtudiants migres : $count');
  }
  print('\n✅ $count etudiants importes.');
}

Future<void> migrateProducts() async {
  print('\n☕ Migration des produits (Stocks)...');
  final file = File('assets/csv migration/Café 2025-2026 - Stocks.csv');

  if (!await file.exists()) {
    print('❌ Fichier Stocks non trouve.');
    return;
  }

  final lines = await file.readAsLines();
  int count = 0;
  for (var i = 1; i < lines.length; i++) {
    final row = lines[i].split(',');
    if (row.length < 2) continue;

    final String name = row[0].trim();
    if (name == '?' || name.isEmpty) continue;

    final data = {
      'name': name,
      'price': 0.50, 
      'isAvailable': row[1].trim().toUpperCase() == 'TRUE',
      'category': 'Café',
    };

    await Firestore.instance.collection('products').add(data);
    count++;
    stdout.write('\rProduits importes : $count');
  }
  print('\n✅ $count produits ajoutes au catalogue.');
}
