import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';
import '../core/utils.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Stream<List<Product>> _productsStream;
  bool _isInitialized = false;
  String _selectedFilter = 'Tous'; // 'Tous', 'Nespresso', 'Dolce Gusto', 'Thé'
  bool _isSaving = false;

  // Stocks édités localement : productId -> {'bureau': int, 'reserve': int}
  final Map<String, ({int bureau, int reserve})> _editedStocks = {};
  // Stocks originaux de la base pour comparaison
  final Map<String, ({int bureau, int reserve})> _originalStocks = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final firebaseService = Provider.of<FirebaseService>(context);
      _productsStream = firebaseService.getProducts();
      _isInitialized = true;
    }
  }

  void _syncInitialData(List<Product> products) {
    for (final p in products) {
      _originalStocks[p.id] = (bureau: p.stockBureau, reserve: p.stockReserve);
      _editedStocks.putIfAbsent(p.id, () => (bureau: p.stockBureau, reserve: p.stockReserve));
    }
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((p) {
      if (_selectedFilter == 'Nespresso') {
        return p.subCategory == ProductCategories.subNespresso;
      } else if (_selectedFilter == 'Dolce Gusto') {
        return p.subCategory == ProductCategories.subDolceGusto;
      } else if (_selectedFilter == 'Thé') {
        return p.category == ProductCategories.the;
      }
      return true;
    }).toList();
  }

  int _countDifferences() {
    int count = 0;
    for (final entry in _editedStocks.entries) {
      final original = _originalStocks[entry.key];
      if (original != null) {
        if (original.bureau != entry.value.bureau || original.reserve != entry.value.reserve) {
          count++;
        }
      }
    }
    return count;
  }

  void _resetToOriginal() {
    setState(() {
      _editedStocks.clear();
      for (final entry in _originalStocks.entries) {
        _editedStocks[entry.key] = entry.value;
      }
    });
    showCustomSnackBar(
      context,
      message: 'Comptages réinitialisés aux valeurs actuelles',
      icon: Icons.refresh,
    );
  }

  Future<void> _saveInventory(List<Product> allProducts) async {
    final diffCount = _countDifferences();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Icon(Icons.fact_check, color: Theme.of(context).primaryColor, size: 28),
            const SizedBox(width: 12),
            const Text('Valider l\'inventaire'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diffCount == 0
                  ? 'Aucun écart constaté. Confirmez-vous que les stocks sont conformes ?'
                  : '$diffCount produit(s) présentent un écart par rapport aux chiffres théoriques.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (diffCount > 0) ...[
              const Text('Résumé des écarts :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Column(
                    children: allProducts.where((p) {
                      final orig = _originalStocks[p.id];
                      final curr = _editedStocks[p.id];
                      if (orig == null || curr == null) return false;
                      return orig.bureau != curr.bureau || orig.reserve != curr.reserve;
                    }).map((p) {
                      final orig = _originalStocks[p.id]!;
                      final curr = _editedStocks[p.id]!;
                      final diffB = curr.bureau - orig.bureau;
                      final diffR = curr.reserve - orig.reserve;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                            if (diffB != 0)
                              Text(
                                'Bur: ${orig.bureau} → ${curr.bureau} (${diffB > 0 ? "+$diffB" : diffB})  ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: diffB < 0 ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (diffR != 0)
                              Text(
                                'Rés: ${orig.reserve} → ${curr.reserve} (${diffR > 0 ? "+$diffR" : diffR})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: diffR < 0 ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer & Enregistrer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final service = context.read<FirebaseService>();
    setState(() => _isSaving = true);
    try {
      await service.batchUpdateInventory(_editedStocks);

      if (!mounted) return;
      showCustomSnackBar(
        context,
        message: 'Inventaire mis à jour avec succès !',
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          message: 'Erreur lors de l\'inventaire : $e',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? [];
        if (snapshot.hasData && _originalStocks.isEmpty) {
          _syncInitialData(allProducts);
        }

        final filteredProducts = _filterProducts(allProducts);
        final diffCount = _countDifferences();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Inventaire Physique'),
            actions: [
              if (diffCount > 0)
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: 'Réinitialiser',
                  onPressed: _resetToOriginal,
                ),
              TextButton.icon(
                onPressed: _isSaving || allProducts.isEmpty ? null : () => _saveInventory(allProducts),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, color: Colors.white),
                label: Text(
                  diffCount > 0 ? 'Valider ($diffCount)' : 'Valider',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Column(
            children: [
              // Bandeau Filtres de catégorie
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey.shade50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tous', Icons.apps),
                      const SizedBox(width: 8),
                      _buildFilterChip('Nespresso', Icons.coffee),
                      const SizedBox(width: 8),
                      _buildFilterChip('Dolce Gusto', Icons.coffee_maker),
                      const SizedBox(width: 8),
                      _buildFilterChip('Thé', Icons.emoji_food_beverage),
                    ],
                  ),
                ),
              ),

              // Bannière info rapide
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: diffCount > 0 ? Colors.orange.shade50 : Colors.blue.shade50,
                child: Row(
                  children: [
                    Icon(
                      diffCount > 0 ? Icons.info_outline : Icons.check_circle_outline,
                      size: 18,
                      color: diffCount > 0 ? Colors.orange.shade800 : Colors.blue.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        diffCount > 0
                            ? '$diffCount produit(s) ajusté(s). Validez en haut pour enregistrer.'
                            : 'Ajustez directement le nombre de capsules constatées au Bureau et en Réserve.',
                        style: TextStyle(
                          fontSize: 12,
                          color: diffCount > 0 ? Colors.orange.shade900 : Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des produits
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : filteredProducts.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun produit trouvé pour ce filtre.',
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredProducts.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final p = filteredProducts[i];
                              return _buildProductInventoryCard(p);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
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
      onSelected: (val) => setState(() => _selectedFilter = label),
    );
  }

  Widget _buildProductInventoryCard(Product product) {
    final original = _originalStocks[product.id] ?? (bureau: product.stockBureau, reserve: product.stockReserve);
    final current = _editedStocks[product.id] ?? (bureau: product.stockBureau, reserve: product.stockReserve);

    final diffBureau = current.bureau - original.bureau;
    final diffReserve = current.reserve - original.reserve;
    final hasChanges = diffBureau != 0 || diffReserve != 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasChanges ? Colors.orange.shade400 : Colors.grey.shade200,
          width: hasChanges ? 2 : 1,
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
          // Titre & badges
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${product.category} • ${product.subCategory} • ${product.price.toStringAsFixed(2)} €',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (hasChanges)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Modifié',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Ligne Comptoir / Bureau
          _buildStockAdjusterRow(
            label: 'Bureau (en rayon)',
            icon: Icons.storefront,
            originalQty: original.bureau,
            currentQty: current.bureau,
            diff: diffBureau,
            color: Colors.blue.shade700,
            onChanged: (newVal) {
              setState(() {
                _editedStocks[product.id] = (bureau: newVal, reserve: current.reserve);
              });
            },
          ),
          const SizedBox(height: 12),

          // Ligne Réserve
          _buildStockAdjusterRow(
            label: 'Réserve (stock fond)',
            icon: Icons.inventory_2_outlined,
            originalQty: original.reserve,
            currentQty: current.reserve,
            diff: diffReserve,
            color: Colors.brown.shade700,
            onChanged: (newVal) {
              setState(() {
                _editedStocks[product.id] = (bureau: current.bureau, reserve: newVal);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStockAdjusterRow({
    required String label,
    required IconData icon,
    required int originalQty,
    required int currentQty,
    required int diff,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(
                  'Théorique : $originalQty',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Badge d'écart
          if (diff != 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: diff < 0 ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                diff > 0 ? '+$diff' : '$diff',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: diff < 0 ? Colors.red.shade900 : Colors.green.shade900,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Stepper tactile ergonomique
          IconButton(
            onPressed: currentQty > 0 ? () => onChanged(currentQty - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 26,
            color: Colors.grey.shade700,
            visualDensity: VisualDensity.compact,
          ),
          InkWell(
            onTap: () async {
              final val = await _showDirectNumberDialog(context, currentQty, label);
              if (val != null) onChanged(val);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                '$currentQty',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(currentQty + 1),
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 26,
            color: Theme.of(context).primaryColor,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Future<int?> _showDirectNumberDialog(BuildContext context, int currentValue, String title) async {
    final controller = TextEditingController(text: '$currentValue');
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier $title'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nouvelle quantité constatée',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, n != null && n >= 0 ? n : currentValue);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
