import 'package:cafe_bda/providers/sheet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/google_sheets_screen.dart';

Future<void> main() async {
  // Ensure that the Flutter bindings are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables from the .env file.
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Erreur lors du chargement du fichier .env: $e");
  }

  // Run the app, wrapped in a ChangeNotifierProvider.
  // This makes the SheetProvider available to the entire widget tree.
  runApp(
    ChangeNotifierProvider(
      create: (context) => SheetProvider(),
      child: const MyApp(),
    ),
  );
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Sheets Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      // The main screen of the application.
      home: const GoogleSheetsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
