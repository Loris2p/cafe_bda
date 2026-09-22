import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';
import '../core/utils.dart';
import 'inventory_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  late Stream<List<Product>> _productsStream;
  bool _isInitialized = false;

  String _selectedCategoryFilter = 'Tous'; // 'Tous', 'Nespresso', 'Dolce Gusto', 'Thé'
  String _selectedStockFilter = 'Tous';    // 'Tous', 'transfer', 'low', 'out'

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

  List<Product> _filterProducts(List<Product> products) {
    return products.where((p) {
      // Filtre catégorie
      if (_selectedCategoryFilter == 'Nespresso' && p.subCategory != ProductCategories.subNespresso) {
        return false;
      }
      if (_selectedCategoryFilter == 'Dolce Gusto' && p.subCategory != ProductCategories.subDolceGusto) {
        return false;
      }
      if (_selectedCategoryFilter == 'Thé' && p.category != ProductCategories.the) {
        return false;
      }

      // Filtre stock
      if (_selectedStockFilter == 'transfer' && !p.needsDeskTransfer) {
        return false;
      }
      if (_selectedStockFilter == 'low' && !p.isLowStock) {
        return false;
      }
      if (_selectedStockFilter == 'out' && !p.isOutOfStock) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Catalogue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Rafraîchir',
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              ).then((_) => _refresh());
            },
            icon: const Icon(Icons.fact_check, size: 18),
            label: const Text('Inventaire'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
          const SizedBox(width: 12),
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

          final allProducts = snapshot.data ?? [];
          final products = _filterProducts(allProducts);

          // Compteurs d'alertes
          final needsTransferCount = allProducts.where((p) => p.needsDeskTransfer).length;
          final lowStockCount = allProducts.where((p) => p.isLowStock).length;
          final outOfStockCount = allProducts.where((p) => p.isOutOfStock).length;

          return Column(
            children: [
              // Bandeau Filtres Catégorie
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                color: Colors.grey.shade50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Tous',
                        icon: Icons.apps,
                        isSelected: _selectedCategoryFilter == 'Tous',
                        onTap: () => setState(() => _selectedCategoryFilter = 'Tous'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Nespresso',
                        icon: Icons.coffee,
                        isSelected: _selectedCategoryFilter == 'Nespresso',
                        onTap: () => setState(() => _selectedCategoryFilter = 'Nespresso'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Dolce Gusto',
                        icon: Icons.coffee_maker,
                        isSelected: _selectedCategoryFilter == 'Dolce Gusto',
                        onTap: () => setState(() => _selectedCategoryFilter = 'Dolce Gusto'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Thé',
                        icon: Icons.emoji_food_beverage,
                        isSelected: _selectedCategoryFilter == 'Thé',
                        onTap: () => setState(() => _selectedCategoryFilter = 'Thé'),
                      ),
                    ],
                  ),
                ),
              ),

              // Bandeau Filtres Alertes de stock
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                color: Colors.grey.shade50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStockBadgeChip(
                        label: 'Tout statut',
                        badgeText: '${allProducts.length}',
                        color: Colors.grey.shade700,
                        isSelected: _selectedStockFilter == 'Tous',
                        onTap: () => setState(() => _selectedStockFilter = 'Tous'),
                      ),
                      const SizedBox(width: 8),
                      if (needsTransferCount > 0) ...[
                        _buildStockBadgeChip(
                          label: 'À remonter',
                          badgeText: '$needsTransferCount',
                          color: Colors.amber.shade800,
                          isSelected: _selectedStockFilter == 'transfer',
                          onTap: () => setState(() => _selectedStockFilter = 'transfer'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (lowStockCount > 0) ...[
                        _buildStockBadgeChip(
                          label: 'Stock faible',
                          badgeText: '$lowStockCount',
                          color: Colors.orange.shade800,
                          isSelected: _selectedStockFilter == 'low',
                          onTap: () => setState(() => _selectedStockFilter = 'low'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (outOfStockCount > 0) ...[
                        _buildStockBadgeChip(
                          label: 'Épuisé',
                          badgeText: '$outOfStockCount',
                          color: Colors.red.shade700,
                          isSelected: _selectedStockFilter == 'out',
                          onTap: () => setState(() => _selectedStockFilter = 'out'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Contenu principal
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Aucun produit correspondant.', style: GoogleFonts.poppins(color: Colors.grey)),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Rafraîchir'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: products.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final p = products[index];
                          return _buildProductCard(context, p);
                        },
                      ),
              ),
            ],
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

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.black87),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
        ],
      ),
      selectedColor: theme.primaryColor,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? theme.primaryColor : Colors.grey.shade300),
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildStockBadgeChip({
    required String label,
    required String badgeText,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.3) : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product p) {
    Color statusColor = Colors.green;
    String statusLabel = 'En stock';
    IconData statusIcon = Icons.check_circle_outline;

    if (p.isOutOfStock) {
      statusColor = Colors.red;
      statusLabel = 'Épuisé';
      statusIcon = Icons.cancel_outlined;
    } else if (p.needsDeskTransfer) {
      statusColor = Colors.amber.shade800;
      statusLabel = 'À remonter au bureau';
      statusIcon = Icons.warning_amber_rounded;
    } else if (p.isLowStock) {
      statusColor = Colors.orange.shade800;
      statusLabel = 'Stock global faible';
      statusIcon = Icons.error_outline;
    }

    final isTea = p.category == ProductCategories.the;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: p.needsDeskTransfer ? Colors.amber.shade400 : (p.isOutOfStock ? Colors.red.shade200 : Colors.grey.shade200),
          width: p.needsDeskTransfer ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne 1 : Titre, Catégorie, Switch actif & actions
          Row(
            children: [
              CircleAvatar(
                backgroundColor: p.isAvailable ? statusColor.withValues(alpha: 0.15) : Colors.grey.shade200,
                child: Icon(
                  isTea ? Icons.emoji_food_beverage : Icons.coffee,
                  color: p.isAvailable ? statusColor : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: p.isAvailable ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '${p.price.toStringAsFixed(2)} € • ${p.category} (${p.subCategory})',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Switch(
                value: p.isAvailable,
                onChanged: (val) {
                  final updated = p.copyWith(isAvailable: val);
                  context.read<FirebaseService>().updateProduct(updated);
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Modifier',
                onPressed: () => _showEditProductDialog(context, p),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ligne 2 : Statut visuel
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Total : ${p.totalStock}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ligne 3 : Jauges de stock (Bureau & Réserve)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storefront, size: 14, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          const Text('Bureau (rayon)', style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.stockBureau} capsule(s)',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: p.stockBureau == 0 ? Colors.red : Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.grey.shade300),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 14, color: Colors.brown.shade700),
                          const SizedBox(width: 4),
                          const Text('Réserve (fond)', style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.stockReserve} capsule(s)',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.brown.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Ligne 4 : Actions rapides de transfert et réassort
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: p.stockReserve > 0 ? () => _showTransferDialog(context, p) : null,
                  icon: const Icon(Icons.move_to_inbox, size: 18),
                  label: Text(
                    p.stockReserve > 0 ? 'Transférer au Bureau' : 'Réserve vide',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.needsDeskTransfer ? Colors.amber.shade900 : Theme.of(context).primaryColor,
                    side: BorderSide(
                      color: p.needsDeskTransfer ? Colors.amber.shade700 : Colors.grey.shade300,
                      width: p.needsDeskTransfer ? 2 : 1,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showRestockDialog(context, p),
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Arrivage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.brown.shade800,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- DIALOGUE RAPIDE : TRANSFERT RÉSERVE -> BUREAU ---
  void _showTransferDialog(BuildContext context, Product p) {
    int qtyToTransfer = p.standardBoxSize.clamp(1, p.stockReserve);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final boxSize = p.standardBoxSize;
          final maxQty = p.stockReserve;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Row(
              children: [
                Icon(Icons.move_to_inbox, color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 12),
                const Expanded(child: Text('Transférer au Bureau')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'Actuel : ${p.stockBureau} au bureau • ${p.stockReserve} en réserve',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),

                // Boutons raccourcis adaptés au conditionnement
                const Text('Raccourcis rapides :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: Text('+1 boîte ($boxSize)'),
                      onPressed: maxQty >= boxSize
                          ? () => setDlgState(() => qtyToTransfer = boxSize)
                          : null,
                    ),
                    if (maxQty >= boxSize * 2)
                      ActionChip(
                        label: Text('+2 boîtes (${boxSize * 2})'),
                        onPressed: () => setDlgState(() => qtyToTransfer = boxSize * 2),
                      ),
                    ActionChip(
                      label: Text('Tout ($maxQty)'),
                      onPressed: () => setDlgState(() => qtyToTransfer = maxQty),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stepper de quantité
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: qtyToTransfer > 1 ? () => setDlgState(() => qtyToTransfer--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 32,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$qtyToTransfer',
                      style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: qtyToTransfer < maxQty ? () => setDlgState(() => qtyToTransfer++) : null,
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Après transfert : ${p.stockBureau + qtyToTransfer} au bureau / ${p.stockReserve - qtyToTransfer} en réserve',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await context.read<FirebaseService>().transferStock(
                          productId: p.id,
                          quantity: qtyToTransfer,
                        );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      showCustomSnackBar(
                        context,
                        message: '$qtyToTransfer dosette(s) transférée(s) au bureau.',
                        backgroundColor: Colors.green,
                        icon: Icons.check_circle,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showCustomSnackBar(context, message: 'Erreur : $e', backgroundColor: Colors.red);
                    }
                  }
                },
                child: const Text('Confirmer le transfert'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DIALOGUE RAPIDE : RÉASSORT FOURNISSEUR ---
  void _showRestockDialog(BuildContext context, Product p) {
    int qtyToAdd = p.standardBoxSize;
    bool toReserve = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Row(
              children: [
                Icon(Icons.add_shopping_cart, color: Colors.brown.shade800, size: 28),
                const SizedBox(width: 12),
                const Text('Arrivage de Stock'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),

                // Destination du réassort
                const Text('Destination de l\'arrivage :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('En Réserve')),
                        selected: toReserve,
                        onSelected: (val) => setDlgState(() => toReserve = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Au Bureau')),
                        selected: !toReserve,
                        onSelected: (val) => setDlgState(() => toReserve = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Raccourcis rapides
                const Text('Quantité reçue :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [10, 20, 50, 100].map((n) {
                    return ActionChip(
                      label: Text('+$n'),
                      onPressed: () => setDlgState(() => qtyToAdd = n),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Stepper
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: qtyToAdd > 1 ? () => setDlgState(() => qtyToAdd = (qtyToAdd - 5).clamp(1, 9999)) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 32,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$qtyToAdd',
                      style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => setDlgState(() => qtyToAdd += 5),
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await context.read<FirebaseService>().restockProduct(
                          productId: p.id,
                          quantity: qtyToAdd,
                          toReserve: toReserve,
                        );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      showCustomSnackBar(
                        context,
                        message: '+$qtyToAdd capsule(s) ajoutée(s) ${toReserve ? "en réserve" : "au bureau"}.',
                        backgroundColor: Colors.green,
                        icon: Icons.check_circle,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showCustomSnackBar(context, message: 'Erreur : $e', backgroundColor: Colors.red);
                    }
                  }
                },
                child: const Text('Ajouter le stock'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DIALOGUE CRÉATION / ÉDITION ---
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
    final bureauController = TextEditingController(text: '${product?.stockBureau ?? 0}');
    final reserveController = TextEditingController(text: '${product?.stockReserve ?? 0}');
    final thresholdController = TextEditingController(text: '${product?.alertThreshold ?? 10}');

    String selectedCategory = product?.category ?? ProductCategories.cafe;
    String selectedSubCategory = product?.subCategory ?? ProductCategories.subNespresso;
    bool trackStock = product?.trackStock ?? true;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final subCategories = selectedCategory == ProductCategories.cafe
              ? ProductCategories.cafeSubCategories
              : ProductCategories.theSubCategories;

          if (!subCategories.contains(selectedSubCategory)) {
            selectedSubCategory = subCategories.first;
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(
              isEdit ? 'Modifier Produit' : 'Nouveau Produit',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du produit (ex: Ristretto, Menthe...)',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Sélection Catégorie principale
                    const Text('Catégorie :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: ProductCategories.mainCategories.map((cat) {
                        final isSel = selectedCategory == cat;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Center(
                                child: Text(cat == ProductCategories.cafe ? '☕ Café' : '🫖 Thé'),
                              ),
                              selected: isSel,
                              onSelected: (val) {
                                if (val) {
                                  setDlgState(() {
                                    selectedCategory = cat;
                                    selectedSubCategory = cat == ProductCategories.cafe
                                        ? ProductCategories.subNespresso
                                        : ProductCategories.theSubCategories.first;
                                  });
                                }
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Sélection Sous-catégorie
                    const Text('Type / Machine :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: subCategories.map((sub) {
                        return ChoiceChip(
                          label: Text(sub),
                          selected: selectedSubCategory == sub,
                          onSelected: (val) {
                            if (val) setDlgState(() => selectedSubCategory = sub);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Prix
                    TextFormField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Prix unitaire (€)',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Stocks
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: bureauController,
                            decoration: InputDecoration(
                              labelText: 'Stock Bureau',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: reserveController,
                            decoration: InputDecoration(
                              labelText: 'Stock Réserve',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Seuil d'alerte global
                    TextFormField(
                      controller: thresholdController,
                      decoration: InputDecoration(
                        labelText: 'Seuil d\'alerte stock faible (Bureau + Réserve)',
                        helperText: 'Alerte quand le stock total tombe sous ce seuil',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Switch Suivre le stock
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Suivi actif des stocks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Décrémente automatiquement lors des ventes', style: TextStyle(fontSize: 12)),
                      value: trackStock,
                      onChanged: (val) => setDlgState(() => trackStock = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text.replaceAll(',', '.').trim()) ?? 0.0;
                    final stockBureau = int.tryParse(bureauController.text.trim()) ?? 0;
                    final stockReserve = int.tryParse(reserveController.text.trim()) ?? 0;
                    final alertThreshold = int.tryParse(thresholdController.text.trim()) ?? 10;

                    try {
                      final service = context.read<FirebaseService>();
                      final newProduct = Product(
                        id: product?.id ?? '',
                        name: name,
                        price: price,
                        category: selectedCategory,
                        subCategory: selectedSubCategory,
                        stockBureau: stockBureau,
                        stockReserve: stockReserve,
                        alertThreshold: alertThreshold,
                        trackStock: trackStock,
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
                        showCustomSnackBar(
                          context,
                          message: 'Le produit "$name" a été ${isEdit ? "mis à jour" : "ajouté"}.',
                          backgroundColor: Colors.green,
                          icon: Icons.check_circle,
                        );
                      }
                      _refresh();
                    } catch (e) {
                      if (context.mounted) {
                        showCustomSnackBar(context, message: 'Erreur : $e', backgroundColor: Colors.red);
                      }
                    }
                  }
                },
                child: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }
}
