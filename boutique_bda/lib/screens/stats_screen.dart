import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../models/transaction.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Stream<List<CafeTransaction>> _statsStream;
  bool _isInitialized = false;
  
  // États pour les stats agrégées (KPIs rapides, toutes périodes)
  double _totalRevenue = 0;
  int _totalItems = 0;
  double _avgBasket = 0;
  bool _loadingKPIs = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadData();
      _isInitialized = true;
    }
  }

  Future<void> _loadData() async {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    
    setState(() {
      _loadingKPIs = true;
      _statsStream = firebaseService.getRecentTransactions(limit: 1000); 
    });

    try {
      final globalStats = await firebaseService.getGlobalStats();
      if (!mounted) return;
      
      final revenue = (globalStats['totalRevenue'] as num).toDouble();
      final count = (globalStats['totalCount'] as num).toInt();
      
      setState(() {
        _totalRevenue = revenue;
        _totalItems = (globalStats['totalItems'] as num).toInt();
        _avgBasket = count > 0 ? (revenue / count) : 0.0;
        _loadingKPIs = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingKPIs = false);
    }
  }

  void _refresh() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques Globales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: _refresh,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPIs "Toutes Périodes" (via agrégations Firestore rapides)
            _buildSectionHeader('Bilan Global (Tout temps)'),
            const SizedBox(height: 16),
            Row(
              children: [
                _ModernKpiCard(
                  title: 'Revenu Total', 
                  value: _loadingKPIs ? '...' : '${_totalRevenue.toStringAsFixed(2)} €', 
                  icon: Icons.euro, 
                  color: Colors.green
                ),
                const SizedBox(width: 16),
                _ModernKpiCard(
                  title: 'Articles Vendus', 
                  value: _loadingKPIs ? '...' : '$_totalItems', 
                  icon: Icons.coffee, 
                  color: Colors.brown
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ModernKpiCard(
                  title: 'Panier Moyen', 
                  value: _loadingKPIs ? '...' : '${_avgBasket.toStringAsFixed(2)} €', 
                  icon: Icons.shopping_cart_outlined, 
                  color: Colors.blue
                ),
                const SizedBox(width: 16),
                _ModernKpiCard(
                  title: 'Période Analysée', 
                  value: 'Aujourd\'hui', 
                  icon: Icons.calendar_today, 
                  color: Colors.orange
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Section Graphiques (Nécessite le téléchargement des documents récents)
            _buildSectionHeader('Analyse Récente (1000 derniers)'),
            const SizedBox(height: 16),
            StreamBuilder<List<CafeTransaction>>(
              stream: _statsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }

                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) return const Center(child: Text('Aucune transaction récente.'));

                Map<String, int> paymentMethods = {};
                Map<String, int> productsCount = {};

                for (var tx in transactions) {
                  if (tx.type == TransactionType.purchase) {
                    productsCount[tx.productName ?? 'Inconnu'] = (productsCount[tx.productName] ?? 0) + tx.amount.toInt();
                  }
                  
                  String method = tx.paymentMethod;
                  if (method.startsWith('Autre')) method = 'Autre';
                  paymentMethods[method] = (paymentMethods[method] ?? 0) + 1;
                }

                final sortedProducts = productsCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text('Répartition des Moyens de Paiement', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                    const SizedBox(height: 16),
                    Container(
                      height: 250,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
                      ),
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          sections: paymentMethods.entries.map((e) {
                            final index = paymentMethods.keys.toList().indexOf(e.key);
                            return PieChartSectionData(
                              value: e.value.toDouble(),
                              title: '${e.key}\n${e.value}',
                              color: Colors.primaries[index % Colors.primaries.length],
                              radius: 60,
                              titleStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    Text('Top Produits (Ventes cumulées)', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedProducts.take(10).length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final e = sortedProducts[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                child: Text('#${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Text(e.key, style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                              Text('${e.value} ventes', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold));
  }
}

class _ModernKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ModernKpiCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
