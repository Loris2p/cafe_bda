import 'dart:async';
import 'dart:io';

import 'package:cafe_bda/repositories/cafe_repository.dart';
import 'package:cafe_bda/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/google_sheets_service.dart';

/// Manages the application's state and business logic.
///
/// This class acts as a central hub for all user interactions and data manipulations.
/// It uses a [GoogleSheetsService] to interact with the Google Sheets API and a
/// [CafeRepository] to encapsulate the business logic.
///
/// It extends [ChangeNotifier] to notify its listeners when the state changes.
class SheetProvider with ChangeNotifier {
  // Service for interacting with the Google Sheets API.
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  // Repository for handling business logic.
  late final CafeRepository _cafeRepository;

  // Private state variables
  List<List<dynamic>> _sheetData = [];
  List<List<dynamic>> _searchResults = [];
  List<List<dynamic>> _studentsData = [];
  bool _isLoading = false;
  bool _isAuthenticating = false;
  String _errorMessage = '';
  String _selectedTable = AppConstants.studentsTable;

  // Available tables in the Google Sheet.
  final List<String> _availableTables = [
    AppConstants.studentsTable,
    AppConstants.creditsTable,
    AppConstants.paymentsTable,
    AppConstants.stockTable,
  ];

  // Public getters for the state
  List<List<dynamic>> get sheetData => _sheetData;
  List<List<dynamic>> get searchResults => _searchResults;
  List<List<dynamic>> get studentsData => _studentsData;
  bool get isLoading => _isLoading;
  bool get isAuthenticating => _isAuthenticating;
  String get errorMessage => _errorMessage;
  String get selectedTable => _selectedTable;
  List<String> get availableTables => _availableTables;
  bool get isAuthenticated => _sheetsService.sheetsApi != null;

  /// Initializes the provider by setting up the repository and attempting to auto-authenticate.
  SheetProvider() {
    _cafeRepository = CafeRepository(_sheetsService);
    _initializeApp();
  }

  /// Initializes the application by checking environment variables and attempting to auto-authenticate.
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
      await readTable();
      await _loadStudentsData();
    }
    notifyListeners();
  }

  /// Authenticates the user with Google and loads the initial data.
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
      await _loadStudentsData();
      notifyListeners();
      return null;
    } on SocketException {
      _isAuthenticating = false;
      _errorMessage = 'Erreur réseau: Veuillez vérifier votre connexion Internet.';
      notifyListeners();
      return _errorMessage;
    } catch (e) {
      _isAuthenticating = false;
      _errorMessage = 'Erreur lors de l\'authentification: ${e.toString()}';
      notifyListeners();
      return _errorMessage;
    }
  }

  /// Logs the user out and clears all data.
  Future<void> logout() async {
    await _sheetsService.logout();
    _sheetData = [];
    _searchResults = [];
    _studentsData = [];
    notifyListeners();
  }

  /// Reads the data from the selected table in the Google Sheet.
  Future<void> readTable({String? tableName}) async {
    _isLoading = true;
    _errorMessage = '';
    if(tableName != null){
      _selectedTable = tableName;
    }
    notifyListeners();

    try {
      final data = await _sheetsService.readTable(_selectedTable);
      _sheetData = data ?? [];
    } catch (e) {
      _errorMessage = 'Erreur de lecture: ${e.toString()}';
      if (e.toString().contains('authentication') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        await logout();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads the data for the 'Étudiants' table.
  Future<void> _loadStudentsData() async {
    try {
      final data = await _sheetsService.readTable(AppConstants.studentsTable);
      _studentsData = data ?? [];
      notifyListeners();
    } catch (e) {
      print('Erreur chargement données étudiants: $e');
    }
  }

  /// Loads the data for the 'Stocks' table.
  Future<List<List<dynamic>>> loadStockData() async {
    try {
      return await _sheetsService.readTable(AppConstants.stockTable) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Handles the submission of the registration form.
  Future<String?> handleRegistrationForm(Map<String, dynamic> formData) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _cafeRepository.addStudent(formData);
      
      await readTable();
      await _loadStudentsData();
      return null;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'enregistrement: ${e.toString()}';
      return _errorMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Handles the submission of the credit form.
  Future<String?> handleCreditSubmission(Map<String, dynamic> formData) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _cafeRepository.addCreditRecord(formData);

      if (_selectedTable == AppConstants.creditsTable) {
        await readTable();
      }
      return null;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'enregistrement: ${e.toString()}';
      return _errorMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handles the submission of the order form.
  Future<String?> handleOrderSubmission(Map<String, dynamic> formData) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _cafeRepository.addOrderRecord(formData);

      if (_selectedTable == AppConstants.paymentsTable) {
        await readTable();
      }
      return null;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'enregistrement: ${e.toString()}';
      return _errorMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Searches for a student in the loaded student data.
  Future<List<List<dynamic>>> searchStudent(String searchTerm) async {
    if (searchTerm.isEmpty) {
      _searchResults = [];
      return [];
    }

    _isLoading = true;
    notifyListeners();

    final results = _studentsData.skip(1).where((row) {
      return row.any(
        (cell) =>
            cell != null &&
            cell.toString().toLowerCase().contains(searchTerm.toLowerCase()),
      );
    }).toList();

    _searchResults = results;
    _isLoading = false;
    notifyListeners();
    return results;
  }
}
