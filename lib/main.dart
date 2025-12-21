import 'package:cafe_bda/providers/auth_provider.dart';
import 'package:cafe_bda/providers/cafe_data_provider.dart';
import 'package:cafe_bda/repositories/cafe_repository.dart';
import 'package:cafe_bda/services/google_sheets_service.dart';
import 'package:cafe_bda/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/google_sheets_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Erreur critique lors du chargement du fichier .env: $e");
  }

  // Initialisation des services et repositories (Singletons)
  final sheetsService = GoogleSheetsService();
  final cafeRepository = CafeRepository(sheetsService);

  runApp(
    MultiProvider(
      providers: [
        // Injection du Service et du Repository pour un accès direct si besoin (ex: currentUser)
        Provider<GoogleSheetsService>.value(value: sheetsService),
        Provider<CafeRepository>.value(value: cafeRepository),
        
        // Providers gérant l'état
        ChangeNotifierProvider(
          create: (_) => AuthProvider(sheetsService),
        ),
        ChangeNotifierProvider(
          create: (_) => CafeDataProvider(cafeRepository, sheetsService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Café BDA',
      theme: AppTheme.lightTheme,
      home: const GoogleSheetsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
