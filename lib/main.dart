import 'package:cafe_bda/providers/sheet_provider.dart';
import 'package:cafe_bda/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/google_sheets_screen.dart';

/// Point d'entrée de l'application Café BDA.
///
/// Responsabilités :
/// 1. Initialiser le binding Flutter.
/// 2. Charger les variables d'environnement (`.env`) contenant les clés API.
/// 3. Initialiser le Provider global (`SheetProvider`).
/// 4. Lancer l'interface utilisateur (`MyApp`).
Future<void> main() async {
  // S'assure que les liaisons Flutter sont prêtes pour les appels asynchrones (ex: dotenv)
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Charge les configurations sensibles (Client ID, Spreadsheet ID)
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Erreur critique lors du chargement du fichier .env: $e");
    // En prod, on pourrait afficher un écran d'erreur bloquant ici.
  }

  // Lance l'application en injectant le Provider à la racine.
  runApp(
    ChangeNotifierProvider(
      create: (context) => SheetProvider(),
      child: const MyApp(),
    ),
  );
}

/// Le widget racine de l'application.
///
/// Configure le thème global et définit l'écran d'accueil.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Café BDA',
      theme: AppTheme.lightTheme, // Application du Design System
      home: const GoogleSheetsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}