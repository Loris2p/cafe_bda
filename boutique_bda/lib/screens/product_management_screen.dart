import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';

class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Catalogue'),
      ),
      body: StreamBuilder<List<Product>>(
        stream: firebaseService.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(child: Text('Aucun produit dans le catalogue.'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return ListTile(
                leading: Icon(Icons.coffee, color: p.isAvailable ? Colors.brown : Colors.grey),
                title: Text(p.name, style: TextStyle(
                  decoration: p.isAvailable ? null : TextDecoration.lineThrough,
                  fontWeight: FontWeight.bold,
                )),
                subtitle: Text('${p.price.toStringAsFixed(2)} € • ${p.category}'),
                trailing: Switch(
                  value: p.isAvailable,
                  onChanged: (val) {
                    // Update availability in Firestore
                    // Note: Il faudrait ajouter une méthode updateProduct dans FirebaseService
                  },
                ),
                onTap: () => _showEditProductDialog(context, p),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau Produit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom du produit')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Prix (€)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0.0;
              if (name.isNotEmpty) {
                context.read<FirebaseService>().addProduct(Product(id: '', name: name, price: price));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    // Similaire à Add mais pré-rempli
  }
}
