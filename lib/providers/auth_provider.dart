import 'package:cafe_bda/services/google_sheets_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Gère l'état de l'authentification et la connexion aux services Google.
class AuthProvider with ChangeNotifier {
  final GoogleSheetsService _sheetsService;

  bool _isAuthenticating = false;
  String _errorMessage = '';
  String? _deniedEmail;

  AuthProvider(this._sheetsService);

  bool get isAuthenticating => _isAuthenticating;
  String get errorMessage => _errorMessage;
  String? get deniedEmail => _deniedEmail;
  
  /// Indique si l'utilisateur est connecté à Google Sheets API.
  bool get isAuthenticated => _sheetsService.sheetsApi != null;

  /// Vérifie l'environnement et tente de restaurer une session précédente au démarrage.
  Future<void> initialize() async {
    _errorMessage = _sheetsService.checkEnvVariables();
    if (_errorMessage.isNotEmpty) {
      notifyListeners();
      return;
    }

    _isAuthenticating = true;
    notifyListeners();

    final autoAuthSuccess = await _sheetsService.tryAutoAuthenticate();
    
    if (autoAuthSuccess) {
      final hasAccess = await _sheetsService.checkSpreadsheetAccess();
      if (!hasAccess) {
        _deniedEmail = _sheetsService.currentUser?.email;
        await _sheetsService.logout();
        _errorMessage = 'PERMISSION_DENIED';
      }
    }
    
    _isAuthenticating = false;
    notifyListeners();
  }

  /// Lance le processus d'authentification complet.
  /// 
  /// Vérifie d'abord la connectivité Internet, puis appelle le service d'authentification Google.
  /// Après connexion, vérifie si l'utilisateur a les droits d'accès à la feuille de calcul.
  /// Retourne un message d'erreur en cas d'échec, sinon null.
  Future<String?> authenticate() async {
    _isAuthenticating = true;
    _errorMessage = '';
    _deniedEmail = null;
    notifyListeners();

    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        throw Exception('Pas de connexion Internet');
      }

      final error = await _sheetsService.authenticate();
      
      if (error != null) {
        _isAuthenticating = false;
        _errorMessage = error;
        notifyListeners();
        return error;
      }
      
      // Vérification des droits d'accès après connexion
      final hasAccess = await _sheetsService.checkSpreadsheetAccess();
      if (!hasAccess) {
        _deniedEmail = _sheetsService.currentUser?.email;
        await logout();
        _isAuthenticating = false;
        _errorMessage = 'PERMISSION_DENIED';
        notifyListeners();
        return _errorMessage;
      }
      
      _isAuthenticating = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isAuthenticating = false;
      _errorMessage = 'Erreur Auth: ${e.toString()}';
      notifyListeners();
      return _errorMessage;
    }
  }

  /// Déconnecte l'utilisateur.
  Future<void> logout() async {
    try {
      await _sheetsService.logout();
    } finally {
      _errorMessage = '';
      _deniedEmail = null;
      notifyListeners();
    }
  }
}
