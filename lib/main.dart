import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/google_sheets_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Erreur lors du chargement du fichier .env: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Sheets Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const GoogleSheetsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
