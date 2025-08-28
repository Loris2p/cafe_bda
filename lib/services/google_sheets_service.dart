import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pour mobile seulement - conditionnel
import 'package:flutter_web_auth/flutter_web_auth.dart';

class GoogleSheetsService {
  static const _authCredentialsKey = 'google_auth_credentials';
  static const _authClientIdKey = 'google_auth_client_id';
  static const _authClientSecretKey = 'google_auth_client_secret';
  SheetsApi? sheetsApi;
  auth_io.AutoRefreshingAuthClient? client;
  
  // Pour mobile seulement
  final String _redirectUriMobile = 'com.cytechdata.exceleditor:/oauth2redirect';
  final String _customScheme = 'com.cytechdata.exceleditor';

  // Vérifier les variables d'environnement
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

  // Tentative d'authentification automatique au démarrage
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
        final credentials = auth_io.AccessCredentials.fromJson(credentialsJson);
        final clientId = auth_io.ClientId(currentClientId, currentClientSecret);
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

  // Stocker les credentials
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

  // Effacer les credentials stockés
  Future<void> _clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authCredentialsKey);
    await prefs.remove(_authClientIdKey);
    await prefs.remove(_authClientSecretKey);
  }

  Future<String?> authenticate() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return _authenticateMobile();
    } else {
      return _authenticateDesktop();
    }
  }

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

  Future<String?> _authenticateMobile() async {
    final clientId = dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
    final scopes = [SheetsApi.spreadsheetsScope];
    
    if (clientId.isEmpty) {
      return 'CLIENT_ID manquant dans .env';
    }

    try {
      final authUrl = 'https://accounts.google.com/o/oauth2/auth?' +
          'response_type=code&' +
          'client_id=$clientId&' +
          'redirect_uri=${Uri.encodeComponent(_redirectUriMobile)}&' +
          'scope=${Uri.encodeComponent(scopes.join(' '))}';

      final result = await FlutterWebAuth.authenticate(
        url: authUrl,
        callbackUrlScheme: _customScheme,
      );

      final code = Uri.parse(result).queryParameters['code'];
      
      if (code == null) {
        return 'Code d\'autorisation non reçu';
      }

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        body: {
          'code': code,
          'client_id': clientId,
          'redirect_uri': _redirectUriMobile,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> tokenData = jsonDecode(response.body);
        final credentials = auth_io.AccessCredentials(
          auth_io.AccessToken(
            'Bearer',
            tokenData['access_token'],
            DateTime.now().add(Duration(seconds: tokenData['expires_in'])),
          ),
          tokenData['refresh_token'],
          scopes,
        );
        
        await _storeAuthCredentials(credentials);
        
        // Initialiser le client
        final clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
        final authClientId = auth_io.ClientId(clientId, clientSecret);
        client = await auth_io.autoRefreshingClient(
          authClientId,
          credentials,
          http.Client(),
        );
        sheetsApi = SheetsApi(client!);
        
        return null;
      } else {
        return 'Erreur lors de l\'échange du token: ${response.statusCode}';
      }
    } catch (e) {
      return 'Erreur d\'authentification mobile: ${e.toString()}';
    }
  }

  // Déconnexion
  Future<void> logout() async {
    await _clearStoredAuth();
    client?.close();
    sheetsApi = null;
    client = null;
  }

  // Lire les données d'un tableau structuré
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

  // Obtenir la prochaine ligne dans un tableau nommé
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

  // Écrire dans un tableau structuré
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

  // Ajouter un enregistrement de crédit
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

  // Ajouter un étudiant avec formules adaptées
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

  // Mettre à jour une cellule spécifique
  Future<void> updateCell(String range, dynamic value) async {
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (spreadsheetId.isEmpty || sheetsApi == null) {
      throw Exception('Spreadsheet ID manquant ou non authentifié');
    }
    try {
      final valueRange = ValueRange()
        ..values = [
          [value],
        ];
      await sheetsApi!.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        range,
        valueInputOption: 'USER_ENTERED',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Obtenir les métadonnées de la feuille
  Future<Spreadsheet> getSpreadsheet() async {
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (spreadsheetId.isEmpty || sheetsApi == null) {
      throw Exception('Spreadsheet ID manquant ou non authentifié');
    }
    try {
      final response = await sheetsApi!.spreadsheets.get(
        spreadsheetId,
        includeGridData: false,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Méthode pour lire les données brutes d'une plage spécifique
  Future<List<List<dynamic>>?> getRawData(String range) async {
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (spreadsheetId.isEmpty || sheetsApi == null) return null;
    try {
      final response = await sheetsApi!.spreadsheets.values.get(
        spreadsheetId,
        range,
      );
      return response.values;
    } catch (e) {
      rethrow;
    }
  }

  // Méthode pour effacer une plage de données
  Future<void> clearRange(String range) async {
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (spreadsheetId.isEmpty || sheetsApi == null) return;
    try {
      final clearRequest = ClearValuesRequest();
      await sheetsApi!.spreadsheets.values.clear(
        clearRequest,
        spreadsheetId,
        range,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Méthode pour mettre à jour plusieurs cellules
  Future<void> updateCells(String range, List<List<dynamic>> values) async {
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (spreadsheetId.isEmpty || sheetsApi == null) return;
    try {
      final valueRange = ValueRange()
        ..range = range
        ..values = values;
      await sheetsApi!.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        range,
        valueInputOption: 'USER_ENTERED',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Ajouter une commande
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
}