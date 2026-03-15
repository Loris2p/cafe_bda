import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/payment_method.dart';
import '../services/firebase_service.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  late Stream<List<PaymentMethod>> _methodsStream;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final firebaseService = Provider.of<FirebaseService>(context);
      _methodsStream = firebaseService.getPaymentMethods();
      _isInitialized = true;
    }
  }

  void _refresh() {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    setState(() {
      _methodsStream = firebaseService.getPaymentMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Paiements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: StreamBuilder<List<PaymentMethod>>(
        stream: _methodsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur lors du chargement des moyens de paiement',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _refresh, child: const Text('Réessayer')),
                  ],
                ),
              ),
            );
          }

          final methods = snapshot.data ?? [];

          if (methods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Aucun moyen de paiement configuré.', style: GoogleFonts.poppins(color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _refresh, 
                    icon: const Icon(Icons.refresh), 
                    label: const Text('Rafraîchir'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                        context.read<FirebaseService>().updatePaymentMethod(updated);
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_payment_fab',
        onPressed: () => _showAddMethodDialog(context),
        icon: const Icon(Icons.add),
        label: Text('Moyen de paiement', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddMethodDialog(BuildContext context) {
    _showMethodFormDialog(context);
  }

  void _showEditMethodDialog(BuildContext context, PaymentMethod m) {
    _showMethodFormDialog(context, method: m);
  }

  void _showMethodFormDialog(BuildContext context, {PaymentMethod? method}) {
    final isEdit = method != null;
    final labelController = TextEditingController(text: method?.label);
    final phoneController = TextEditingController(text: method?.phone);
    final linkController = TextEditingController(text: method?.link);
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          isEdit ? 'Modifier Paiement' : 'Nouveau Paiement', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: labelController, 
                decoration: InputDecoration(
                  labelText: 'Label (ex: Lydia)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController, 
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: linkController, 
                decoration: InputDecoration(
                  labelText: 'Lien de paiement (pour QR)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final label = labelController.text.trim();
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  final service = context.read<FirebaseService>();
                  final updatedMethod = PaymentMethod(
                    id: method?.id ?? '', 
                    label: label, 
                    phone: phoneController.text.trim(),
                    link: linkController.text.trim(),
                    isActive: method?.isActive ?? true,
                  );

                  if (isEdit) {
                    await service.updatePaymentMethod(updatedMethod);
                  } else {
                    await service.addPaymentMethod(updatedMethod);
                  }
                  
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);

                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (successCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        title: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 30),
                            const SizedBox(width: 12),
                            Text(isEdit ? 'Moyen Modifié' : 'Moyen Ajouté'),
                          ],
                        ),
                        content: Text('Le moyen de paiement "$label" a été ${isEdit ? "mis à jour" : "configuré"}.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(successCtx), child: const Text('OK')),
                        ],
                      ),
                    );
                  }
                  _refresh();
                } catch (e) {
                  if (context.mounted) {
                    showCustomSnackBar(context, message: 'Erreur : $e', backgroundColor: Colors.red, icon: Icons.error_outline);
                  }
                }
              }
            },
            child: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PaymentMethod m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous vraiment supprimer "${m.label}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              try {
                await context.read<FirebaseService>().deletePaymentMethod(m.id);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (context.mounted) {
                  showCustomSnackBar(context, message: 'Moyen de paiement supprimé', backgroundColor: Colors.blueGrey, icon: Icons.delete_sweep_outlined);
                }
                _refresh();
              } catch (e) {
                if (context.mounted) {
                  showCustomSnackBar(context, message: 'Erreur : $e', backgroundColor: Colors.red, icon: Icons.error_outline);
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
