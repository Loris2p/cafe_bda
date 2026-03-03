import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/student.dart';
import '../widgets/student_search_delegate.dart';
import '../main.dart';
import 'sale_screen.dart';
import 'top_up_screen.dart';
import 'student_list_screen.dart';
import 'history_screen.dart';
import 'product_management_screen.dart';
import 'stats_screen.dart';
import 'payment_info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AdminProvider>().isAdmin;
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique BDA', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Switch(
            value: isAdmin,
            onChanged: (val) => context.read<AdminProvider>().setAdmin(val),
            activeThumbColor: Colors.white,
          ),
          IconButton(
            onPressed: () => context.read<AuthService>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Image.asset('assets/icon/logo-bda.png', height: 140),
                  const SizedBox(height: 24),
                  Text(
                    'Bienvenue au Café BDA',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Barre de recherche
                  _buildSearchBar(context, firebaseService),

                  const SizedBox(height: 48),
                  _buildDashboardGrid(context),
                  
                  const SizedBox(height: 48),
                  if (isAdmin) _buildAdminSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, FirebaseService service) {
    return Container(
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
        readOnly: true,
        onTap: () => _handleSearch(context, service),
        decoration: InputDecoration(
          hintText: "Rechercher un étudiant...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => _handleSearch(context, service),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  Future<void> _handleSearch(BuildContext context, FirebaseService service) async {
    final students = await service.getStudents().first;
    if (!context.mounted) return;
    
    final result = await showSearch<Student?>(
      context: context,
      delegate: StudentSearchDelegate(students),
    );
    
    if (result != null && context.mounted) {
      _showStudentDetails(context, result);
    }
  }

  void _showStudentDetails(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(child: Text(student.lastName[0])),
            const SizedBox(width: 12),
            Expanded(child: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Matricule: ${student.studentId}', style: const TextStyle(color: Colors.grey)),
            Text('Classe: ${student.classGroup}', style: const TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Solde actuel :'),
                Text('${student.balance.toStringAsFixed(2)} €', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 22,
                    color: student.balance >= 0 ? Colors.green : Colors.red
                  )
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Colors.amber),
                  const SizedBox(width: 12),
                  Text('Fidélité : ${student.loyaltyBonus} café(s) offert(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TopUpScreen()));
                  },
                  icon: const Icon(Icons.add_card),
                  label: const Text('Créditer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleScreen()));
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Vendre'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 2.5,
      children: [
        _DashboardCard(
          title: 'Étudiants',
          subtitle: 'Soldes & Inscriptions',
          icon: Icons.people_alt_rounded,
          color: Colors.blue.shade700,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentListScreen())),
        ),
        _DashboardCard(
          title: 'Vendre',
          subtitle: 'Passer une commande',
          icon: Icons.shopping_cart_rounded,
          color: Colors.green.shade700,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleScreen())),
        ),
        _DashboardCard(
          title: 'Créditer',
          subtitle: 'Recharger un compte',
          icon: Icons.add_card_rounded,
          color: Colors.purple.shade700,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopUpScreen())),
        ),
        _DashboardCard(
          title: 'Paiements',
          subtitle: 'QR Codes & Infos',
          icon: Icons.qr_code_rounded,
          color: Colors.teal.shade700,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentInfoScreen())),
        ),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 24),
        Text('Administration', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.deepOrange, child: Icon(Icons.inventory, color: Colors.white)),
                title: const Text('Gérer les produits'),
                subtitle: const Text('Modifier prix et stocks'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductManagementScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.bar_chart, color: Colors.white)),
                title: const Text('Statistiques'),
                subtitle: const Text('Revenus et top ventes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.history, color: Colors.white)),
                title: const Text('Historique complet'),
                subtitle: const Text('Toutes les transactions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
