import 'package:cafe_bda/services/google_sheets_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Gère l'état de l'authentification et la connexion aux services Google.
class AuthProvider with ChangeNotifier {
  final GoogleSheetsService _sheetsService;

  bool _isAuthenticating = false;
  String _errorMessage = '';

  AuthProvider(this._sheetsService);

  bool get isAuthenticating => _isAuthenticating;
  String get errorMessage => _errorMessage;
  
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
        await _sheetsService.logout();
        _errorMessage = 'PERMISSION_DENIED';
      }
    }
    
    _isAuthenticating = false;
    notifyListeners();
  }

  /// Lance le processus d'authentification complet.
  Future<String?> authenticate() async {
    _isAuthenticating = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
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
    await _sheetsService.logout();
    notifyListeners();
  }
}
