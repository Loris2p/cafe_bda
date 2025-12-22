import 'dart:convert';
import 'package:cafe_bda/repositories/cafe_repository.dart';
import 'package:cafe_bda/services/google_sheets_service.dart';
import 'package:cafe_bda/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gère les données métier de l'application (Étudiants, Crédits, Stocks...).
class CafeDataProvider with ChangeNotifier {
  final CafeRepository _cafeRepository;
  final GoogleSheetsService _sheetsService;

  List<List<dynamic>> _sheetData = [];
  List<List<dynamic>> _searchResults = [];
  List<List<dynamic>> _studentsData = [];
  
  bool _isLoading = false;
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

  CafeDataProvider(this._cafeRepository, this._sheetsService);

  // --- Getters ---
  List<List<dynamic>> get sheetData => _sheetData;
  List<List<dynamic>> get searchResults => _searchResults;
  List<List<dynamic>> get studentsData => _studentsData;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedTable => _selectedTable;
  List<String> get availableTables => _availableTables;
  int? get sortColumnIndex => _sortColumnIndex;
  bool get sortAscending => _sortAscending;
  Map<String, List<bool>> get columnVisibility => _columnVisibility;
  String? get responsableName => _responsableName;

  /// Initialise les données une fois l'utilisateur authentifié.
  Future<void> initData() async {
    await _loadColumnVisibility();
    await _loadResponsableName();
    await readTable();
  }

  /// Vide les données locales (lors de la déconnexion).
  void clearData() {
    _sheetData = [];
    _searchResults = [];
    _studentsData = [];
    _sortColumnIndex = null;
    _columnVisibility = {};
    _responsableName = null;
    notifyListeners();
  }

  /// Charge les données de la table sélectionnée ou demandée.
  Future<void> readTable({String? tableName, bool forceRefresh = false}) async {
    if (tableName != null && tableName != _selectedTable) {
      _selectedTable = tableName;
      _sortColumnIndex = null;
      _sheetData = [];
    }

    if (forceRefresh) {
      _cafeRepository.invalidateCache();
    }
    
    await _executeTransaction(() async {
      List<List<dynamic>>? data;
      
      if (_selectedTable == AppConstants.studentsTable) {
        data = await _cafeRepository.getStudentsTable(forceRefresh: forceRefresh);
        if (data != null) {
          _studentsData = data;
        }
      } else {
        data = await _cafeRepository.getGenericTable(_selectedTable);
      }
      
      _sheetData = data ?? [];

      // Initialise les paramètres de visibilité si nécessaire
      if (_sheetData.isNotEmpty && (_columnVisibility[_selectedTable] == null || _columnVisibility[_selectedTable]!.length != _sheetData[0].length)) {
        _columnVisibility[_selectedTable] = List.generate(_sheetData[0].length, (_) => true);
        await _saveColumnVisibility();
      }
      
      // S'assure que les données étudiants (pour les formulaires) sont à jour
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

        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return _sortAscending ? -1 : 1;
        if (bValue == null) return _sortAscending ? 1 : -1;
        
        if (aValue is bool && bValue is bool) {
          final compare = aValue.toString().compareTo(bValue.toString());
          return _sortAscending ? compare : -compare;
        }
        
        final aNum = num.tryParse(aValue.toString());
        final bNum = num.tryParse(bValue.toString());

        int compare;
        if (aNum != null && bNum != null) {
          compare = aNum.compareTo(bNum);
        } else {
          compare = aValue.toString().toLowerCase().compareTo(bValue.toString().toLowerCase());
        }

        return _sortAscending ? compare : -compare;
      });

      _sheetData = [header, ...rows];
    }
    notifyListeners();
  }
  
  Future<List<List<dynamic>>> loadStockData() async {
    return await _cafeRepository.getGenericTable(AppConstants.stockTable) ?? [];
  }

  // --- Gestion de la visibilité des colonnes et préférences ---

  Future<void> saveResponsableName(String name) async {
    final userId = _sheetsService.currentUser?.id;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'responsable_name_$userId';
    await prefs.setString(key, name);
    _responsableName = name;
    notifyListeners();
  }

  Future<void> _loadResponsableName() async {
    final userId = _sheetsService.currentUser?.id;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'responsable_name_$userId';
    _responsableName = prefs.getString(key);
    notifyListeners();
  }

  void setColumnVisibility(int columnIndex, bool isVisible) {
    if (_columnVisibility[_selectedTable] != null &&
        columnIndex < _columnVisibility[_selectedTable]!.length) {
      
      final newVisibilityList = List<bool>.from(_columnVisibility[_selectedTable]!);
      newVisibilityList[columnIndex] = isVisible;
      
      final newVisibilityMap = Map<String, List<bool>>.from(_columnVisibility);
      newVisibilityMap[_selectedTable] = newVisibilityList;
      
      _columnVisibility = newVisibilityMap;
      notifyListeners();
      _saveColumnVisibility();
    }
  }

  Future<void> _loadColumnVisibility() async {
    final userId = _sheetsService.currentUser?.id;
    if (userId == null) {
      _columnVisibility = {};
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

  Future<void> _saveColumnVisibility() async {
    final userId = _sheetsService.currentUser?.id;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'column_visibility_$userId';
    final jsonString = json.encode(_columnVisibility);
    await prefs.setString(key, jsonString);
  }

  // --- Transactions ---

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
          clearData(); // Vide les données locales en cas de perte de droits
        } else {
          _errorMessage = e.toString();
        }
        return _errorMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> handleRegistrationForm(Map<String, dynamic> formData) async {
    return _executeTransaction(() async {
      await _cafeRepository.addStudent(formData);
      await readTable(forceRefresh: true);
    });
  }
  
  Future<String?> handleCreditSubmission(Map<String, dynamic> formData) async {
    return _executeTransaction(() async {
      await _cafeRepository.addCreditRecord(formData);
      _cafeRepository.invalidateCache();
      if (_selectedTable == AppConstants.creditsTable || _selectedTable == AppConstants.studentsTable) {
        await readTable(forceRefresh: true);
      }
    });
  }

  Future<String?> handleOrderSubmission(Map<String, dynamic> formData) async {
    return _executeTransaction(() async {
      await _cafeRepository.addOrderRecord(formData);
      _cafeRepository.invalidateCache();
      if (_selectedTable == AppConstants.paymentsTable || _selectedTable == AppConstants.studentsTable) {
        await readTable(forceRefresh: true);
      }
    });
  }
  
  Future<List<List<dynamic>>> searchStudent(String searchTerm) async {
    if (searchTerm.isEmpty) {
      _searchResults = [];
      return [];
    }

    final results = _studentsData.skip(1).where((row) {
      return row.any(
        (cell) =>
            cell != null &&
            cell.toString().toLowerCase().contains(searchTerm.toLowerCase()),
      );
    }).toList();

    _searchResults = results;
    notifyListeners();
    return results;
  }

  Future<String?> updateCellValue(int rowIndex, int colIndex, dynamic newValue) async {
    final tableName = _selectedTable;
    final dataRowIndex = rowIndex + 1;

    if (dataRowIndex >= _sheetData.length || colIndex >= _sheetData[dataRowIndex].length) {
      return "Erreur : Index hors limites.";
    }

    final oldValue = _sheetData[dataRowIndex][colIndex];
    
    final newSheetData = _sheetData.map((row) => List<dynamic>.from(row)).toList();
    newSheetData[dataRowIndex][colIndex] = newValue;
    _sheetData = newSheetData;
    notifyListeners();
    
    try {
      await _cafeRepository.updateCellValue(tableName, rowIndex, colIndex, newValue);
      return null;
    } catch (e) {
      final revertedSheetData = _sheetData.map((row) => List<dynamic>.from(row)).toList();
      revertedSheetData[dataRowIndex][colIndex] = oldValue;
      _sheetData = revertedSheetData;

      _errorMessage = "La mise à jour a échoué: ${e.toString()}";
      notifyListeners();
      return _errorMessage;
    }
  }
}
