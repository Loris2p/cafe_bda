import 'dart:io';

// ignore_for_file: avoid_print

/// SCRIPT DE MISE À JOUR DE VERSION (LOCAL UNIQUEMENT)
/// 
/// Ce script met à jour la version dans le fichier pubspec.yaml.
/// La version Firestore doit être mise à jour manuellement sur la console.
/// 
/// POUR EXÉCUTER :
/// dart run update_version.dart [new_version]

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart update_version.dart <new_version>');
    print('Exemple: dart update_version.dart 10.1.0');
    exit(1);
  }

  final newVersion = args[0];
  print('🚀 Mise à jour locale vers la version $newVersion...');

  try {
    // Mise à jour de pubspec.yaml
    await updatePubspec(newVersion);
    print('✅ pubspec.yaml mis à jour.');
    print('\n✨ Version $newVersion appliquée localement !');
    print('⚠️ N\'oubliez pas de mettre à jour manuellement Firestore (collection: config, doc: app_version).');
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
      // On conserve le build number si présent (ex: 1.0.0+1)
      if (line.contains('+')) {
        final buildNumber = line.split('+').last;
        return 'version: $version+$buildNumber';
      }
      return 'version: $version';
    }
    return line;
  }).toList();

  await file.writeAsString(newLines.join('\n'));
}
