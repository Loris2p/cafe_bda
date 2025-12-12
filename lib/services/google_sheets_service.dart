import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// A service class for interacting with the Google Sheets API.
///
/// This class handles authentication (OAuth 2.0) and provides methods for
/// basic CRUD (Create, Read, Update, Delete) operations on a Google Sheet.
/// It is designed to be a generic service, with all business-specific logic
/// handled by the [CafeRepository].
class GoogleSheetsService {
  // Constants for SharedPreferences keys
  static const _authCredentialsKey = 'google_auth_credentials';
  static const _authClientIdKey = 'google_auth_client_id';
  static const _authClientSecretKey = 'google_auth_client_secret';

  // The authenticated Google Sheets API client.
  SheetsApi? sheetsApi;
  auth_io.AutoRefreshingAuthClient? client;

  /// Checks if the required environment variables are set in the .env file.
  String checkEnvVariables() {
    final clientId = dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (clientId.isEmpty || clientSecret.isEmpty || spreadsheetId.isEmpty) {
      return 'Variables manquantes dans .env:\n'
          'GOOGLE_CLIENT_ID: ${clientId.isEmpty ? "MANQUANT" : "OK"}\n'
          'GOOGLE_CLIENT_SECRET: ${clientSecret.isEmpty ? "MANQUANT" : "OK"}\n'
          'GOOGLE_SPREADSHEET_ID: ${spreadsheetId.isEmpty ? "MANQUANT" : "OK"}';
    }
    return '';
  }

  /// Tries to automatically authenticate the user using stored credentials.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> tryAutoAuthenticate() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCredentials = prefs.getString(_authCredentialsKey);
    final storedClientId = prefs.getString(_authClientIdKey);
    final storedClientSecret = prefs.getString(_authClientSecretKey);
    final currentClientId = dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
    final currentClientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';

    if (storedCredentials != null &&
        storedClientId == currentClientId &&
        storedClientSecret == currentClientSecret) {
      try {
        final credentialsJson = json.decode(storedCredentials);
        final credentials =
            auth_io.AccessCredentials.fromJson(credentialsJson);
        final clientId =
            auth_io.ClientId(currentClientId, currentClientSecret);
        client = await auth_io.autoRefreshingClient(
          clientId,
          credentials,
          http.Client(),
        );
        sheetsApi = SheetsApi(client!);
        return true;
      } catch (e) {
        await _clearStoredAuth();
        return false;
      }
    }
    return false;
  }

  /// Authenticates the user based on the platform (mobile or desktop).
  Future<String?> authenticate() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return _authenticateMobile();
    } else {
      return _authenticateDesktop();
    }
  }

  /// Logs the user out, clearing stored credentials and closing the client.
  Future<void> logout() async {
    await _clearStoredAuth();
    client?.close();
    sheetsApi = null;
    client = null;
  }

  /// Reads data from a specified range in the Google Sheet.
  Future<List<List<dynamic>>?> readTable(String rangeName) async {
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (spreadsheetId.isEmpty || sheetsApi == null) return null;
    try {
      final response = await sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        rangeName,
      );
      return response.values;
    } catch (e) {
      rethrow;
    }
  }

  /// Appends a row of data to a specified table (range).
  Future<void> appendToTable(
    String rangeName,
    List<dynamic> rowData, {
    bool useFormulas = false,
  }) async {
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (spreadsheetId.isEmpty || sheetsApi == null) {
      throw Exception('Spreadsheet ID manquant ou non authentifié');
    }
    try {
      final valueRange = ValueRange()..values = [rowData];
      await sheetsApi!.spreadsheets.values.append(
        valueRange,
        spreadsheetId,
        rangeName,
        valueInputOption: useFormulas ? 'USER_ENTERED' : 'RAW',
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Private helper methods

  /// Stores the user's authentication credentials securely.
  Future<void> _storeAuthCredentials(
    auth_io.AccessCredentials credentials,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _authCredentialsKey,
      json.encode(credentials.toJson()),
    );
    await prefs.setString(
      _authClientIdKey,
      dotenv.env['GOOGLE_CLIENT_ID'] ?? '',
    );
    await prefs.setString(
      _authClientSecretKey,
      dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '',
    );
  }

  /// Clears the stored authentication credentials.
  Future<void> _clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authCredentialsKey);
    await prefs.remove(_authClientIdKey);
    await prefs.remove(_authClientSecretKey);
  }

  /// Handles the authentication flow for desktop platforms.
  Future<String?> _authenticateDesktop() async {
    final clientId = dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
    final clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
    final scopes = [SheetsApi.spreadsheetsScope];

    if (clientId.isEmpty || clientSecret.isEmpty) {
      return 'CLIENT_ID ou CLIENT_SECRET manquant dans .env';
    }

    try {
      final credentials = await auth_io.obtainAccessCredentialsViaUserConsent(
        auth_io.ClientId(clientId, clientSecret),
        scopes,
        http.Client(),
        (String url) async {
          final uri = Uri.parse(url);
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            throw 'Impossible d\'ouvrir $url';
          }
        },
      );
      await _storeAuthCredentials(credentials);
      client = await auth_io.autoRefreshingClient(
        auth_io.ClientId(clientId, clientSecret),
        credentials,
        http.Client(),
      );
      sheetsApi = SheetsApi(client!);
      return null;
    } catch (e) {
      return 'Erreur d\'authentification desktop: ${e.toString()}';
    }
  }

  /// Handles the authentication flow for mobile platforms (Android/iOS).
  Future<String?> _authenticateMobile() async {
    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;
      await signIn.signOut();
      final GoogleSignInAccount? googleUser = await signIn.authenticate(
        scopeHint: [SheetsApi.spreadsheetsScope],
      );

      if (googleUser == null) {
        return 'Connexion annulée par l\'utilisateur';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credentials = auth_io.AccessCredentials(
        auth_io.AccessToken(
          'Bearer',
          googleAuth.idToken!,
          DateTime.now().add(const Duration(hours: 1)),
        ),
        null,
        [SheetsApi.spreadsheetsScope],
      );

      final clientId = auth_io.ClientId(
        dotenv.env['GOOGLE_ANDROID_CLIENT_ID'] ?? '',
        dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '',
      );

      client = await auth_io.autoRefreshingClient(
        clientId,
        credentials,
        http.Client(),
      );

      sheetsApi = SheetsApi(client!);
      await _storeAuthCredentials(credentials);
      return null;
    } catch (e) {
      return 'Erreur d\'authentification mobile: ${e.toString()}';
    }
  }
  
  /// A method that is not used in the app but is kept for future use.
  Future<void> addStudentWithFormulas(
    Map<String, dynamic> formData,
    int rowNumber,
  ) async {
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (spreadsheetId.isEmpty || sheetsApi == null) {
      throw Exception('Spreadsheet ID manquant ou non authentifié');
    }
    try {
      // Préparer les données avec les formules adaptées au numéro de ligne
      final List<dynamic> rowData = [
        formData['Nom'],
        formData['Prenom'],
        formData['Num etudiant'],
        formData['Cycle + groupe'],
        '=F$rowNumber-G$rowNumber+I$rowNumber', // Nb Cafés Restants
        '=SIERREUR(SOMME.SI(Credit[Numéro étudiant];C$rowNumber; Credit[Nb de Cafés]); 0)', // Nb Cafés Crédités
        '=SIERREUR(SOMME.SI.ENS(Paiements[Nb de Cafés]; Paiements[Numéro étudiant]; C$rowNumber; Paiements[Moyen Paiement]; "Crédit");0)', // Nb Cafés Pris SUR crédit
        '=SIERREUR(SOMME.SI.ENS(Paiements[Nb de Cafés]; Paiements[Numéro étudiant]; C$rowNumber; Paiements[Moyen Paiement]; "<>Crédit"); 0)', // Nb Cafés Payés HORS crédit
        '=ENT((G$rowNumber+H$rowNumber)/10)', // Nb cafés Fidélité Obtenus
      ];
      final valueRange = ValueRange()..values = [rowData];
      await sheetsApi!.spreadsheets.values.append(
        valueRange,
        spreadsheetId,
        'Étudiants',
        valueInputOption: 'USER_ENTERED',
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// A method that is not used in the app but is kept for future use.
  Future<void> addCreditRecord(Map<String, dynamic> creditData) async {
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (spreadsheetId.isEmpty || sheetsApi == null) {
      throw Exception('Spreadsheet ID manquant ou non authentifié');
    }
    try {
      // Préparer les données dans l'ordre des colonnes
      final List<dynamic> rowData = [
        creditData['Date'],
        creditData['Responsable'],
        creditData['Numéro étudiant'],
        creditData['Nom'],
        creditData['Prenom'],
        creditData['Classe + Groupe'],
        creditData['Valeur (€)'],
        creditData['Nb de Cafés'],
        creditData['Moyen Paiement'], // Nouvelle colonne ajoutée
      ];
      await appendToTable('Credits', rowData);
    } catch (e) {
      rethrow;
    }
  }

  /// A method that is not used in the app but is kept for future use.
  Future<void> addOrderRecord(Map<String, dynamic> orderData) async {
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (spreadsheetId.isEmpty || sheetsApi == null) {
      throw Exception('Spreadsheet ID manquant ou non authentifié');
    }
    try {
      // Préparer les données dans l'ordre des colonnes du tableau Paiements
      final List<dynamic> rowData = [
        orderData['Date'],
        orderData['Moyen Paiement'],
        orderData['Nom de famille'],
        orderData['Prénom'],
        orderData['Numéro étudiant'],
        orderData['Nb de Cafés'],
        orderData['Café pris'],
      ];
      await appendToTable('Paiements', rowData);
    } catch (e) {
      rethrow;
    }
  }
  
  /// A method that is not used in the app but is kept for future use.
  Future<int> getNextRowInNamedRange(String rangeName) async {
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (spreadsheetId.isEmpty || sheetsApi == null) {
      throw Exception('Spreadsheet ID manquant ou non authentifié');
    }
    try {
      // Lire directement les données du tableau nommé
      final response = await sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        rangeName,
      );
      final currentData = response.values ?? [];
      return currentData.isEmpty ? 1 : currentData.length + 1;
    } catch (e) {
      // Fallback: utiliser une méthode basique
      final response = await sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        'A:Z',
      );
      final currentData = response.values ?? [];
      return currentData.isEmpty ? 1 : currentData.length + 1;
    }
  }
}
