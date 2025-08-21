import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../services/google_sheets_service.dart';
import '../widgets/search_dialog.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/registration_form.dart';
import '../widgets/credit_form.dart';
import '../widgets/order_form.dart';

class GoogleSheetsScreen extends StatefulWidget {
  const GoogleSheetsScreen({super.key});

  @override
  State<GoogleSheetsScreen> createState() => _GoogleSheetsScreenState();
}

class _GoogleSheetsScreenState extends State<GoogleSheetsScreen> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  final TextEditingController _searchController = TextEditingController();

  List<List<dynamic>> sheetData = [];
  List<List<dynamic>> searchResults = [];
  List<List<dynamic>> studentsData = []; // Données des étudiants séparées
  bool isLoading = false;
  bool isAuthenticating = false;
  String errorMessage = '';
  String selectedTable = 'Étudiants'; // Tableau par défaut

  // Noms des tableaux disponibles
  final List<String> availableTables = [
    'Étudiants',
    'Credits',
    'Paiements',
    'Stocks',
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    setState(() {
      errorMessage = _sheetsService.checkEnvVariables();
    });

    if (errorMessage.isEmpty) {
      setState(() => isAuthenticating = true);
      final autoAuthSuccess = await _sheetsService.tryAutoAuthenticate();
      setState(() => isAuthenticating = false);

      if (autoAuthSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentification automatique réussie!'),
          ),
        );
        // Charger les données du tableau par défaut
        await _readTable();
        // Charger aussi les données des étudiants pour la recherche
        await _loadStudentsData();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Charger les données des étudiants pour la recherche
  Future<void> _loadStudentsData() async {
    try {
      final data = await _sheetsService.readTable('Étudiants');
      setState(() {
        studentsData = data ?? [];
      });
    } catch (e) {
      print('Erreur chargement données étudiants: $e');
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      isAuthenticating = true;
      errorMessage = '';
    });

    try {
      // Vérifier la connexion réseau avant de tenter l'authentification
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('Pas de connexion Internet');
      }

      final error = await _sheetsService.authenticate();
      setState(() {
        isAuthenticating = false;
        if (error != null) errorMessage = error;
      });

      if (error == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentification réussie!')),
        );
        await _readTable();
        await _loadStudentsData();
      }
    } on SocketException catch (e) {
      setState(() {
        isAuthenticating = false;
        errorMessage =
            'Erreur réseau: Veuillez vérifier votre connexion Internet.';
      });
      print('Erreur SocketException: $e');
    } catch (e) {
      setState(() {
        isAuthenticating = false;
        errorMessage = 'Erreur lors de l\'authentification: ${e.toString()}';
      });
      print('Erreur générale: $e');
    }
  }

  Future<void> _logout() async {
    await _sheetsService.logout();
    setState(() {
      sheetData = [];
      searchResults = [];
      studentsData = [];
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Déconnexion réussie')));
    }
  }

  Future<void> _readTable() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await _sheetsService.readTable(selectedTable);
      setState(() {
        sheetData = data ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur de lecture: ${e.toString()}';
      });

      if (e.toString().contains('authentication') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        await _logout();
      }
    }
  }

  void _showRegistrationForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RegistrationForm(
          onSubmit: _handleFormSubmission,
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void _showCreditForm() {
    if (studentsData.isEmpty || studentsData.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord charger les données des étudiants'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreditForm(
          studentsData:
              studentsData, // Utiliser studentsData au lieu de sheetData
          onSubmit: _handleCreditSubmission,
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void _showOrderForm() {
    if (studentsData.isEmpty || studentsData.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord charger les données des étudiants'),
        ),
      );
      return;
    }

    // Charger les données du stock
    _loadStockData().then((stockData) {
      if (stockData.isEmpty || stockData.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de charger les données du stock'),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return OrderForm(
            studentsData:
                studentsData, // Utiliser studentsData au lieu de sheetData
            stockData: stockData,
            onSubmit: _handleOrderSubmission,
            onCancel: () => Navigator.of(context).pop(),
          );
        },
      );
    });
  }

  // Méthode pour charger les données du stock
  Future<List<List<dynamic>>> _loadStockData() async {
    try {
      return await _sheetsService.readTable('Stocks') ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _handleFormSubmission(Map<String, dynamic> formData) async {
    Navigator.of(context).pop(); // Fermer le dialogue

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Obtenir le prochain numéro de ligne dans le tableau
      final nextRow = await _sheetsService.getNextRowInNamedRange('Étudiants');

      // Utiliser la nouvelle méthode avec formules adaptées
      await _sheetsService.addStudentWithFormulas(formData, nextRow);

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscription enregistrée avec succès!')),
      );

      // Recharger les données
      await _readTable();
      await _loadStudentsData(); // Recharger aussi les étudiants
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur lors de l\'enregistrement: ${e.toString()}';
      });
    }
  }

  Future<void> _handleCreditSubmission(Map<String, dynamic> formData) async {
    Navigator.of(context).pop(); // Fermer le dialogue

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await _sheetsService.addCreditRecord(formData);

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crédit enregistré avec succès!')),
      );

      // Recharger les données si on est dans le tableau Credits
      if (selectedTable == 'Credits') {
        await _readTable();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur lors de l\'enregistrement: ${e.toString()}';
      });
    }
  }

  Future<void> _handleOrderSubmission(Map<String, dynamic> formData) async {
    Navigator.of(context).pop(); // Fermer le dialogue

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await _sheetsService.addOrderRecord(formData);

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande enregistrée avec succès!')),
      );

      // Recharger les données si on est dans le tableau Paiements
      if (selectedTable == 'Paiements') {
        await _readTable();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur lors de l\'enregistrement: ${e.toString()}';
      });
    }
  }

  Future<void> _searchRow() async {
    final searchText = _searchController.text.trim();

    if (searchText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un terme de recherche')),
      );
      return;
    }

    if (studentsData.isEmpty || studentsData.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucune donnée d\'étudiants à rechercher. Veuillez d\'abord actualiser.',
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    // Rechercher uniquement dans les données des étudiants
    final results = studentsData.skip(1).where((row) {
      return row.any(
        (cell) =>
            cell != null &&
            cell.toString().toLowerCase().contains(searchText.toLowerCase()),
      );
    }).toList();

    setState(() {
      searchResults = results;
      isLoading = false;
    });

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aucun étudiant trouvé pour "$searchText"')),
      );
    } else {
      SearchDialog.showSearchResults(
        context,
        searchTerm: searchText,
        results: results,
        fullData: studentsData, // Utiliser studentsData pour les détails
        onRowSelected: (row) {
          SearchDialog.showRowDetails(
            context,
            row: row,
            columnNames: studentsData.isNotEmpty ? studentsData[0] : [],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Café - Google Sheets'),
        actions: [
          if (_sheetsService.sheetsApi != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Déconnexion',
            ),
          if (isAuthenticating)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Sélecteur de tableau
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tableaux',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedTable,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedTable = newValue;
                          });
                          _readTable();
                        }
                      },
                      items: availableTables.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Première ligne de boutons (auth/refresh)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isAuthenticating ? null : _authenticate,
                  child: const Text('S\'authentifier'),
                ),
                ElevatedButton(
                  onPressed: (isLoading || _sheetsService.sheetsApi == null)
                      ? null
                      : _readTable,
                  child: const Text('Actualiser'),
                ),
              ],
            ),

            // Deuxième ligne de boutons - uniquement pour le tableau Étudiants
            if (selectedTable == 'Étudiants') ...[
              const SizedBox(height: 10),
              // Conteneur pour centrer la liste horizontale
              Center(
                child: SizedBox(
                  height: 50, // Hauteur fixe pour la ligne de boutons
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    padding:
                        EdgeInsets.zero, // Suppression du padding par défaut
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton.icon(
                          onPressed:
                              (isLoading || _sheetsService.sheetsApi == null)
                              ? null
                              : _showRegistrationForm,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Ajouter étudiant'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton.icon(
                          onPressed:
                              (isLoading ||
                                  _sheetsService.sheetsApi == null ||
                                  studentsData.isEmpty ||
                                  studentsData.length < 2)
                              ? null
                              : _showCreditForm,
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('Ajouter crédit'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton.icon(
                          onPressed:
                              (isLoading ||
                                  _sheetsService.sheetsApi == null ||
                                  studentsData.isEmpty ||
                                  studentsData.length < 2)
                              ? null
                              : _showOrderForm,
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Nouvelle commande'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Champ de recherche (toujours affiché)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recherche d\'étudiants',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: "Nom, prénom ou numéro étudiant...",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            onSubmitted: (_) => _searchRow(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _searchRow,
                          icon: const Icon(Icons.search),
                          label: const Text("Chercher"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red[50],
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            if (searchResults.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${searchResults.length} étudiant(s) trouvé(s)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(child: DataTableWidget(data: sheetData)),
          ],
        ),
      ),
    );
  }
}
