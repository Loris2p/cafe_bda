import 'package:cafe_bda/providers/auth_provider.dart';
import 'package:cafe_bda/providers/cafe_data_provider.dart';
import 'package:cafe_bda/services/google_sheets_service.dart';
import 'package:cafe_bda/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_settings_dialog.dart';
import '../widgets/search_dialog.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/registration_form.dart';
import '../widgets/credit_form.dart';
import '../widgets/order_form.dart';
import 'dart:developer' as developer;

class GoogleSheetsScreen extends StatefulWidget {
  const GoogleSheetsScreen({super.key});

  @override
  State<GoogleSheetsScreen> createState() => _GoogleSheetsScreenState();
}

class _GoogleSheetsScreenState extends State<GoogleSheetsScreen> {
  
  @override
  void initState() {
    super.initState();
    // Au démarrage, on initialise l'auth qui va tenter l'auto-login.
    // Une fois connecté, on déclenchera le chargement des données.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Café - BDA', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [
          _RefreshButton(),
          _LogoutButton(),
          _AuthLoadingIndicator(),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (!authProvider.isAuthenticated) {
            // Afficher le spinner si on est en train de vérifier l'auto-login
            if (authProvider.isAuthenticating) {
               return const Center(child: CircularProgressIndicator());
            }
            return const _WelcomePage();
          }

          if (authProvider.errorMessage == 'PERMISSION_DENIED') {
            return const _AccessDeniedPage();
          }
          
          // Une fois authentifié, on s'assure que les données sont chargées
          // On utilise un Builder pour éviter de déclencher l'initData à chaque rebuild de AuthProvider
          return const MainScaffold();
        },
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final List<int> _history = [0];

  @override
  void initState() {
    super.initState();
    // Charger les données dès que l'écran authentifié est monté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CafeDataProvider>().initData();
    });
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _history.add(index);
    });
  }

  void _handlePop(bool didPop, dynamic result) {
    if (didPop) return;
    setState(() {
      _history.removeLast();
      _selectedIndex = _history.last;
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Accueil',
      ),
      const NavigationDestination(
        icon: Icon(Icons.shopping_cart_outlined),
        selectedIcon: Icon(Icons.shopping_cart),
        label: 'Commander',
      ),
      const NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet),
        label: 'Créditer',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Paramètres',
      ),
    ];

    final railDestinations = destinations.map((d) {
      return NavigationRailDestination(
        icon: d.icon,
        selectedIcon: d.selectedIcon,
        label: Text(d.label),
      );
    }).toList();

    final pages = [
      const _HomeTab(),
      const _OrderTab(),
      const _CreditTab(),
      const _SettingsTab(),
    ];

    return PopScope(
      canPop: _history.length <= 1,
      onPopInvokedWithResult: _handlePop,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // Desktop Layout
            return Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onItemTapped,
                    labelType: NavigationRailLabelType.all,
                    destinations: railDestinations,
                    // Use a trailing widget for logout/refresh on desktop rail? 
                    // For now, keep it simple, actions are in AppBar.
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: pages,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Mobile Layout
            return Scaffold(
              body: IndexedStack(
                index: _selectedIndex,
                children: pages,
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                destinations: destinations,
              ),
            );
          }
        },
      ),
    );
  }
}

// --- Tabs Content ---

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    // Benchmark : Log build start
    final stopwatch = Stopwatch()..start();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _HeaderControls(),
          const SizedBox(height: 16),
          const _UnifiedToolbar(),
          const SizedBox(height: 20),
          const _StatusAndErrorSection(),
          Expanded(child: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                stopwatch.stop();
                developer.log('HomeTab content build time: ${stopwatch.elapsedMilliseconds}ms');
              });
              return const _DataDisplay();
            }
          )),
        ],
      ),
    );
  }
}

class _OrderTab extends StatefulWidget {
  const _OrderTab();

  @override
  State<_OrderTab> createState() => _OrderTabState();
}

class _OrderTabState extends State<_OrderTab> {
  bool _isLoadingStock = false;
  List<List<dynamic>>? _stockData;

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  Future<void> _loadStock() async {
    setState(() {
      _isLoadingStock = true;
    });
    final provider = context.read<CafeDataProvider>();
    final stock = await provider.loadStockData();
    if (mounted) {
      setState(() {
        _stockData = stock;
        _isLoadingStock = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CafeDataProvider>();

    if (provider.studentsData.isEmpty || provider.studentsData.length < 2) {
      return const Center(child: Text("Veuillez d'abord charger les données étudiants (Accueil)"));
    }

    if (_isLoadingStock) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stockData == null || _stockData!.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Erreur de chargement du stock ou stock vide."),
            ElevatedButton(onPressed: _loadStock, child: const Text("Réessayer"))
          ],
        ),
      );
    }

    return OrderForm(
      studentsData: provider.studentsData,
      stockData: _stockData!,
      onSubmit: provider.handleOrderSubmission,
    );
  }
}

class _CreditTab extends StatelessWidget {
  const _CreditTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CafeDataProvider>();

    if (provider.studentsData.isEmpty || provider.studentsData.length < 2) {
       return const Center(child: Text("Veuillez d'abord charger les données étudiants (Accueil)"));
    }

    return CreditForm(
      studentsData: provider.studentsData,
      initialResponsableName: provider.responsableName,
      onSubmit: provider.handleCreditSubmission,
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CafeDataProvider>();
    final sheetData = provider.sheetData;

    if (sheetData.isEmpty || sheetData.first.isEmpty) {
      return const Center(child: Text("Chargez des données pour configurer les colonnes (Accueil)"));
    }

    final visibility = provider.columnVisibility[provider.selectedTable] ?? [];

    return AppSettingsWidget(
      columnNames: sheetData.first,
      visibility: visibility,
      responsableName: provider.responsableName,
      onVisibilityChanged: (index, isVisible) {
        provider.setColumnVisibility(index, isVisible);
      },
      onResponsableNameSaved: (name) {
        provider.saveResponsableName(name);
      },
    );
  }
}

// --- Boutons de lAppBar ---

class _RefreshButton extends StatelessWidget {
  const _RefreshButton();

  @override
  Widget build(BuildContext context) {
    return Selector2<CafeDataProvider, AuthProvider, (bool, bool)>(
      selector: (_, data, auth) => (data.isLoading, auth.isAuthenticated),
      builder: (context, data, _) {
        final isLoading = data.$1;
        final isAuthenticated = data.$2;
        
        if (!isAuthenticated) return const SizedBox.shrink();
        
        return IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualiser',
          onPressed: isLoading
              ? null
              : () => context.read<CafeDataProvider>().readTable(forceRefresh: true),
        );
      },
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, bool>(
      selector: (_, p) => p.isAuthenticated,
      builder: (_, isAuthenticated, __) {
        if (!isAuthenticated) return const SizedBox.shrink();
        return IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            // On vide les données d'abord
            context.read<CafeDataProvider>().clearData();
            // Puis on déconnecte
            await context.read<AuthProvider>().logout();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Déconnexion réussie')));
            }
          },
          tooltip: 'Déconnexion',
        );
      },
    );
  }
}

class _AuthLoadingIndicator extends StatelessWidget {
  const _AuthLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, bool>(
      selector: (_, p) => p.isAuthenticating,
      builder: (_, isAuthenticating, __) {
         return isAuthenticating 
          ? const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          : const SizedBox.shrink();
      },
    );
  }
}

// --- Pages d'état ---

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage();

  Future<void> _launchEmailToRequestAccess(BuildContext context) async {
    final email = Uri(
      scheme: 'mailto',
      path: 'bdapaucytech@gmail.com',
      query: 'subject=Demande d\'accès au tableur du Café BDA',
    );

    try {
      if (await canLaunchUrl(email)) {
        await launchUrl(email);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir l\'application de messagerie.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetsService = context.read<GoogleSheetsService>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 24),
            Text(
              'Accès non autorisé',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Votre compte Google (${sheetsService.currentUser?.email}) n\'a pas les permissions pour accéder à la feuille de calcul.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Veuillez contacter le support pour obtenir l\'accès :',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _launchEmailToRequestAccess(context),
              icon: const Icon(Icons.email),
              label: const Text('Contacter bdapaucytech@gmail.com'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
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
            Selector<AuthProvider, bool>(
              selector: (_, p) => p.isAuthenticating,
              builder: (context, isAuthenticating, _) {
                if (isAuthenticating) {
                  return const CircularProgressIndicator();
                }
                return ElevatedButton.icon(
                  onPressed: () async {
                    final provider = context.read<AuthProvider>();
                    final error = await provider.authenticate();
                    if (context.mounted && error == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Authentification réussie!')));
                      // Le chargement des données se fera via le changement d'état dans le parent
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
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.errorMessage.isNotEmpty && auth.errorMessage != 'PERMISSION_DENIED') {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(auth.errorMessage, style: const TextStyle(color: Colors.red)),
                  );
                }
                return const SizedBox.shrink();
              }
            )
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
            Consumer<CafeDataProvider>(
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

class _UnifiedToolbar extends StatelessWidget {
  const _UnifiedToolbar();

  @override
  Widget build(BuildContext context) {
    return Selector<CafeDataProvider, String>(
      selector: (_, p) => p.selectedTable,
      builder: (context, selectedTable, _) {
        if (selectedTable != AppConstants.studentsTable) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;

            if (isWide) {
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _SearchSection()),
                  SizedBox(width: 16),
                  _ActionButtonsGroup(),
                ],
              );
            } else {
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SearchSection(),
                  SizedBox(height: 12),
                  Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _ActionButtonsGroup(),
                    ),
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

class _ActionButtonsGroup extends StatelessWidget {
  const _ActionButtonsGroup();

  void _showRegistrationForm(BuildContext context) {
    final provider = context.read<CafeDataProvider>();
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
    return Consumer<CafeDataProvider>(
      builder: (context, provider, _) {
         final canAct = !provider.isLoading; // Auth checked by parent
         
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
              label: const Text('Nouvel Étudiant'),
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

    final provider = context.read<CafeDataProvider>();
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
    return Consumer<CafeDataProvider>(
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
        return const SizedBox.shrink();
      },
    );
  }
}

class _DataDisplay extends StatelessWidget {
  const _DataDisplay();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CafeDataProvider>();
    return Selector<CafeDataProvider, (List<List<dynamic>>, String, int?, bool, Map<String, List<bool>>)>(
      selector: (_, p) => (p.sheetData, p.selectedTable, p.sortColumnIndex, p.sortAscending, p.columnVisibility),
      builder: (context, data, _) {
        final sheetData = data.$1;
        final selectedTable = data.$2;
        final sortColumnIndex = data.$3;
        final sortAscending = data.$4;
        final columnVisibility = data.$5;

        if (sheetData.isEmpty) {
          return const Center(child: Text("Pas de données à afficher."));
        }

        final visibilityList = columnVisibility[selectedTable] ?? [];
        
        final List<int> visibleOriginalIndices = [];
        if (visibilityList.isNotEmpty) {
          for (int i = 0; i < visibilityList.length; i++) {
            if (visibilityList[i]) {
              visibleOriginalIndices.add(i);
            }
          }
        } else if (sheetData.isNotEmpty) {
          visibleOriginalIndices.addAll(List.generate(sheetData.first.length, (i) => i));
        }

        if (visibleOriginalIndices.isEmpty) {
          return const Center(child: Text("Toutes les colonnes sont masquées."));
        }

        final visibleData = sheetData.map((row) {
          return visibleOriginalIndices.map((originalIndex) => originalIndex < row.length ? row[originalIndex] : null).toList();
        }).toList();

        int? visibleSortColumnIndex;
        if (sortColumnIndex != null) {
          visibleSortColumnIndex = visibleOriginalIndices.indexOf(sortColumnIndex);
          if (visibleSortColumnIndex == -1) {
            visibleSortColumnIndex = null;
          }
        }

        final bool isStockTable = selectedTable == AppConstants.stockTable;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DataTableWidget(
              data: visibleData,
              sortColumnIndex: visibleSortColumnIndex,
              sortAscending: sortAscending,
              onSort: (visibleIndex) {
                final originalIndex = visibleOriginalIndices[visibleIndex];
                provider.sortData(originalIndex);
              },
              onCellUpdate: isStockTable
                  ? (rowIndex, visibleIndex, newValue) async {
                      final originalIndex = visibleOriginalIndices[visibleIndex];
                      final error = await provider.updateCellValue(rowIndex, originalIndex, newValue);
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
