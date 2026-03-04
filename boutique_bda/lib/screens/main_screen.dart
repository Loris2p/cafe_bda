import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'home_screen.dart';
import 'sale_screen.dart';
import 'top_up_screen.dart';
import 'student_list_screen.dart';
import 'payment_info_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'product_management_screen.dart';
import 'payment_management_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AdminProvider>().isAdmin;
    final tabProvider = context.watch<TabProvider>();
    final selectedIndex = tabProvider.selectedIndex;
    
    final List<_TabItem> tabs = isAdmin ? _getAdminTabs() : _getUserTabs();

    // Sécurité si on change de mode
    int effectiveIndex = selectedIndex;
    if (effectiveIndex >= tabs.length) {
      effectiveIndex = 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          body: Row(
            children: [
              if (isDesktop)
                NavigationRail(
                  selectedIndex: effectiveIndex,
                  onDestinationSelected: (index) => tabProvider.setTab(index),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Theme.of(context).cardColor,
                  indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  selectedLabelTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
                  selectedIconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
                  unselectedIconTheme: const IconThemeData(color: Colors.grey),
                  destinations: tabs.map((t) => NavigationRailDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon),
                    label: Text(t.label),
                  )).toList(),
                  trailing: isAdmin ? Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: IconButton(
                          icon: const Icon(Icons.exit_to_app, color: Colors.orange),
                          tooltip: 'Quitter le mode Admin',
                          onPressed: () {
                            context.read<AdminProvider>().setAdmin(false);
                          },
                        ),
                      ),
                    ),
                  ) : null,
                ),
              if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: IndexedStack(
                  index: effectiveIndex,
                  children: tabs.map((t) => t.page).toList(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: !isDesktop ? NavigationBar(
            selectedIndex: effectiveIndex,
            onDestinationSelected: (index) => tabProvider.setTab(index),
            destinations: tabs.map((t) => NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            )).toList(),
          ) : null,
        );
      },
    );
  }

  List<_TabItem> _getUserTabs() {
    return [
      _TabItem(
        label: 'Accueil',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        page: const HomeScreen(),
      ),
      _TabItem(
        label: 'Vendre',
        icon: Icons.shopping_bag_outlined,
        selectedIcon: Icons.shopping_bag,
        page: const SaleScreen(),
      ),
      _TabItem(
        label: 'Créditer',
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        page: const TopUpScreen(),
      ),
      _TabItem(
        label: 'Membres',
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        page: const StudentListScreen(),
      ),
      _TabItem(
        label: 'Paiements',
        icon: Icons.qr_code_2_outlined,
        selectedIcon: Icons.qr_code_2,
        page: const PaymentInfoScreen(),
      ),
    ];
  }

  List<_TabItem> _getAdminTabs() {
    return [
      _TabItem(
        label: 'Accueil',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        page: const HomeScreen(),
      ),
      _TabItem(
        label: 'Produits',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        page: const ProductManagementScreen(),
      ),
      _TabItem(
        label: 'Paiements',
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments,
        page: const PaymentManagementScreen(),
      ),
      _TabItem(
        label: 'Stats',
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics,
        page: const StatsScreen(),
      ),
      _TabItem(
        label: 'Historique',
        icon: Icons.history_edu_outlined,
        selectedIcon: Icons.history_edu,
        page: const HistoryScreen(),
      ),
      _TabItem(
        label: 'Réglages',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        page: const SettingsScreen(),
      ),
    ];
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  _TabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });
}
