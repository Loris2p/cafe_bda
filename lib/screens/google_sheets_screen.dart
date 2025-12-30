import 'package:cafe_bda/providers/auth_provider.dart';
import 'package:cafe_bda/providers/cafe_data_provider.dart';
import 'package:cafe_bda/services/google_sheets_service.dart';
import 'package:cafe_bda/services/version_check_service.dart'; // Ajout
import 'package:cafe_bda/widgets/update_dialog.dart'; // Ajout
import 'package:cafe_bda/widgets/payment_dialog.dart'; // Ajout
import 'package:cafe_bda/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  bool _versionChecked = false;
  
  @override
  void initState() {
    super.initState();
    // Au démarrage, on initialise l'auth qui va tenter l'auto-login.
    // Une fois connecté, on déclenchera le chargement des données.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
    });
  }

  Future<void> _checkVersion(BuildContext context) async {
    if (!mounted) return;
    
    final sheetsService = context.read<GoogleSheetsService>();
    final versionService = VersionCheckService(sheetsService);
    
    final result = await versionService.checkVersion();
    
    if (!mounted) return;

    if (result.status == VersionStatus.updateRequired) {
      UpdateDialog.show(
        context,
        isMandatory: true,
        latestVersion: result.latestVersion ?? '?',
        currentVersion: result.localVersion ?? '?',
        downloadUrl: result.downloadUrl,
      );
    } else if (result.status == VersionStatus.updateAvailable) {
      UpdateDialog.show(
        context,
        isMandatory: false,
        latestVersion: result.latestVersion ?? '?',
        currentVersion: result.localVersion ?? '?',
        downloadUrl: result.downloadUrl,
      );
    }
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
          if (authProvider.errorMessage == 'PERMISSION_DENIED') {
            return const _AccessDeniedPage();
          }

          if (!authProvider.isAuthenticated) {
            // Afficher le spinner si on est en train de vérifier l'auto-login
            if (authProvider.isAuthenticating) {
               return const Center(child: CircularProgressIndicator());
            }
            return const _WelcomePage();
          }

          // Déclencher la vérification de version une seule fois après l'authentification
          if (!_versionChecked) {
            _versionChecked = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _checkVersion(context));
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
  final GlobalKey<_HomeTabState> _homeTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Charger les données dès que l'écran authentifié est monté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CafeDataProvider>().initData();
    });
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      if (index == 0) {
        _homeTabKey.currentState?.resetToDashboard();
      }
      return;
    }
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
        icon: Icon(Icons.qr_code_2_outlined),
        selectedIcon: Icon(Icons.qr_code_2),
        label: 'Lydia',
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
      _HomeTab(key: _homeTabKey),
      const _OrderTab(),
      const _CreditTab(),
      const _PaymentTab(),
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

class _HomeTab extends StatefulWidget {
  const _HomeTab({super.key});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _showDashboard = true;

  void _openTable(String tableName) {
    context.read<CafeDataProvider>().readTable(tableName: tableName);
    setState(() {
      _showDashboard = false;
    });
  }

  void resetToDashboard() {
    if (!_showDashboard) {
      setState(() {
        _showDashboard = true;
      });
    }
  }

  void _backToDashboard() {
    setState(() {
      _showDashboard = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Benchmark : Log build start
    final stopwatch = Stopwatch()..start();

    if (_showDashboard) {
      return _DashboardView(onTableSelected: _openTable);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _backToDashboard();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _backToDashboard,
                  tooltip: "Retour à l'accueil",
                ),
                Expanded(child: const _HeaderControls()),
              ],
            ),
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
      ),
    );
  }
}

class _DashboardView extends StatefulWidget {
  final Function(String) onTableSelected;

  const _DashboardView({required this.onTableSelected});

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty) return;

    // Masquer le clavier
    FocusScope.of(context).unfocus();

    final provider = context.read<CafeDataProvider>();
    
    // Si les données étudiants ne sont pas encore chargées, on tente de les charger
    if (provider.studentsData.isEmpty) {
      await provider.readTable(tableName: AppConstants.studentsTable);
    }

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
            visibleColumns: provider.columnVisibility[AppConstants.studentsTable],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/icon/logo-bda.png',
                    height: 140,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.coffee, size: 100, color: Colors.brown),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Bienvenue au Café BDA',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // --- Barre de recherche ---
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _performSearch(),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: "Rechercher un étudiant...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: Consumer<CafeDataProvider>(
                        builder: (context, provider, _) {
                          if (provider.isLoading && provider.selectedTable == AppConstants.studentsTable) {
                             return const Padding(
                               padding: EdgeInsets.all(12.0),
                               child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                             );
                          }
                          return IconButton(
                            icon: Icon(Icons.arrow_forward, color: Theme.of(context).primaryColor),
                            onPressed: _performSearch,
                          );
                        }
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
                // --------------------------

                const SizedBox(height: 48),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        _DashboardCard(
                          title: 'Étudiants',
                          subtitle: 'Soldes & Inscriptions',
                          icon: Icons.people_alt_rounded,
                          color: Colors.blue.shade700,
                          onTap: () => widget.onTableSelected(AppConstants.studentsTable),
                          width: isWide ? 300 : double.infinity,
                        ),
                        _DashboardCard(
                          title: 'Stocks',
                          subtitle: 'Inventaire produits',
                          icon: Icons.inventory_2_rounded,
                          color: Colors.orange.shade800,
                          onTap: () => widget.onTableSelected(AppConstants.stockTable),
                          width: isWide ? 300 : double.infinity,
                        ),
                        _DashboardCard(
                          title: 'Historique Paiements',
                          subtitle: 'Transactions récentes',
                          icon: Icons.payments_rounded,
                          color: Colors.green.shade700,
                          onTap: () => widget.onTableSelected(AppConstants.paymentsTable),
                          width: isWide ? 300 : double.infinity,
                        ),
                        _DashboardCard(
                          title: 'Historique Crédits',
                          subtitle: 'Rechargements effectués',
                          icon: Icons.history_edu_rounded,
                          color: Colors.purple.shade700,
                          onTap: () => widget.onTableSelected(AppConstants.creditsTable),
                          width: isWide ? 300 : double.infinity,
                        ),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double width;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
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

class _PaymentTab extends StatelessWidget {
  const _PaymentTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CafeDataProvider>();
    final configs = provider.paymentConfigs;

    if (configs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text("Aucune information de paiement configurée."),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: PaymentInfoWidget(paymentConfigs: configs), // Reusing PaymentInfoWidget widget which handles layouts well
        ),
      ),
    );
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late Future<void> _headersFuture;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CafeDataProvider>();
    // Start fetching headers when the tab is initialized if not already present
    if (provider.tableHeaders.isEmpty) {
      _headersFuture = provider.fetchAllTableHeaders();
    } else {
      _headersFuture = Future.value();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _headersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // We can consume provider even if fetch had an error (it handles its own errors gracefully mostly)
        final provider = context.watch<CafeDataProvider>();

        return FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, packageSnapshot) {
            final String version = packageSnapshot.hasData 
                ? packageSnapshot.data!.version 
                : 'Chargement...';

            return AppSettingsWidget(
              allHeaders: provider.tableHeaders,
              allVisibility: provider.columnVisibility,
              responsableName: provider.responsableName,
              appVersion: version,
              onVisibilityChanged: (tableName, index, isVisible) {
                provider.setColumnVisibility(index, isVisible, tableName: tableName);
              },
              onResponsableNameSaved: (name) {
                provider.saveResponsableName(name);
              },
            );
          }
        );
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
    final authProvider = context.read<AuthProvider>();
    final deniedEmail = authProvider.deniedEmail ?? 'Compte inconnu';

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
              'Votre compte Google ($deniedEmail) n\'a pas les permissions pour accéder à la feuille de calcul.',
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
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter / Changer de compte'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
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
            Image.asset(
              'assets/icon/logo-bda.png',
              height: 120,
              errorBuilder: (context, error, stackTrace) => 
                  Icon(Icons.coffee, size: 80, color: Theme.of(context).colorScheme.primary),
            ),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tableau Actif',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<CafeDataProvider>(
              builder: (context, provider, _) {
                // Défense : s'assurer que la valeur sélectionnée existe dans la liste
                final String dropdownValue = provider.availableTables.contains(provider.selectedTable)
                    ? provider.selectedTable
                    : provider.availableTables.isNotEmpty 
                        ? provider.availableTables.first 
                        : '';

                if (dropdownValue.isEmpty) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: dropdownValue,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: provider.isLoading 
                          ? null // Désactiver visuellement pendant le chargement pour éviter les conflits
                          : (String? newValue) {
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
            visibleColumns: provider.columnVisibility[AppConstants.studentsTable],
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
