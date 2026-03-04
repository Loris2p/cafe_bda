import 'dart:io';
import 'package:firedart/firedart.dart';

// --- CONFIGURATION ---
// Remplacez par votre Project ID Firebase
const String projectId = 'boutique-bda'; 

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart update_version.dart <new_version>');
    print('Exemple: dart update_version.dart 10.1.0');
    exit(1);
  }

  final newVersion = args[0];
  print('🚀 Mise à jour vers la version $newVersion...');

  try {
    // 1. Mise à jour de pubspec.yaml
    await updatePubspec(newVersion);
    print('✅ pubspec.yaml mis à jour.');

    // 2. Mise à jour de Firestore
    await updateFirestore(newVersion);
    print('✅ Firestore mis à jour.');

    print('\n✨ Version $newVersion déployée avec succès !');
  } catch (e) {
    print('\n❌ Erreur : $e');
    exit(1);
  }
}

Future<void> updatePubspec(String version) async {
  final file = File('pubspec.yaml');
  if (!await file.exists()) {
    throw Exception('Fichier pubspec.yaml introuvable.');
  }

  final lines = await file.readAsLines();
  final newLines = lines.map((line) {
    if (line.startsWith('version:')) {
      return 'version: $version';
    }
    return line;
  }).toList();

  await file.writeAsString(newLines.join('\n'));
}

Future<void> updateFirestore(String version) async {
  Firestore.initialize(projectId);
  
  await Firestore.instance.collection('config').document('app_version').set({
    'latest': version,
    'updatedAt': DateTime.now().toIso8601String(),
  });
}
