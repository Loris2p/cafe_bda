import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';
import '../core/utils.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  late Stream<List<Product>> _productsStream;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final firebaseService = Provider.of<FirebaseService>(context);
      _productsStream = firebaseService.getProducts();
      _isInitialized = true;
    }
  }

  void _refresh() {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    setState(() {
      _productsStream = firebaseService.getProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Catalogue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: _refresh,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productsStream,
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
                      'Erreur lors du chargement des produits',
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

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Aucun produit dans le catalogue.', style: GoogleFonts.poppins(color: Colors.grey)),
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
                        context.read<FirebaseService>().updateProduct(updated);
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_product_fab',
        onPressed: () => _showAddProductDialog(context),
        icon: const Icon(Icons.add),
        label: Text('Nouveau produit', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    _showProductFormDialog(context);
  }

  void _showEditProductDialog(BuildContext context, Product p) {
    _showProductFormDialog(context, product: p);
  }

  void _showProductFormDialog(BuildContext context, {Product? product}) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: product?.name);
    final priceController = TextEditingController(text: product?.price.toStringAsFixed(2));
    final categoryController = TextEditingController(text: product?.category ?? 'Café');
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          isEdit ? 'Modifier Produit' : 'Nouveau Produit', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController, 
                decoration: InputDecoration(
                  labelText: 'Nom du produit',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController, 
                decoration: InputDecoration(
                  labelText: 'Prix (€)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: categoryController, 
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final name = nameController.text.trim();
                final priceText = priceController.text.replaceAll(',', '.').trim();
                final price = double.tryParse(priceText) ?? 0.0;
                
                try {
                  final service = context.read<FirebaseService>();
                  final newProduct = Product(
                    id: product?.id ?? '', 
                    name: name, 
                    price: price,
                    category: categoryController.text.trim(),
                    isAvailable: product?.isAvailable ?? true,
                  );

                  if (isEdit) {
                    await service.updateProduct(newProduct);
                  } else {
                    await service.addProduct(newProduct);
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
                            Text(isEdit ? 'Produit Modifié' : 'Produit Ajouté'),
                          ],
                        ),
                        content: Text('Le produit "$name" a été ${isEdit ? "mis à jour" : "ajouté au catalogue"}.'),
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
}
