import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/firebase_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Transactions'),
      ),
      body: StreamBuilder<List<CafeTransaction>>(
        stream: firebaseService.getRecentTransactions(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return const Center(child: Text('Aucune transaction récente.'));
          }

          return ListView.separated(
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isPurchase = tx.type == TransactionType.purchase;
              final dateStr = DateFormat('dd/MM HH:mm').format(tx.timestamp);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPurchase ? Colors.green.shade100 : Colors.blue.shade100,
                  child: Icon(
                    isPurchase ? Icons.shopping_basket : Icons.add_card,
                    color: isPurchase ? Colors.green.shade800 : Colors.blue.shade800,
                  ),
                ),
                title: Text(
                  '${tx.studentName} - ${tx.price.toStringAsFixed(2)} €',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${isPurchase ? "Achat: ${tx.productName ?? 'Produit'}" : "Rechargement"}\nPar: ${tx.responsibleName} • $dateStr',
                ),
                trailing: Text(
                  tx.paymentMethod,
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
