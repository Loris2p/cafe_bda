import 'dart:async';
import 'dart:io';

import 'package:cafe_bda/repositories/cafe_repository.dart';
import 'package:cafe_bda/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/google_sheets_service.dart';

/// Gère l'état global et la logique métier de l'application (Pattern Provider).
///
/// Cette classe centralise :
/// * L'état de l'authentification.
/// * Les données chargées depuis Google Sheets (Etudiants, Stocks...).
/// * Les états de chargement (loading spinners) et les messages d'erreur.
/// * Les résultats de recherche locale.
///
/// Elle notifie les widgets abonnés via [notifyListeners] lors des changements d'état.
class SheetProvider with ChangeNotifier {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  late final CafeRepository _cafeRepository;

  // --- États Privés ---
  
  /// Les données actuellement affichées dans le tableau principal.
  List<List<dynamic>> _sheetData = [];
  
  /// Les résultats de la recherche d'étudiants courante.
  List<List<dynamic>> _searchResults = [];
  
  /// Copie locale de la table "Étudiants" pour permettre la recherche rapide et les listes déroulantes
  /// sans avoir à recharger l'onglet principal.
  List<List<dynamic>> _studentsData = [];
  
  bool _isLoading = false;
  bool _isAuthenticating = false;
  String _errorMessage = '';
  String _selectedTable = AppConstants.studentsTable;

  final List<String> _availableTables = [
    AppConstants.studentsTable,
    AppConstants.creditsTable,
    AppConstants.paymentsTable,
    AppConstants.stockTable,
  ];

  // --- Getters Publics ---
  
  List<List<dynamic>> get sheetData => _sheetData;
  List<List<dynamic>> get searchResults => _searchResults;
  List<List<dynamic>> get studentsData => _studentsData;
  bool get isLoading => _isLoading;
  bool get isAuthenticating => _isAuthenticating;
  String get errorMessage => _errorMessage;
  String get selectedTable => _selectedTable;
  List<String> get availableTables => _availableTables;
  
  /// Indique si l'utilisateur est connecté à Google Sheets API.
  bool get isAuthenticated => _sheetsService.sheetsApi != null;

  /// Initialise le Provider, configure le Repository et tente l'auto-connexion.
  SheetProvider() {
    _cafeRepository = CafeRepository(_sheetsService);
    _initializeApp();
  }

  /// Vérifie l'environnement et tente de restaurer une session précédente au démarrage.
  Future<void> _initializeApp() async {
    _errorMessage = _sheetsService.checkEnvVariables();
    if (_errorMessage.isNotEmpty) {
      notifyListeners();
      return;
    }

    _isAuthenticating = true;
    notifyListeners();

    final autoAuthSuccess = await _sheetsService.tryAutoAuthenticate();
    
    _isAuthenticating = false;
    if (autoAuthSuccess) {
      // Charge les données initiales si connecté
      await readTable();
    }
    notifyListeners();
  }

  /// Lance le processus d'authentification complet (avec interaction utilisateur si nécessaire).
  ///
  /// * Vérifie d'abord la connectivité internet.
  /// * Gère les erreurs réseaux et d'API.
  /// 
  /// * Returns - Un message d'erreur [String] si échec, ou `null` si succès.
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
      
      _isAuthenticating = false;
      if (error != null) {
        _errorMessage = error;
        notifyListeners();
        return error;
      }

      await readTable();
      notifyListeners();
      return null;
    } catch (e) {
      _isAuthenticating = false;
      _errorMessage = 'Erreur Auth: ${e.toString()}';
      notifyListeners();
      return _errorMessage;
    }
  }

  /// Déconnecte l'utilisateur et vide toutes les données locales en mémoire.
  Future<void> logout() async {
    await _sheetsService.logout();
    _sheetData = [];
    _searchResults = [];
    _studentsData = [];
    notifyListeners();
  }

  /// Charge les données de la table sélectionnée ou demandée.
  ///
  /// Utilise le cache du Repository pour la table Étudiants afin d'optimiser les performances.
  ///
  /// * [tableName] - Optionnel. Si fourni, change la table active (_selectedTable).
  Future<void> readTable({String? tableName}) async {
    if (tableName != null) {
      _selectedTable = tableName;
    }
    
    await _executeTransaction(() async {
      List<List<dynamic>>? data;
      
      if (_selectedTable == AppConstants.studentsTable) {
        // Utilise le cache intelligent pour les étudiants
        data = await _cafeRepository.getStudentsTable();
        if (data != null) {
          _studentsData = data;
        }
      } else {
        // Lecture standard pour les autres tables
        data = await _cafeRepository.getGenericTable(_selectedTable);
      }
      
      _sheetData = data ?? [];
      
      // S'assure que les données étudiants sont chargées en arrière-plan même si on est sur un autre onglet
      // (Nécessaire pour les formulaires de commande/crédit qui nécessitent la liste des étudiants)
      if (_studentsData.isEmpty && _selectedTable != AppConstants.studentsTable) {
         final sData = await _cafeRepository.getStudentsTable();
         if (sData != null) _studentsData = sData;
      }
    });
  }

  /// Charge spécifiquement les données de stock pour les formulaires de commande.
  ///
  /// * Returns - La liste des stocks.
  Future<List<List<dynamic>>> loadStockData() async {
    return await _cafeRepository.getGenericTable(AppConstants.stockTable) ?? [];
  }

  /// Helper générique pour exécuter des transactions asynchrones (DRY).
  ///
  /// Gère automatiquement :
  /// * L'état `isLoading` (true au début, false à la fin).
  /// * La capture des erreurs (`try/catch`).
  /// * La notification de l'UI.
  ///
  /// * [action] - La fonction asynchrone à exécuter.
  /// * Returns - Un message d'erreur ou null.
  Future<String?> _executeTransaction(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await action();
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      return _errorMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Traite la soumission du formulaire d'inscription étudiant.
  Future<String?> handleRegistrationForm(Map<String, dynamic> formData) async {
    return _executeTransaction(() async {
      await _cafeRepository.addStudent(formData);
      // Rafraîchir la vue pour montrer le nouvel étudiant
      await readTable();
    });
  }
  
  /// Traite la soumission d'un ajout de crédit.
  Future<String?> handleCreditSubmission(Map<String, dynamic> formData) async {
    return _executeTransaction(() async {
      await _cafeRepository.addCreditRecord(formData);
      // Si on visionne les crédits, on rafraîchit la table
      if (_selectedTable == AppConstants.creditsTable) {
        await readTable();
      }
    });
  }

  /// Traite la soumission d'une nouvelle commande.
  Future<String?> handleOrderSubmission(Map<String, dynamic> formData) async {
    return _executeTransaction(() async {
      await _cafeRepository.addOrderRecord(formData);
      // Si on visionne les paiements, on rafraîchit la table
      if (_selectedTable == AppConstants.paymentsTable) {
        await readTable();
      }
    });
  }
  
  /// Effectue une recherche locale (filtrage) dans la liste des étudiants chargés.
  ///
  /// * [searchTerm] - Le texte à chercher (Nom, prénom, num étudiant...).
  /// * Returns - La liste des lignes correspondantes.
  Future<List<List<dynamic>>> searchStudent(String searchTerm) async {
    if (searchTerm.isEmpty) {
      _searchResults = [];
      return [];
    }

    // Note d'optimisation : On ne déclenche pas le spinner (_isLoading) pour une recherche locale rapide
    // afin d'éviter un scintillement de l'interface.

    final results = _studentsData.skip(1).where((row) {
      return row.any(
        (cell) =>
            cell != null &&
            cell.toString().toLowerCase().contains(searchTerm.toLowerCase()),
      );
    }).toList();

    _searchResults = results;
    notifyListeners(); // Met à jour l'UI avec les résultats
    return results;
  }
}