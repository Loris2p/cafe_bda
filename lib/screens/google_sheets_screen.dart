import 'package:cafe_bda/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sheet_provider.dart';
import '../widgets/search_dialog.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/registration_form.dart';
import '../widgets/credit_form.dart';
import '../widgets/order_form.dart';
import 'dart:developer' as developer;

class GoogleSheetsScreen extends StatelessWidget {
  const GoogleSheetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Benchmark : Log build start
    final stopwatch = Stopwatch()..start();
    
    // On accède au provider sans écouter (listen: false) pour les appels de méthodes
    final provider = context.read<SheetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Café - BDA', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Refresh Button (moved to AppBar)
          Selector<SheetProvider, (bool, bool)>(
            selector: (_, p) => (p.isLoading, p.isAuthenticated),
            builder: (context, data, _) {
              final isLoading = data.$1;
              final isAuthenticated = data.$2;
              if (!isAuthenticated) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser',
                onPressed: isLoading
                    ? null
                    : () => context.read<SheetProvider>().readTable(),
              );
            },
          ),
          // Logout Button
          Selector<SheetProvider, bool>(
            selector: (_, p) => p.isAuthenticated,
            builder: (_, isAuthenticated, __) {
              if (!isAuthenticated) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await provider.logout();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Déconnexion réussie')));
                  }
                },
                tooltip: 'Déconnexion',
              );
            },
          ),
          Selector<SheetProvider, bool>(
            selector: (_, p) => p.isAuthenticating,
            builder: (_, isAuthenticating, __) {
               return isAuthenticating 
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  )
                : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Selector<SheetProvider, bool>(
        selector: (_, p) => p.isAuthenticated,
        builder: (context, isAuthenticated, _) {
          if (!isAuthenticated) {
            return const _WelcomePage();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Top Section: Table Selector
                const _HeaderControls(),
                const SizedBox(height: 16),
                
                // Unified Toolbar (Search + Actions)
                const _UnifiedToolbar(),
                const SizedBox(height: 20),
                
                // Status Messages (Errors, Loading)
                const _StatusAndErrorSection(),
                
                // Data Table
                Expanded(child: Builder(
                  builder: (context) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      stopwatch.stop();
                      developer.log('GoogleSheetsScreen build time: ${stopwatch.elapsedMilliseconds}ms');
                    });
                    return const _DataDisplay();
                  }
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.coffee, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Bienvenue sur Gestion Café',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Connectez-vous pour accéder à la base de données.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            Selector<SheetProvider, bool>(
              selector: (_, p) => p.isAuthenticating,
              builder: (context, isAuthenticating, _) {
                if (isAuthenticating) {
                  return const CircularProgressIndicator();
                }
                return ElevatedButton.icon(
                  onPressed: () async {
                    final provider = context.read<SheetProvider>();
                    final error = await provider.authenticate();
                    if (context.mounted && error == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Authentification réussie!')));
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Se connecter avec Google'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderControls extends StatelessWidget {
  const _HeaderControls();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tableau Actif', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Consumer<SheetProvider>(
              builder: (context, provider, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: provider.selectedTable,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          provider.readTable(tableName: newValue);
                        }
                      },
                      items: provider.availableTables
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre d'outils unifiée combinant Recherche et Actions.
/// S'adapte à la largeur de l'écran.
class _UnifiedToolbar extends StatelessWidget {
  const _UnifiedToolbar();

  @override
  Widget build(BuildContext context) {
    return Selector<SheetProvider, String>(
      selector: (_, p) => p.selectedTable,
      builder: (context, selectedTable, _) {
        if (selectedTable != AppConstants.studentsTable) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            // Seuil desktop/mobile (800px)
            final isWide = constraints.maxWidth > 800;

            if (isWide) {
              // Mode Desktop : Recherche à gauche, Actions à droite sur la même ligne
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _SearchSection()),
                  SizedBox(width: 16),
                  _ActionButtonsGroup(),
                ],
              );
            } else {
              // Mode Mobile : Recherche en haut, Actions en bas (scrollable horizontalement)
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SearchSection(),
                  SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _ActionButtonsGroup(),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }
}

/// Groupe de boutons d'action (Étudiant, Crédit, Commande)
class _ActionButtonsGroup extends StatelessWidget {
  const _ActionButtonsGroup();

  void _showRegistrationForm(BuildContext context) {
    final provider = context.read<SheetProvider>();
    showDialog(
      context: context,
      builder: (BuildContext context) => RegistrationForm(
        onSubmit: (formData) async {
          Navigator.of(context).pop();
          final error = await provider.handleRegistrationForm(formData);
          if (context.mounted) _showSnack(context, error, 'Inscription enregistrée!');
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showCreditForm(BuildContext context) {
    final provider = context.read<SheetProvider>();
    if (!_checkDataLoaded(context, provider)) return;

    showDialog(
      context: context,
      builder: (BuildContext context) => CreditForm(
        studentsData: provider.studentsData,
        onSubmit: (formData) async {
          Navigator.of(context).pop();
          final error = await provider.handleCreditSubmission(formData);
          if (context.mounted) _showSnack(context, error, 'Crédit enregistré!');
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showOrderForm(BuildContext context) async {
    final provider = context.read<SheetProvider>();
    if (!_checkDataLoaded(context, provider)) return;

    final stockData = await provider.loadStockData();
    if (stockData.isEmpty || stockData.length < 2) {
      if (context.mounted) _showSnack(context, 'Erreur stock', null);
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) => OrderForm(
        studentsData: provider.studentsData,
        stockData: stockData,
        onSubmit: (formData) async {
          Navigator.of(context).pop();
          final error = await provider.handleOrderSubmission(formData);
          if (context.mounted) _showSnack(context, error, 'Commande enregistrée!');
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  bool _checkDataLoaded(BuildContext context, SheetProvider provider) {
    if (provider.studentsData.isEmpty || provider.studentsData.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord charger les données des étudiants')),
      );
      return false;
    }
    return true;
  }

  void _showSnack(BuildContext context, String? error, String? successMsg) {
    if (error == null) {
      if (successMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg)));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SheetProvider>(
      builder: (context, provider, _) {
         final canAct = !provider.isLoading && provider.isAuthenticated;
         final hasData = provider.studentsData.length >= 2;
         
         // Style commun pour les boutons d'action (Couleur Tertiaire)
         final buttonStyle = ElevatedButton.styleFrom(
           backgroundColor: Theme.of(context).colorScheme.tertiary,
           foregroundColor: Theme.of(context).colorScheme.onTertiary,
         );

         return Row(
          children: [
            ElevatedButton.icon(
              style: buttonStyle,
              onPressed: canAct ? () => _showRegistrationForm(context) : null,
              icon: const Icon(Icons.person_add),
              label: const Text('Étudiant'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: buttonStyle,
              onPressed: (canAct && hasData) ? () => _showCreditForm(context) : null,
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Crédit'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: buttonStyle,
              onPressed: (canAct && hasData) ? () => _showOrderForm(context) : null,
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Commande'),
            ),
          ],
        );
      }
    );
  }
}

class _SearchSection extends StatefulWidget {
  const _SearchSection();

  @override
  State<_SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<_SearchSection> {
  final TextEditingController _searchController = TextEditingController();

  void _searchRow() async {
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty) return;

    final provider = context.read<SheetProvider>();
    final results = await provider.searchStudent(searchTerm);

    if (!mounted) return;

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aucun résultat pour "$searchTerm"')),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Rechercher (Nom, Prénom, N°)...",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: _searchRow,
        ),
      ),
      onSubmitted: (_) => _searchRow(),
    );
  }
}

class _StatusAndErrorSection extends StatelessWidget {
  const _StatusAndErrorSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<SheetProvider>(
      builder: (context, provider, _) {
        if (provider.errorMessage.isNotEmpty) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.errorMessage,
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          );
        }
        if (provider.isLoading) {
           return const Padding(
             padding: EdgeInsets.all(20.0),
             child: Center(child: CircularProgressIndicator()),
           );
        }
        // Compteur de résultats supprimé ici (déplacé dans la popup)
        return const SizedBox.shrink();
      },
    );
  }
}

class _DataDisplay extends StatelessWidget {
  const _DataDisplay();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SheetProvider>();
    return Selector<SheetProvider, (List<List<dynamic>>, String, int?, bool)>(
      selector: (_, p) => (p.sheetData, p.selectedTable, p.sortColumnIndex, p.sortAscending),
      builder: (context, data, _) {
        final sheetData = data.$1;
        final selectedTable = data.$2;
        final sortColumnIndex = data.$3;
        final sortAscending = data.$4;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DataTableWidget(
              data: sheetData,
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              onSort: (columnIndex) => provider.sortData(columnIndex),
              onCellUpdate: selectedTable == AppConstants.stockTable
                  ? (rowIndex, colIndex, newValue) async {
                      final error = await provider.updateCellValue(rowIndex, colIndex, newValue);
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }
}