import 'dart:async';
import 'package:flutter/foundation.dart';

class TableData {
  final String id;
  final List<String> rows;
  TableData({required this.id, required this.rows});
}

class TableManager extends ChangeNotifier {
  final Map<String, TableData> _cache = {};
  Timer? _debounceTimer;
  bool _isLoading = false;
  String? _error;
  TableData? _currentData;
  int _requestToken = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  TableData? get currentData => _currentData;

  /// Appeler lors du changement de tableau depuis l'UI.
  /// Debounce pour éviter les basculements rapides.
  void switchTable(String tableId, {Duration debounce = const Duration(milliseconds: 250)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => _loadTable(tableId));
  }

  Future<void> _loadTable(String tableId) async {
    _debounceTimer?.cancel();
    final int token = ++_requestToken;

    // si en cache -> retour immédiat
    if (_cache.containsKey(tableId)) {
      _currentData = _cache[tableId];
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // exécute fetch + parse en background pour ne pas bloquer l'UI
      final TableData data = await compute(_fetchAndParseTable, tableId);
      if (token != _requestToken) return; // résultat obsolète
      _cache[tableId] = data;
      _currentData = data;
      _error = null;
    } catch (e) {
      if (token != _requestToken) return;
      _error = e.toString();
      _currentData = null;
    } finally {
      if (token == _requestToken) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Forcer un refresh du tableau courant (supprime du cache puis reload)
  Future<void> refreshCurrent() async {
    final id = _currentData?.id;
    if (id == null) return;
    _cache.remove(id);
    await _loadTable(id);
  }

  // Remplacez cette méthode par votre fetch réel + parsing.
  static Future<TableData> _fetchAndParseTable(String tableId) async {
    // simulate network latency + parsing
    await Future.delayed(const Duration(milliseconds: 300));
    // ...real fetch & parse here...
    final rows = List<String>.generate(1000, (i) => 'Row $i of $tableId');
    return TableData(id: tableId, rows: rows);
  }
}
