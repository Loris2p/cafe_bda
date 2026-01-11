import 'dart:convert';
import 'package:cafe_bda/models/app_config.dart';
import 'package:cafe_bda/models/payment_config.dart';
import 'package:cafe_bda/repositories/cafe_repository.dart';
import 'package:cafe_bda/services/google_sheets_service.dart';
import 'package:cafe_bda/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Gère les données métier de l'application (Étudiants, Crédits, Stocks...).
class CafeDataProvider with ChangeNotifier {
  final CafeRepository _cafeRepository;
  final GoogleSheetsService _sheetsService;

  CafeDataProvider(this._cafeRepository, this._sheetsService);

  List<List<dynamic>> _sheetData = [];
  List<List<dynamic>> _formulaData = [];
  List<List<dynamic>> _searchResults = [];
  List<List<dynamic>> _studentsData = [];
  List<PaymentConfig> _paymentConfigs = [];
  AppConfig? _appConfig;

  final List<String> _availableTables = [
    AppConstants.studentsTable,
    AppConstants.creditsTable,
    AppConstants.paymentsTable,
    AppConstants.stockTable,
  ];

  String _selectedTable = AppConstants.studentsTable;
  Map<String, List<String>> _tableHeaders = {};
  Map<String, List<bool>> _columnVisibility = {};
  int? _sortColumnIndex;
  bool _sortAscending = true;
  String? _responsableName;
  String _errorMessage = '';
  bool _isAdminMode = false;
  bool _isLoading = false;

  // Getters
  List<List<dynamic>> get sheetData => _sheetData;
  List<List<dynamic>> get formulaData => _formulaData;
  List<List<dynamic>> get searchResults => _searchResults;
  List<List<dynamic>> get studentsData => _studentsData;
  List<PaymentConfig> get paymentConfigs => _paymentConfigs;
  AppConfig? get appConfig => _appConfig;
  List<String> get availableTables => _availableTables;
  String get selectedTable => _selectedTable;
  Map<String, List<String>> get tableHeaders => _tableHeaders;
  Map<String, List<bool>> get columnVisibility => _columnVisibility;
  int? get sortColumnIndex => _sortColumnIndex;
  bool get sortAscending => _sortAscending;
  String? get responsableName => _responsableName;
  String get errorMessage => _errorMessage;
  bool get isAdminMode => _isAdminMode;
  bool get isLoading => _isLoading;

  set isAdminMode(bool value) {
    _isAdminMode = value;
    notifyListeners();
  }

  /// Initialise les données une fois l'utilisateur authentifié.
  Future<void> initData() async {
    await _loadColumnVisibility();
    await _loadResponsableName();
    await readTable();
    await fetchPaymentConfigs();
    await fetchAppConfig();
    await fetchAllTableHeaders();
  }

  /// Récupère la configuration de l'application (version, PIN...).
  Future<void> fetchAppConfig() async {
    try {
      _appConfig = await _sheetsService.getAppConfig();
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur lors de la récupération de la config app: $e");
    }
  }

  /// Récupère les configurations de paiement.
  Future<void> fetchPaymentConfigs() async {
    try {
      _paymentConfigs = await _cafeRepository.getPaymentConfigs();
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur lors de la récupération des configs de paiement: $e");
    }
  }

  /// Récupère les en-têtes de toutes les tables pour la configuration.
  Future<void> fetchAllTableHeaders() async {
    for (final table in _availableTables) {
      if (_tableHeaders.containsKey(table) && _tableHeaders[table]!.isNotEmpty) continue;

      try {
        final data = await _sheetsService.readTable('$table!1:1');
        if (data != null && data.isNotEmpty) {
          final headers = data[0].map((e) => e.toString()).toList();
          _tableHeaders[table] = headers;

          if (_columnVisibility[table] == null || _columnVisibility[table]!.length != headers.length) {
            _columnVisibility[table] = List.generate(headers.length, (_) => true);
          }
        }
      } catch (e) {
        debugPrint('Error fetching headers for $table: $e');
      }
    }
    await _saveColumnVisibility();
    notifyListeners();
  }

  /// Vide les données locales (lors de la déconnexion).
  void clearData() {
    _sheetData = [];
    _searchResults = [];
    _studentsData = [];
    _tableHeaders = {};
    _sortColumnIndex = null;
    _columnVisibility = {};
    _responsableName = null;
    _errorMessage = '';
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
      final results = await Future.wait([
        (_selectedTable == AppConstants.studentsTable)
            ? _cafeRepository.getStudentsTable(forceRefresh: forceRefresh)
            : _cafeRepository.getGenericTable(_selectedTable),
        _cafeRepository.getGenericTable(_selectedTable, renderOption: 'FORMULA'),
      ]);

      _sheetData = results[0] ?? [];
      _formulaData = results[1] ?? [];

      if (_selectedTable == AppConstants.studentsTable) {
        _studentsData = _sheetData;
      }

      if (_sheetData.isNotEmpty && (_columnVisibility[_selectedTable] == null || _columnVisibility[_selectedTable]!.length != _sheetData[0].length)) {
        _columnVisibility[_selectedTable] = List.generate(_sheetData[0].length, (_) => true);
        await _saveColumnVisibility();
      }

      if ((_studentsData.isEmpty || forceRefresh) && _selectedTable != AppConstants.studentsTable) {
        final sData = await _cafeRepository.getStudentsTable(forceRefresh: forceRefresh);
        if (sData != null) _studentsData = sData;
      }
    });
  }

  bool isCellFormula(int rowIndex, int colIndex) {
    if (rowIndex + 1 >= _formulaData.length || colIndex >= _formulaData[rowIndex + 1].length) {
      return false;
    }
    final cellValue = _formulaData[rowIndex + 1][colIndex].toString();
    return cellValue.startsWith('=');
  }

  DateTime? _tryParseDate(String value) {
    final formats = [
      DateFormat('dd/MM/yyyy HH:mm:ss'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('yyyy-MM-dd HH:mm:ss'),
      DateFormat('yyyy-MM-dd'),
    ];

    for (var format in formats) {
      try {
        return format.parseLoose(value);
      } catch (_) {}
    }
    return null;
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

        final aStr = aValue.toString();
        final bStr = bValue.toString();

        final aNum = num.tryParse(aStr);
        final bNum = num.tryParse(bStr);

        int compare;
        if (aNum != null && bNum != null) {
          compare = aNum.compareTo(bNum);
        } else {
          final aDate = _tryParseDate(aStr);
          final bDate = _tryParseDate(bStr);

          if (aDate != null && bDate != null) {
            compare = aDate.compareTo(bDate);
          } else {
            compare = aStr.toLowerCase().compareTo(bStr.toLowerCase());
          }
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

  void setColumnVisibility(int columnIndex, bool isVisible, {String? tableName}) {
    final targetTable = tableName ?? _selectedTable;
    if (_columnVisibility[targetTable] != null &&
        columnIndex < _columnVisibility[targetTable]!.length) {
      final newVisibilityList = List<bool>.from(_columnVisibility[targetTable]!);
      newVisibilityList[columnIndex] = isVisible;

      final newVisibilityMap = Map<String, List<bool>>.from(_columnVisibility);
      newVisibilityMap[targetTable] = newVisibilityList;

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
      } catch (e) {
        _columnVisibility = {};
        await prefs.remove(key);
      }
    } else {
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
        clearData();
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
        (cell) => cell != null && cell.toString().toLowerCase().contains(searchTerm.toLowerCase()),
      );
    }).toList();

    _searchResults = results;
    notifyListeners();
    return results;
  }

  Future<List<List<dynamic>>> searchCurrentTable(String searchTerm) async {
    if (searchTerm.isEmpty) {
      _searchResults = [];
      return [];
    }

    final dataToSearch = _sheetData.length > 1 ? _sheetData.sublist(1) : <List<dynamic>>[];

    final results = dataToSearch.where((row) {
      return row.any(
        (cell) => cell != null && cell.toString().toLowerCase().contains(searchTerm.toLowerCase()),
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