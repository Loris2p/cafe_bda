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

/// L'écran principal de l'application.
///
/// Cette classe structure l'interface utilisateur et orchestre les interactions.
///
/// **Optimisation des Performances** :
/// Au lieu d'écouter tout le [SheetProvider] à la racine (ce qui causerait un rebuild total
/// à chaque changement), cet écran est découpé en composants plus petits ([_TableSelector],
/// [_DataDisplay], etc.) qui utilisent [Selector] ou [Consumer] pour n'écouter que
/// les parties de l'état qui les concernent.
class GoogleSheetsScreen extends StatelessWidget {
  const GoogleSheetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Benchmark : Début du chronométrage du temps de build
    final stopwatch = Stopwatch()..start();
    
    // On accède au provider sans écouter (listen: false) pour les appels de méthodes
    final provider = context.read<SheetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Café - BDA'),
        actions: [
          // Affiche le bouton déconnexion uniquement si authentifié
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
          // Affiche un spinner dans l'AppBar si une auth est en cours
          Selector<SheetProvider, bool>(
            selector: (_, p) => p.isAuthenticating,
            builder: (_, isAuthenticating, __) {
               return isAuthenticating 
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const _TableSelector(),
            const SizedBox(height: 10),
            const _AuthAndRefreshButtons(),
            const _StudentActionsSection(),
            const SizedBox(height: 10),
            const _SearchSection(),
            const SizedBox(height: 20),
            const _StatusAndErrorSection(),
            const SizedBox(height: 20),
            Expanded(child: Builder(
              builder: (context) {
                // Benchmark : Fin du chronométrage après le rendu de la frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  stopwatch.stop();
                  developer.log('GoogleSheetsScreen build time: ${stopwatch.elapsedMilliseconds}ms');
                });
                return const _DataDisplay();
              }
            )),
          ],
        ),
      ),
    );
  }
}

/// Widget affichant le sélecteur de table (Dropdown).
class _TableSelector extends StatelessWidget {
  const _TableSelector();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tableaux',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Rebuild uniquement si la table sélectionnée ou la liste change
            Consumer<SheetProvider>(
              builder: (context, provider, _) {
                return DropdownButton<String>(
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget contenant les boutons d'authentification et d'actualisation manuelle.
class _AuthAndRefreshButtons extends StatelessWidget {
  const _AuthAndRefreshButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bouton Auth : s'active/désactive selon l'état isAuthenticating
        Selector<SheetProvider, bool>(
          selector: (_, p) => p.isAuthenticating,
          builder: (context, isAuthenticating, _) {
            return ElevatedButton(
              onPressed: isAuthenticating
                  ? null
                  : () async {
                      final provider = context.read<SheetProvider>();
                      final error = await provider.authenticate();
                      if (context.mounted && error == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Authentification réussie!')));
                      }
                    },
              child: const Text('S\'authentifier'),
            );
          },
        ),
        // Bouton Refresh : s'active uniquement si auth et pas loading
        Selector<SheetProvider, (bool, bool)>(
          selector: (_, p) => (p.isLoading, p.isAuthenticated),
          builder: (context, data, _) {
            final isLoading = data.$1;
            final isAuthenticated = data.$2;
            return ElevatedButton(
              onPressed: (isLoading || !isAuthenticated)
                  ? null
                  : () => context.read<SheetProvider>().readTable(),
              child: const Text('Actualiser'),
            );
          },
        ),
      ],
    );
  }
}

/// Widget affichant les boutons d'actions spécifiques aux étudiants (Ajout, Crédit, Commande).
///
/// Ne s'affiche que si la table "Étudiants" est sélectionnée.
class _StudentActionsSection extends StatelessWidget {
  const _StudentActionsSection();

  // --- Helpers pour afficher les Dialogues ---

  void _showRegistrationForm(BuildContext context) {
    final provider = context.read<SheetProvider>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RegistrationForm(
          onSubmit: (formData) async {
            Navigator.of(context).pop();
            final error = await provider.handleRegistrationForm(formData);
            if (context.mounted) {
              if (error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inscription enregistrée avec succès!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
              }
            }
          },
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void _showCreditForm(BuildContext context) {
    final provider = context.read<SheetProvider>();
    // Validation pré-dialogue
    if (provider.studentsData.isEmpty || provider.studentsData.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord charger les données des étudiants')),
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
            if (context.mounted) {
              if (error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Crédit enregistré avec succès!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
              }
            }
          },
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void _showOrderForm(BuildContext context) async {
    final provider = context.read<SheetProvider>();
    if (provider.studentsData.isEmpty || provider.studentsData.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord charger les données des étudiants')),
      );
      return;
    }

    // Chargement dynamique des stocks avant d'ouvrir le formulaire
    final stockData = await provider.loadStockData();
    if (stockData.isEmpty || stockData.length < 2) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger les données du stock')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OrderForm(
          studentsData: provider.studentsData,
          stockData: stockData,
          onSubmit: (formData) async {
            Navigator.of(context).pop();
            final error = await provider.handleOrderSubmission(formData);
            if (context.mounted) {
              if (error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Commande enregistrée avec succès!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
              }
            }
          },
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Écoute uniquement le changement de table sélectionnée pour afficher/masquer ce bloc
    return Selector<SheetProvider, String>(
      selector: (_, p) => p.selectedTable,
      builder: (context, selectedTable, _) {
        if (selectedTable != AppConstants.studentsTable) return const SizedBox.shrink();

        return Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                height: 50,
                child: Consumer<SheetProvider>(
                  builder: (context, provider, _) {
                     final canAct = !provider.isLoading && provider.isAuthenticated;
                     // Vérifie s'il y a assez de données (au moins header + 1 ligne)
                     final hasData = provider.studentsData.length >= 2;
                     
                     return ListView(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: canAct ? () => _showRegistrationForm(context) : null,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Ajouter étudiant'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: (canAct && hasData) ? () => _showCreditForm(context) : null,
                            icon: const Icon(Icons.account_balance_wallet),
                            label: const Text('Ajouter crédit'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: (canAct && hasData) ? () => _showOrderForm(context) : null,
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text('Nouvelle commande'),
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget gérant la barre de recherche d'étudiants.
///
/// Dispose de son propre état local ([_SearchSectionState]) pour gérer le champ texte
/// sans provoquer de rebuilds inutiles du parent.
class _SearchSection extends StatefulWidget {
  const _SearchSection();

  @override
  State<_SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<_SearchSection> {
  final TextEditingController _searchController = TextEditingController();

  void _searchRow() async {
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un terme de recherche')),
      );
      return;
    }

    final provider = context.read<SheetProvider>();
    final results = await provider.searchStudent(searchTerm);

    if (!mounted) return;

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recherche d\'étudiants',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Nom, prénom ou numéro étudiant...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
    );
  }
}

/// Affiche les messages d'état (Erreurs, Chargement, Résultats de recherche).
class _StatusAndErrorSection extends StatelessWidget {
  const _StatusAndErrorSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<SheetProvider>(
      builder: (context, provider, _) {
        if (provider.errorMessage.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            color: Colors.red[50],
            child: Text(
              provider.errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (provider.isLoading) {
           return const Center(child: CircularProgressIndicator());
        }
        if (provider.searchResults.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${provider.searchResults.length} étudiant(s) trouvé(s)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Affiche le tableau de données principal.
class _DataDisplay extends StatelessWidget {
  const _DataDisplay();

  @override
  Widget build(BuildContext context) {
    // Écoute uniquement les changements dans sheetData
    return Selector<SheetProvider, List<List<dynamic>>>(
      selector: (_, p) => p.sheetData,
      builder: (context, sheetData, _) {
        return DataTableWidget(data: sheetData);
      },
    );
  }
}