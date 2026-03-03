import 'package:cafe_bda/services/auth_service.dart';
import 'package:cafe_bda/services/google_sheets_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Gère l'état de l'authentification via Firebase Auth et Google Sign-In.
class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final GoogleSheetsService _sheetsService;

  bool _isAuthenticating = false;
  String _errorMessage = '';
  String? _deniedEmail;

  AuthProvider(this._authService, this._sheetsService);

  bool get isAuthenticating => _isAuthenticating;
  String get errorMessage => _errorMessage;
  String? get deniedEmail => _deniedEmail;
  
  /// Indique si l'utilisateur est connecté à Firebase Auth.
  bool get isAuthenticated => _authService.currentUser != null;

  User? get currentUser => _authService.currentUser;

  /// Tente de restaurer une session précédente au démarrage.
  Future<void> initialize() async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      final user = await _authService.signInSilently();
      
      if (user != null && _authService.accessToken != null) {
        _sheetsService.setAccessToken(_authService.accessToken!);
      }
    } catch (e) {
      print('Erreur initialisation auth: $e');
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Lance le processus d'authentification Firebase via Google.
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

      final user = await _authService.signInWithGoogle();
      
      if (user == null) {
        _isAuthenticating = false;
        notifyListeners();
        return 'Authentification annulée';
      }

      if (_authService.accessToken != null) {
        _sheetsService.setAccessToken(_authService.accessToken!);
      }
      
      _isAuthenticating = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isAuthenticating = false;
      _errorMessage = 'Erreur Firebase Auth: ${e.toString()}';
      notifyListeners();
      return _errorMessage;
    }
  }

  /// Déconnecte l'utilisateur.
  Future<void> logout() async {
    try {
      await _authService.signOut();
    } finally {
      _errorMessage = '';
      _deniedEmail = null;
      notifyListeners();
    }
  }

  /// Révoque l'accès et déconnecte.
  Future<void> revokeAccess() async {
    try {
      await _authService.disconnect();
    } finally {
      _errorMessage = '';
      _deniedEmail = null;
      notifyListeners();
    }
  }
}
