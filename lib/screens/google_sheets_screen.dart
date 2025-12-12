import 'package:cafe_bda/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sheet_provider.dart';
import '../widgets/search_dialog.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/registration_form.dart';
import '../widgets/credit_form.dart';
import '../widgets/order_form.dart';

/// The main screen of the application.
///
/// This is a [StatelessWidget] that listens to the [SheetProvider] for state changes
/// and rebuilds the UI accordingly. All business logic and state management are

class GoogleSheetsScreen extends StatelessWidget {
  const GoogleSheetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the SheetProvider for state changes.
    // The UI will rebuild whenever notifyListeners() is called in the provider.
    final provider = context.watch<SheetProvider>();
    final searchController = TextEditingController();

    // Helper method to show the registration form dialog.
    void showRegistrationForm() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return RegistrationForm(
            onSubmit: (formData) async {
              Navigator.of(context).pop();
              final error = await provider.handleRegistrationForm(formData);
              if (error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Inscription enregistrée avec succès!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            },
            onCancel: () => Navigator.of(context).pop(),
          );
        },
      );
    }

    // Helper method to show the credit form dialog.
    void showCreditForm() {
      if (provider.studentsData.isEmpty || provider.studentsData.length < 2) {
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
            studentsData: provider.studentsData,
            onSubmit: (formData) async {
              Navigator.of(context).pop();
              final error = await provider.handleCreditSubmission(formData);
              if (error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Crédit enregistré avec succès!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            },
            onCancel: () => Navigator.of(context).pop(),
          );
        },
      );
    }
    
    // Helper method to show the order form dialog.
    void showOrderForm() async {
      if (provider.studentsData.isEmpty || provider.studentsData.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez d\'abord charger les données des étudiants'),
          ),
        );
        return;
      }

      final stockData = await provider.loadStockData();
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
            studentsData: provider.studentsData,
            stockData: stockData,
            onSubmit: (formData) async {
              Navigator.of(context).pop();
              final error = await provider.handleOrderSubmission(formData);
              if (error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Commande enregistrée avec succès!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            },
            onCancel: () => Navigator.of(context).pop(),
          );
        },
      );
    }

    // Helper method to handle the search logic.
    void searchRow() async {
      final searchTerm = searchController.text.trim();
      if (searchTerm.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez entrer un terme de recherche')),
        );
        return;
      }

      final results = await provider.searchStudent(searchTerm);
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aucun étudiant trouvé pour "$searchTerm"')),
        );
      } else {
        SearchDialog.showSearchResults(
          context,
          searchTerm: searchTerm,
          results: results,
          fullData: provider.studentsData,
          onRowSelected: (row) {
            SearchDialog.showRowDetails(
              context,
              row: row,
              columnNames: provider.studentsData.isNotEmpty
                  ? provider.studentsData[0]
                  : [],
            );
          },
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Café - BDA'),
        actions: [
          // Show logout button if authenticated
          if (provider.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await provider.logout();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Déconnexion réussie')));
              },
              tooltip: 'Déconnexion',
            ),
          // Show loading indicator during authentication
          if (provider.isAuthenticating)
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
            // UI Section: Table Selector
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tableaux',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: provider.selectedTable,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          provider.readTable(tableName: newValue);
                        }
                      },
                      items: provider.availableTables
                          .map<DropdownMenuItem<String>>((String value) {
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
            
            // UI Section: Action Buttons (Authenticate and Refresh)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: provider.isAuthenticating
                      ? null
                      : () async {
                          final error = await provider.authenticate();
                          if (error == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Authentification réussie!')));
                          }
                        },
                  child: const Text('S\'authentifier'),
                ),
                ElevatedButton(
                  onPressed: (provider.isLoading || !provider.isAuthenticated)
                      ? null
                      : provider.readTable,
                  child: const Text('Actualiser'),
                ),
              ],
            ),
            
            // UI Section: Student-specific actions
            if (provider.selectedTable == AppConstants.studentsTable) ...[
              const SizedBox(height: 10),
              Center(
                child: SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton.icon(
                          onPressed:
                              (provider.isLoading || !provider.isAuthenticated)
                                  ? null
                                  : showRegistrationForm,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Ajouter étudiant'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: (provider.isLoading ||
                                  !provider.isAuthenticated ||
                                  provider.studentsData.isEmpty ||
                                  provider.studentsData.length < 2)
                              ? null
                              : showCreditForm,
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('Ajouter crédit'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: (provider.isLoading ||
                                  !provider.isAuthenticated ||
                                  provider.studentsData.isEmpty ||
                                  provider.studentsData.length < 2)
                              ? null
                              : showOrderForm,
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
            
            // UI Section: Student Search
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recherche d\'étudiants',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: "Nom, prénom ou numéro étudiant...",
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onSubmitted: (_) => searchRow(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: searchRow,
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
            
            // UI Section: Error Message Display
            if (provider.errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red[50],
                child: Text(
                  provider.errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),
            
            // UI Section: Loading and Search Results
            if (provider.isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            if (provider.searchResults.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${provider.searchResults.length} étudiant(s) trouvé(s)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              
            // UI Section: Data Table
            Expanded(child: DataTableWidget(data: provider.sheetData)),
          ],
        ),
      ),
    );
  }
}
