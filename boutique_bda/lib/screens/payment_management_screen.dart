import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment_method.dart';
import '../services/firebase_service.dart';

class PaymentManagementScreen extends StatelessWidget {
  const PaymentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Paiements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Trigger a rebuild by calling setState if it was a StatefulWidget, 
              // but here it's a StatelessWidget. The StreamBuilder will handle 
              // it if we provide a way to trigger it. 
              // For now, switching tabs is the easiest way to refresh a Stream.fromFuture.
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PaymentMethod>>(
        stream: firebaseService.getPaymentMethods(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final methods = snapshot.data ?? [];

          if (methods.isEmpty) {
            return const Center(child: Text('Aucun moyen de paiement configuré.'));
          }

          return ListView.separated(
            itemCount: methods.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final m = methods[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: m.isActive ? Colors.blue.shade100 : Colors.grey.shade200,
                  child: Icon(Icons.payment, color: m.isActive ? Colors.blue : Colors.grey),
                ),
                title: Text(m.label, style: TextStyle(
                  decoration: m.isActive ? null : TextDecoration.lineThrough,
                  fontWeight: FontWeight.bold,
                )),
                subtitle: Text('${m.phone} ${m.link.isNotEmpty ? "• Lien QR présent" : ""}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: m.isActive,
                      onChanged: (val) {
                        final updated = PaymentMethod(
                          id: m.id,
                          label: m.label,
                          phone: m.phone,
                          link: m.link,
                          isActive: val,
                        );
                        firebaseService.updatePaymentMethod(updated);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditMethodDialog(context, m),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _showDeleteConfirmation(context, m),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_payment_fab',
        onPressed: () => _showAddMethodDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMethodDialog(BuildContext context) {
    final labelController = TextEditingController();
    final phoneController = TextEditingController();
    final linkController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau Moyen de Paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Label (ex: Lydia)')),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Numéro de téléphone')),
            const SizedBox(height: 12),
            TextField(controller: linkController, decoration: const InputDecoration(labelText: 'Lien de paiement (pour QR Code)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final label = labelController.text.trim();
              if (label.isNotEmpty) {
                context.read<FirebaseService>().addPaymentMethod(PaymentMethod(
                  id: '', 
                  label: label, 
                  phone: phoneController.text.trim(),
                  link: linkController.text.trim(),
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditMethodDialog(BuildContext context, PaymentMethod m) {
    final labelController = TextEditingController(text: m.label);
    final phoneController = TextEditingController(text: m.phone);
    final linkController = TextEditingController(text: m.link);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier Moyen de Paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Label')),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Numéro de téléphone')),
            const SizedBox(height: 12),
            TextField(controller: linkController, decoration: const InputDecoration(labelText: 'Lien de paiement')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final label = labelController.text.trim();
              if (label.isNotEmpty) {
                context.read<FirebaseService>().updatePaymentMethod(PaymentMethod(
                  id: m.id, 
                  label: label, 
                  phone: phoneController.text.trim(),
                  link: linkController.text.trim(),
                  isActive: m.isActive,
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PaymentMethod m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous vraiment supprimer "${m.label}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              context.read<FirebaseService>().deletePaymentMethod(m.id);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
