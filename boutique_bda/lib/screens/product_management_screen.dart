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

          return ListView.separated(
            itemCount: products.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = products[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: p.isAvailable ? Colors.brown.shade100 : Colors.grey.shade200,
                  child: Icon(Icons.coffee, color: p.isAvailable ? Colors.brown : Colors.grey),
                ),
                title: Text(p.name, style: TextStyle(
                  decoration: p.isAvailable ? null : TextDecoration.lineThrough,
                  fontWeight: FontWeight.bold,
                )),
                subtitle: Text('${p.price.toStringAsFixed(2)} € • ${p.category}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: p.isAvailable,
                      onChanged: (val) {
                        final updated = Product(
                          id: p.id,
                          name: p.name,
                          price: p.price,
                          category: p.category,
                          isAvailable: val,
                        );
                        firebaseService.updateProduct(updated);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditProductDialog(context, p),
                    ),
                  ],
                ),
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
    final categoryController = TextEditingController(text: 'Café');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau Produit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom du produit')),
            const SizedBox(height: 12),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Prix (€)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Catégorie')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
              if (name.isNotEmpty) {
                context.read<FirebaseService>().addProduct(Product(
                  id: '', 
                  name: name, 
                  price: price,
                  category: categoryController.text.trim(),
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

  void _showEditProductDialog(BuildContext context, Product p) {
    final nameController = TextEditingController(text: p.name);
    final priceController = TextEditingController(text: p.price.toString());
    final categoryController = TextEditingController(text: p.category);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier Produit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom du produit')),
            const SizedBox(height: 12),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Prix (€)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Catégorie')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
              if (name.isNotEmpty) {
                context.read<FirebaseService>().updateProduct(Product(
                  id: p.id, 
                  name: name, 
                  price: price,
                  category: categoryController.text.trim(),
                  isAvailable: p.isAvailable,
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
}
