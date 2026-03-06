import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../models/student.dart';
import '../widgets/student_search_delegate.dart';
import '../main.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AdminProvider>().isAdmin;
    final firebaseService = context.read<FirebaseService>();
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header Immersif
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final top = constraints.biggest.height;
                return FlexibleSpaceBar(
                  centerTitle: true,
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: top < 140 ? 1.0 : 0.0,
                    child: Text(
                      'Boutique BDA',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50,
                          top: -20,
                          child: Icon(Icons.coffee, size: 200, color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: top > 140 ? 1.0 : 0.0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Image.asset('assets/icon/logoBDA_4_complet.png', height: 40),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Boutique BDA',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Que voulez-vous faire aujourd\'hui ?',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                tooltip: 'Paramètres',
              ),
            ],
          ),

          // Contenu du Dashboard
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModernSearchBar(context, firebaseService),
                    const SizedBox(height: 48),

                    Text('Actions Principales', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 20),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: _buildModernGrid(context),
                      ),
                    ),

                    const SizedBox(height: 40),
                    if (isAdmin) ...[
                      Text('Administration', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 20),
                      _buildAdminCards(context),
                    ],
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSearchBar(BuildContext context, FirebaseService service) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleSearch(context, service),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Text(
                  'Rechercher un membre...',
                  style: GoogleFonts.poppins(color: Colors.black45, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune, size: 20, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernGrid(BuildContext context) {
    final tabProvider = context.read<TabProvider>();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _ModernCard(
          title: 'Vendre',
          subtitle: 'Nouvelle commande',
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFF4CAF50),
          onTap: () => tabProvider.setTab(1),
        ),
        _ModernCard(
          title: 'Créditer',
          subtitle: 'Recharger compte',
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF2196F3),
          onTap: () => tabProvider.setTab(2),
        ),
        _ModernCard(
          title: 'Membres',
          subtitle: 'Liste étudiants',
          icon: Icons.people_outline,
          color: const Color(0xFF9C27B0),
          onTap: () => tabProvider.setTab(3),
        ),
        _ModernCard(
          title: 'Paiements',
          subtitle: 'QR & Lydia',
          icon: Icons.qr_code_2_outlined,
          color: const Color(0xFF00BCD4),
          onTap: () => tabProvider.setTab(4),
        ),
      ],
    );
  }

  Widget _buildAdminCards(BuildContext context) {
    final tabProvider = context.read<TabProvider>();
    return Column(
      children: [
        _AdminTile(
          title: 'Catalogue Produits',
          icon: Icons.inventory_2_outlined,
          onTap: () => tabProvider.setTab(1),
        ),
        const SizedBox(height: 12),
        _AdminTile(
          title: 'Statistiques Globales',
          icon: Icons.analytics_outlined,
          onTap: () => tabProvider.setTab(2),
        ),
        const SizedBox(height: 12),
        _AdminTile(
          title: 'Historique des Ventes',
          icon: Icons.history_edu_outlined,
          onTap: () => tabProvider.setTab(3),
        ),
      ],
    );
  }

  Future<void> _handleSearch(BuildContext context, FirebaseService service) async {
    final students = await service.getStudents().first;
    if (!context.mounted) return;
    final result = await showSearch<Student?>(context: context, delegate: StudentSearchDelegate(students));
    if (result != null && context.mounted) _showStudentDetails(context, result);
  }

  void _showStudentDetails(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(student.fullName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow(label: 'Matricule', value: student.studentId),
            _InfoRow(label: 'Classe', value: student.classGroup),
            const Divider(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: student.balance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Solde', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  Text('${student.balance.toStringAsFixed(2)} €', 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24, color: student.balance >= 0 ? Colors.green : Colors.red)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TabProvider>().setTab(1); // Index 1 est 'Vendre'
            },
            child: const Text('Vendre'),
          ),
        ],
      ),
    );
  }
}

class _ModernCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                      Text(subtitle, style: GoogleFonts.poppins(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminTile({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.white,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
