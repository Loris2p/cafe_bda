import 'dart:async';
import 'dart:convert';
import 'package:googleapis/sheets/v4.dart';

import 'package:cafe_bda/repositories/cafe_repository.dart';
import 'package:cafe_bda/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  int? _sortColumnIndex;
  bool _sortAscending = true;
  Map<String, List<bool>> _columnVisibility = {};
  String? _responsableName;

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
  int? get sortColumnIndex => _sortColumnIndex;
  bool get sortAscending => _sortAscending;
  Map<String, List<bool>> get columnVisibility => _columnVisibility;
  String? get responsableName => _responsableName;
  
  /// Le service sous-jacent pour les interactions avec Google Sheets.
  GoogleSheetsService get sheetsService => _sheetsService;
  
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
      // Charge les paramètres et les données initiales si connecté
      await _loadColumnVisibility();
      await _loadResponsableName();
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

      // Charge les paramètres et les données après une connexion réussie
      await _loadColumnVisibility();
      await _loadResponsableName();
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
    _sortColumnIndex = null;
    _columnVisibility = {}; // Réinitialise les paramètres de visibilité
    _responsableName = null;
    notifyListeners();
  }

  /// Charge les données de la table sélectionnée ou demandée.
  ///
  /// Utilise le cache du Repository pour la table Étudiants afin d'optimiser les performances.
  ///
  /// * [tableName] - Optionnel. Si fourni, change la table active (_selectedTable).
  /// * [forceRefresh] - Si `true`, ignore le cache et force une nouvelle lecture depuis la source.
  Future<void> readTable({String? tableName, bool forceRefresh = false}) async {
    if (tableName != null && tableName != _selectedTable) {
      _selectedTable = tableName;
      _sortColumnIndex = null; // Réinitialiser le tri lors du changement de table
    }

    if (forceRefresh) {
      _cafeRepository.invalidateCache();
    }
    
    await _executeTransaction(() async {
      List<List<dynamic>>? data;
      
      if (_selectedTable == AppConstants.studentsTable) {
        // Utilise le cache intelligent pour les étudiants
        data = await _cafeRepository.getStudentsTable(forceRefresh: forceRefresh);
        if (data != null) {
          _studentsData = data;
        }
      } else {
        // Lecture standard pour les autres tables (pas de cache ici)
        data = await _cafeRepository.getGenericTable(_selectedTable);
      }
      
      _sheetData = data ?? [];

      // Initialise les paramètres de visibilité si non existants
      if (_sheetData.isNotEmpty && (_columnVisibility[_selectedTable] == null || _columnVisibility[_selectedTable]!.length != _sheetData[0].length)) {
        _columnVisibility[_selectedTable] = List.generate(_sheetData[0].length, (_) => true);
        await _saveColumnVisibility();
      }
      
      // S'assure que les données étudiants (pour les formulaires) sont à jour si on force le rafraîchissement
      if ((_studentsData.isEmpty || forceRefresh) && _selectedTable != AppConstants.studentsTable) {
         final sData = await _cafeRepository.getStudentsTable(forceRefresh: forceRefresh);
         if (sData != null) _studentsData = sData;
      }
    });
  }

  /// Trie les données de la table actuellement affichée.
  void sortData(int columnIndex) {
    if (_sortColumnIndex == columnIndex) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumnIndex = columnIndex;
      _sortAscending = true;
    }

    if (_sheetData.length > 1) {
      final header = _sheetData.first;
      final rows = _sheetData.sublist(1);

      rows.sort((a, b) {
        final aValue = a.length > columnIndex ? a[columnIndex] : null;
        final bValue = b.length > columnIndex ? b[columnIndex] : null;

        // Gestion des valeurs nulles
        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return _sortAscending ? -1 : 1;
        if (bValue == null) return _sortAscending ? 1 : -1;
        
        // Gestion des booléens
        if (aValue is bool && bValue is bool) {
          final compare = aValue.toString().compareTo(bValue.toString());
          return _sortAscending ? compare : -compare;
        }
        
        // Tentative de comparaison numérique
        final aNum = num.tryParse(aValue.toString());
        final bNum = num.tryParse(bValue.toString());

        int compare;
        if (aNum != null && bNum != null) {
          compare = aNum.compareTo(bNum);
        } else {
          // Comparaison de chaînes de caractères (insensible à la casse)
          compare = aValue.toString().toLowerCase().compareTo(bValue.toString().toLowerCase());
        }

        return _sortAscending ? compare : -compare;
      });

      _sheetData = [header, ...rows]; // Crée une nouvelle liste pour la notification
    }
    notifyListeners();
  }
  
  /// Charge spécifiquement les données de stock pour les formulaires de commande.
  ///
  /// * Returns - La liste des stocks.
  Future<List<List<dynamic>>> loadStockData() async {
    return await _cafeRepository.getGenericTable(AppConstants.stockTable) ?? [];
  }

  // --- Gestion de la visibilité des colonnes ---

  /// Sauvegarde le nom du responsable pour l'utilisateur actuel.
  Future<void> saveResponsableName(String name) async {
    final userId = _sheetsService.currentUser?.id;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'responsable_name_$userId';
    await prefs.setString(key, name);
    _responsableName = name;
    notifyListeners();
  }

  /// Charge le nom du responsable pour l'utilisateur actuel.
  Future<void> _loadResponsableName() async {
    final userId = _sheetsService.currentUser?.id;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'responsable_name_$userId';
    _responsableName = prefs.getString(key);
    notifyListeners();
  }

  /// Met à jour la visibilité d'une colonne et sauvegarde les préférences.
  void setColumnVisibility(int columnIndex, bool isVisible) {
    if (_columnVisibility[_selectedTable] != null &&
        columnIndex < _columnVisibility[_selectedTable]!.length) {
      
      // Crée de nouvelles copies de la liste et de la map pour assurer la détection du changement d'état.
      final newVisibilityList = List<bool>.from(_columnVisibility[_selectedTable]!);
      newVisibilityList[columnIndex] = isVisible;
      
      final newVisibilityMap = Map<String, List<bool>>.from(_columnVisibility);
      newVisibilityMap[_selectedTable] = newVisibilityList;
      
      _columnVisibility = newVisibilityMap;
      
      // Notifie l'UI immédiatement pour une réactivité maximale.
      notifyListeners();

      // Sauvegarde les préférences en arrière-plan sans bloquer l'UI.
      _saveColumnVisibility();
    }
  }

  /// Charge les préférences de visibilité des colonnes pour l'utilisateur actuel.
  Future<void> _loadColumnVisibility() async {
    final userId = _sheetsService.currentUser?.id;
    if (userId == null) {
      _columnVisibility = {}; // Pas d'utilisateur, pas de paramètres
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final key = 'column_visibility_$userId';
    final jsonString = prefs.getString(key);
    
    if (jsonString != null) {
      try {
        final Map<String, dynamic> decodedMap = json.decode(jsonString);
        _columnVisibility = decodedMap.map(
          (key, value) => MapEntry(key, List<bool>.from(value)),
        );
      } catch(e) {
        _columnVisibility = {};
        await prefs.remove(key);
      }
    }
    else {
      _columnVisibility = {};
    }
    notifyListeners();
  }

  /// Sauvegarde les préférences de visibilité pour l'utilisateur actuel.
  Future<void> _saveColumnVisibility() async {
    final userId = _sheetsService.currentUser?.id;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'column_visibility_$userId';
    final jsonString = json.encode(_columnVisibility);
    await prefs.setString(key, jsonString);
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
        if (e is DetailedApiRequestError && e.status == 403) {
          _errorMessage = 'PERMISSION_DENIED';
        } else {
          _errorMessage = e.toString();
        }
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
      await readTable(forceRefresh: true);
    });
  }
  
  /// Traite la soumission d'un ajout de crédit.
  Future<String?> handleCreditSubmission(Map<String, dynamic> formData) async {
    return _executeTransaction(() async {
      await _cafeRepository.addCreditRecord(formData);
      _cafeRepository.invalidateCache();
      // Si on visionne les crédits ou les étudiants, on rafraîchit la table
      if (_selectedTable == AppConstants.creditsTable || _selectedTable == AppConstants.studentsTable) {
        await readTable(forceRefresh: true);
      }
    });
  }

  /// Traite la soumission d'une nouvelle commande.
  Future<String?> handleOrderSubmission(Map<String, dynamic> formData) async {
    return _executeTransaction(() async {
      await _cafeRepository.addOrderRecord(formData);
      _cafeRepository.invalidateCache();
      // Si on visionne les paiements ou les étudiants, on rafraîchit la table
      if (_selectedTable == AppConstants.paymentsTable || _selectedTable == AppConstants.studentsTable) {
        await readTable(forceRefresh: true);
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

  /// Met à jour la valeur d'une cellule et gère l'état de l'interface utilisateur.
  ///
  /// * [rowIndex] - L'index de la ligne de données (base 0, après l'en-tête).
  /// * [colIndex] - L'index de la colonne (base 0).
  /// * [newValue] - La nouvelle valeur.
  /// * Returns - Un message d'erreur en cas d'échec, sinon null.
  Future<String?> updateCellValue(int rowIndex, int colIndex, dynamic newValue) async {
    final tableName = _selectedTable;
    // L'index de ligne dans _sheetData doit tenir compte de l'en-tête.
    final dataRowIndex = rowIndex + 1;

    if (dataRowIndex >= _sheetData.length || colIndex >= _sheetData[dataRowIndex].length) {
      return "Erreur : Index hors limites.";
    }

    final oldValue = _sheetData[dataRowIndex][colIndex];
    
    // Mise à jour optimiste de l'UI : Crée une nouvelle liste pour que le Provider notifie les auditeurs.
    final newSheetData = _sheetData.map((row) => List<dynamic>.from(row)).toList();
    newSheetData[dataRowIndex][colIndex] = newValue;
    _sheetData = newSheetData;
    notifyListeners();
    
    try {
      await _cafeRepository.updateCellValue(tableName, rowIndex, colIndex, newValue);
      // Le cache pour 'Stock' n'est pas géré agressivement, donc pas besoin d'invalider.
      return null;
    } catch (e) {
      // Annuler en cas d'échec
      final revertedSheetData = _sheetData.map((row) => List<dynamic>.from(row)).toList();
      revertedSheetData[dataRowIndex][colIndex] = oldValue;
      _sheetData = revertedSheetData;

      _errorMessage = "La mise à jour a échoué: ${e.toString()}";
      notifyListeners();
      return _errorMessage;
    }
  }
}