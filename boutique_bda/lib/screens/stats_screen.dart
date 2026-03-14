import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  double _totalCredits = 0;
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
        _totalCredits = (globalStats['totalCredits'] as num).toDouble();
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
            // KPIs "Toutes Périodes"
            _buildSectionHeader('Bilan Global (Tout temps)'),
            const SizedBox(height: 16),
            Row(
              children: [
                _ModernKpiCard(
                  title: 'Ventes Totales', 
                  value: _loadingKPIs ? '...' : '${_totalRevenue.toStringAsFixed(2)} €', 
                  icon: Icons.euro, 
                  color: Colors.green
                ),
                const SizedBox(width: 16),
                _ModernKpiCard(
                  title: 'Rechargements', 
                  value: _loadingKPIs ? '...' : '${_totalCredits.toStringAsFixed(2)} €', 
                  icon: Icons.account_balance_wallet_outlined, 
                  color: Colors.blue
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ModernKpiCard(
                  title: 'Articles Vendus', 
                  value: _loadingKPIs ? '...' : '$_totalItems', 
                  icon: Icons.coffee, 
                  color: Colors.brown
                ),
                const SizedBox(width: 16),
                _ModernKpiCard(
                  title: 'Panier Moyen', 
                  value: _loadingKPIs ? '...' : '${_avgBasket.toStringAsFixed(2)} €', 
                  icon: Icons.shopping_cart_outlined, 
                  color: Colors.orange
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Section Graphiques (Documents récents)
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

                // Calculs locaux pour les graphiques
                Map<String, int> paymentMethods = {};
                Map<String, int> productsCount = {};
                Map<DateTime, double> salesByDay = {};

                for (var tx in transactions) {
                  final date = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
                  
                  if (tx.type == TransactionType.purchase) {
                    productsCount[tx.productName ?? 'Inconnu'] = (productsCount[tx.productName] ?? 0) + tx.amount.toInt();
                    salesByDay[date] = (salesByDay[date] ?? 0) + tx.price;
                    
                    String method = tx.paymentMethod;
                    if (method.startsWith('Autre')) method = 'Autre';
                    paymentMethods[method] = (paymentMethods[method] ?? 0) + 1;
                  }
                }

                final sortedProducts = productsCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                final sortedSales = salesByDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Évolution des Ventes (€)'),
                    const SizedBox(height: 24),
                    _buildLineChart(sortedSales, theme),
                    
                    const SizedBox(height: 40),
                    _buildSectionHeader('Répartition des Paiements'),
                    const SizedBox(height: 24),
                    _buildPieChart(paymentMethods),
                    
                    const SizedBox(height: 40),
                    _buildSectionHeader('Top Produits (Ventes cumulées)'),
                    const SizedBox(height: 16),
                    _buildProductList(sortedProducts, theme),
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

  Widget _buildLineChart(List<MapEntry<DateTime, double>> data, ThemeData theme) {
    if (data.isEmpty) return const Center(child: Text('Pas assez de données.'));
    
    return Container(
      height: 200,
      padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    if (value.toInt() == 0 || value.toInt() == data.length - 1 || value.toInt() == data.length ~/ 2) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(DateFormat('dd/MM').format(data[value.toInt()].key), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> paymentMethods) {
    return Container(
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
    );
  }

  Widget _buildProductList(List<MapEntry<String, int>> sortedProducts, ThemeData theme) {
    return ListView.separated(
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
    );
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
            Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
