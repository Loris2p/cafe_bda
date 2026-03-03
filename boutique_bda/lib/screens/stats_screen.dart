import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../models/transaction.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: StreamBuilder<List<CafeTransaction>>(
        stream: firebaseService.getRecentTransactions(limit: 1000),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) return const Center(child: Text('Aucune donnée disponible.'));

          double totalRevenue = 0;
          int totalCoffees = 0;
          Map<String, int> paymentMethods = {};
          Map<String, int> productsCount = {};

          for (var tx in transactions) {
            if (tx.type == TransactionType.purchase) {
              totalRevenue += tx.price;
              totalCoffees += tx.amount.toInt();
              productsCount[tx.productName ?? 'Inconnu'] = (productsCount[tx.productName] ?? 0) + tx.amount.toInt();
            }
            paymentMethods[tx.paymentMethod] = (paymentMethods[tx.paymentMethod] ?? 0) + 1;
          }

          final sortedProducts = productsCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ModernKpiCard(title: 'Revenu Total', value: '${totalRevenue.toStringAsFixed(2)} €', icon: Icons.euro, color: Colors.green),
                    const SizedBox(width: 16),
                    _ModernKpiCard(title: 'Cafés Servis', value: '$totalCoffees', icon: Icons.coffee, color: Colors.brown),
                  ],
                ),
                const SizedBox(height: 40),
                
                _buildSectionHeader('Répartition des Paiements'),
                const SizedBox(height: 24),
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
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
                          titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                _buildSectionHeader('Top Produits'),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedProducts.take(5).length,
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
            ),
          );
        },
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
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
