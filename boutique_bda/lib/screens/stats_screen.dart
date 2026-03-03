import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';
import '../models/transaction.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques & Rapports'),
      ),
      body: StreamBuilder<List<CafeTransaction>>(
        stream: firebaseService.getRecentTransactions(limit: 500), // On prend un gros échantillon
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) return const Center(child: Text('Aucune donnée pour les statistiques.'));

          // Calculs simples
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // KPI Cards
                Row(
                  children: [
                    _KpiCard(title: 'Revenu Total', value: '${totalRevenue.toStringAsFixed(2)} €', color: Colors.green),
                    const SizedBox(width: 16),
                    _KpiCard(title: 'Cafés Servis', value: '$totalCoffees', color: Colors.brown),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Graphique Moyens de Paiement
                const Text('Répartition des Paiements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: paymentMethods.entries.map((e) {
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          title: e.key,
                          color: Colors.primaries[paymentMethods.keys.toList().indexOf(e.key) % Colors.primaries.length],
                          radius: 50,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Top Produits
                const Text('Produits Populaires', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                ...productsCount.entries.map((e) => ListTile(
                  title: Text(e.key),
                  trailing: Text('${e.value} ventes'),
                  leading: const Icon(Icons.coffee),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _KpiCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
