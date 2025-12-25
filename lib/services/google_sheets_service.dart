import 'package:cafe_bda/models/app_config.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Un client HTTP personnalisé qui injecte les en-têtes d'authentification dans chaque requête.
///
/// Cette classe est utilisée pour passer les credentials OAuth aux APIs Google.
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  /// Crée une instance de [GoogleAuthClient].
  ///
  /// * [_headers] : Les en-têtes HTTP (contenant le token Bearer).
  GoogleAuthClient(this._headers);

  /// Envoie une requête HTTP avec les en-têtes d'authentification ajoutés.
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

/// Service responsable de l'authentification et des interactions brutes avec l'API Google Sheets.
///
/// Ce service gère le flux OAuth 2.0 (Mobile et Desktop) et expose les méthodes CRUD génériques
/// (Lecture, Ajout). Il ne contient **aucune** logique métier spécifique à l'application Café BDA.
///
/// Voir [CafeRepository] pour la logique métier.
class GoogleSheetsService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [
    SheetsApi.spreadsheetsScope,
  ]);

  // Clés pour le stockage sécurisé des credentials
  static const _authCredentialsKey = 'google_auth_credentials';
  static const _authClientIdKey = 'google_auth_client_id';
  static const _authClientSecretKey = 'google_auth_client_secret';

  /// L'instance de l'API Google Sheets authentifiée.
  SheetsApi? sheetsApi;
  
  /// Le client HTTP authentifié (pour le Desktop).
  auth_io.AutoRefreshingAuthClient? client;

  /// L'utilisateur Google actuellement connecté.
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Vérifie si les variables d'environnement requises sont présentes.
  ///
  /// Retourne un message d'erreur listant les variables manquantes, ou une chaîne vide si tout est OK.
  ///
  /// * Returns - String (Message d'erreur ou vide).
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

  /// Tente d'authentifier l'utilisateur automatiquement avec les credentials stockés.
  ///
  /// * Sur Mobile : Tente un `signInSilently`.
  /// * Sur Desktop : Vérifie les `SharedPreferences` pour retrouver les tokens d'accès.
  ///
  /// * Returns - `true` si l'authentification silencieuse réussit, `false` sinon.
  Future<bool> tryAutoAuthenticate() async {
    // Pour mobile, on tente une connexion silencieuse
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          final authHeaders = await account.authHeaders;
          final httpClient = GoogleAuthClient(authHeaders);
          sheetsApi = SheetsApi(httpClient);
          return true;
        }
        return false;
      } catch (e) {
        return false;
      }
    }

    // Logique existante pour le bureau
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

  /// Authentifie l'utilisateur via le flux OAuth approprié à la plateforme.
  ///
  /// * Sur Mobile : Ouvre la pop-up Google Sign-In native.
  /// * Sur Desktop : Ouvre le navigateur par défaut pour l'autorisation.
  ///
  /// * Returns - `null` si succès, ou un message d'erreur [String] en cas d'échec.
  Future<String?> authenticate() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return _authenticateMobile();
    } else {
      return _authenticateDesktop();
    }
  }

  /// Déconnecte l'utilisateur et efface les données de session.
  ///
  /// * Supprime les credentials stockés localement.
  /// * Révoque l'accès Google Sign-In (sur mobile).
  /// * Ferme le client HTTP.
  Future<void> logout() async {
    await _clearStoredAuth();
    if (Platform.isAndroid || Platform.isIOS) {
      await _googleSignIn.signOut();
    }
    client?.close();
    sheetsApi = null;
    client = null;
  }

  /// Vérifie si l'utilisateur authentifié a bien les droits de lecture sur le fichier.
  ///
  /// Effectue une lecture minimale (A1) pour valider l'accès.
  ///
  /// * Returns - `true` si l'accès est confirmé, `false` sinon.
  Future<bool> checkSpreadsheetAccess() async {
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (spreadsheetId.isEmpty || sheetsApi == null) return false;
    
    try {
      // Tente de lire une seule cellule pour vérifier les droits
      await sheetsApi!.spreadsheets.values.get(spreadsheetId, 'A1');
      return true;
    } catch (e) {
      // Si erreur 403 ou autre, on considère que l'accès est refusé
      return false;
    }
  }

  /// Lit les données brutes d'une plage (Range) dans le Google Sheet.
  ///
  /// * [rangeName] - Le nom de la feuille ou de la plage nommée (ex: 'Étudiants', 'A1:B10').
  /// * Returns - Une liste de lignes `List<List<dynamic>>`, ou `null` si erreur/vide.
  /// * Throws - Exception si l'API échoue.
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

  /// Ajoute une ligne de données à la fin d'une table existante.
  ///
  /// * [rangeName] - La table cible (ex: 'Paiements').
  /// * [rowData] - La liste des valeurs à insérer.
  /// * [useFormulas] - Si `true`, les chaînes commençant par `=` sont interprétées comme des formules Excel.
  ///
  /// * Throws - [Exception] si non authentifié ou erreur API.
  Future<void> appendToTable(
    String rangeName,
    List<dynamic> rowData,
    {
    String valueInputOption = 'RAW',
  } ) async {
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
        valueInputOption: valueInputOption,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Met à jour une cellule spécifique dans le Google Sheet.
  ///
  /// * [rangeName] - Le nom de la feuille (ex: 'Stock').
  /// * [rowIndex] - L'index de la ligne de donnée (base 0, sans l'en-tête).
  /// * [colIndex] - L'index de la colonne (base 0).
  /// * [newValue] - La nouvelle valeur pour la cellule.
  Future<void> updateCell(String rangeName, int rowIndex, int colIndex, dynamic newValue) async {
    final spreadsheetId = dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
    if (spreadsheetId.isEmpty || sheetsApi == null) {
      throw Exception('Spreadsheet ID manquant ou non authentifié');
    }

    // rowIndex est en base 0 et exclut l'en-tête.
    // Les lignes de la feuille de calcul sont en base 1. L'en-tête est la ligne 1.
    // Donc, la ligne de données réelle est rowIndex + 2.
    final sheetRow = rowIndex + 2;
    final sheetCol = _columnIntToLetter(colIndex);
    final range = '$rangeName!$sheetCol$sheetRow';

    try {
      final valueRange = ValueRange()..values = [[newValue]];
      await sheetsApi!.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        range,
        valueInputOption: 'RAW',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère la configuration de l'application (versions, url) depuis la feuille 'Application'.
  ///
  /// Lit les colonnes A (Clé) et B (Valeur) de la feuille 'Application'.
  Future<AppConfig?> getAppConfig() async {
    final rows = await readTable('Application!A:B');
    if (rows == null || rows.isEmpty) return null;

    final Map<String, String> configMap = {};
    for (var row in rows) {
      if (row.length >= 2) {
        // row[0] est la clé, row[1] est la valeur
        configMap[row[0].toString().trim()] = row[1].toString().trim();
      }
    }
    return AppConfig.fromMap(configMap);
  }

  /// Convertit un index de colonne entier (base 0) en sa lettre correspondante (A, B, C...).
  String _columnIntToLetter(int column) {
    String result = "";
    int dividend = column + 1;
    while (dividend > 0) {
      int modulo = (dividend - 1) % 26;
      result = String.fromCharCode('A'.codeUnitAt(0) + modulo) + result;
      dividend = ((dividend - modulo) / 26).floor();
    }
    return result;
  }
  
  // --- Méthodes privées d'aide ---

  /// Stocke les credentials OAuth dans les SharedPreferences.
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

  /// Efface les credentials OAuth stockés.
  Future<void> _clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authCredentialsKey);
    await prefs.remove(_authClientIdKey);
    await prefs.remove(_authClientSecretKey);
  }

  /// Gère le flux d'authentification Desktop (via navigateur externe).
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

  /// Gère le flux d'authentification Mobile (via le plugin google_sign_in).
  Future<String?> _authenticateMobile() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return 'Connexion annulée';
      }

      final authHeaders = await account.authHeaders;
      final httpClient = GoogleAuthClient(authHeaders);
      
      sheetsApi = SheetsApi(httpClient);
      return null;
    } catch (e) {
      return 'Erreur d\'authentification mobile: ${e.toString()}';
    }
  }
}