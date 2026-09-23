import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/student.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/app_user.dart';
import '../services/firebase_service.dart';
import '../widgets/student_search_delegate.dart';
import '../main.dart';
import '../core/utils.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  Student? _selectedStudent;
  Product? _selectedProduct;
  int _quantity = 1;
  String _paymentMethod = 'Crédit';
  final TextEditingController _otherPaymentController = TextEditingController();
  bool _isProcessing = false;

  String _selectedCategoryFilter = 'Tous'; // 'Tous', 'Nespresso', 'Dolce Gusto', 'Thé'

  late Stream<List<Student>> _studentsStream;
  late Stream<List<Product>> _productsStream;
  bool _isInitialized = false;

  @override
  void dispose() {
    _otherPaymentController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final firebaseService = Provider.of<FirebaseService>(context);
      _studentsStream = firebaseService.getStudents();
      _productsStream = firebaseService.getProducts();
      _isInitialized = true;
    }
  }

  // Produits express pour ventes "à la va-vite" en cas de rush
  final List<Product> _expressProducts = [
    Product(
      id: '',
      name: 'Café Nespresso (Express)',
      price: 0.50,
      category: ProductCategories.cafe,
      subCategory: ProductCategories.subNespresso,
      trackStock: false,
    ),
    Product(
      id: '',
      name: 'Café Dolce Gusto (Express)',
      price: 0.50,
      category: ProductCategories.cafe,
      subCategory: ProductCategories.subDolceGusto,
      trackStock: false,
    ),
    Product(
      id: '',
      name: 'Thé / Infusion (Express)',
      price: 0.50,
      category: ProductCategories.the,
      subCategory: 'Général',
      trackStock: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Vente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Client'),
            const SizedBox(height: 12),
            _buildStudentSelector(),
            const SizedBox(height: 28),

            _buildSectionTitle('Mode de règlement'),
            const SizedBox(height: 12),
            _buildModernPaymentSelector(),
            if (_paymentMethod == 'Autre') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _otherPaymentController,
                decoration: InputDecoration(
                  labelText: 'Précisez le moyen de paiement',
                  hintText: 'Ex: Chèque, BDA...',
                  prefixIcon: const Icon(Icons.edit_note),
                  fillColor: Colors.white,
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Section Ventes Express (Rush)
            _buildExpressSalesSection(),
            const SizedBox(height: 28),

            // Section Catalogue de dosettes
            _buildSectionTitle('Sélectionner une dosette / variété'),
            const SizedBox(height: 12),
            _buildCategoryFilterChips(),
            const SizedBox(height: 12),
            _buildProductGrid(),
            const SizedBox(height: 32),

            if (_selectedProduct != null) ...[
              _buildSectionTitle('Quantité'),
              const SizedBox(height: 12),
              _buildQuantitySelector(),
              const SizedBox(height: 32),
              _buildCheckoutSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87));
  }

  // --- SECTION VENTES EXPRESS EN CAS DE RUSH ---
  Widget _buildExpressSalesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: Colors.amber.shade900, size: 22),
              const SizedBox(width: 8),
              Text(
                'Vente Express (sans noter le café exact)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'En heure de rush, encaissez directement sans choisir de dosette. L\'inventaire réalignera le stock.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _expressProducts.map((p) {
                  final isSelected = _selectedProduct?.name == p.name;
                  return SizedBox(
                    width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 16) / 3,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedProduct = p;
                          _quantity = 1;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.amber.shade700 : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? Colors.amber.shade800 : Colors.amber.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.shade200.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              p.name.replaceAll(' (Express)', ''),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.price.toStringAsFixed(2)} €',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected ? Colors.white : Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSelector() {
    return StreamBuilder<List<Student>>(
      stream: _studentsStream,
      builder: (context, snapshot) {
        final students = snapshot.data ?? [];
        return InkWell(
          onTap: () async {
            final result = await showSearch<Student?>(context: context, delegate: StudentSearchDelegate(students));
            if (result != null && mounted) setState(() => _selectedStudent = result);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _selectedStudent != null ? Theme.of(context).primaryColor : Colors.grey.shade200, width: 2),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _selectedStudent != null ? Theme.of(context).primaryColor : Colors.grey.shade100,
                  child: Icon(_selectedStudent != null ? Icons.person : Icons.person_search, color: _selectedStudent != null ? Colors.white : Colors.black45),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedStudent?.fullName ?? 'Choisir un étudiant', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                      if (_selectedStudent != null)
                        Text('Solde actuel: ${_selectedStudent!.balance.toStringAsFixed(2)} €', style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black26),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilterChips() {
    return SingleChildScrollView(
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
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedCategoryFilter == label;
    final theme = Theme.of(context);
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: isSelected ? Colors.white : Colors.black87),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
        ],
      ),
      selectedColor: theme.primaryColor,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? theme.primaryColor : Colors.grey.shade300),
      ),
      onSelected: (_) => setState(() => _selectedCategoryFilter = label),
    );
  }

  Widget _buildProductGrid() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1000 ? 5 : (width > 600 ? 4 : 2);

    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allProducts = snapshot.data ?? [];
        final availableProducts = allProducts.where((p) => p.isAvailable).toList();

        final products = availableProducts.where((p) {
          if (_selectedCategoryFilter == 'Nespresso') {
            return p.subCategory == ProductCategories.subNespresso;
          }
          if (_selectedCategoryFilter == 'Dolce Gusto') {
            return p.subCategory == ProductCategories.subDolceGusto;
          }
          if (_selectedCategoryFilter == 'Thé') {
            return p.category == ProductCategories.the;
          }
          return true;
        }).toList();

        if (products.isEmpty && snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Aucun produit disponible dans cette sélection.'),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: width > 600 ? 2.0 : 1.6,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            final isSelected = _selectedProduct?.id == p.id && p.id.isNotEmpty;

            // États de stock
            final isOutOfStock = p.isOutOfStock;
            final needsTransfer = p.needsDeskTransfer;

            return InkWell(
              onTap: () {
                if (isOutOfStock) {
                  showCustomSnackBar(
                    context,
                    message: '${p.name} est en rupture totale (ni au bureau, ni en réserve).',
                    backgroundColor: Colors.red,
                    icon: Icons.cancel,
                  );
                  return;
                }
                if (needsTransfer) {
                  _showPromptTransferDialog(context, p);
                  return;
                }
                setState(() {
                  _selectedProduct = p;
                  _quantity = 1;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isOutOfStock
                      ? Colors.grey.shade100
                      : (isSelected ? Theme.of(context).primaryColor : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : (needsTransfer ? Colors.amber.shade300 : (isOutOfStock ? Colors.grey.shade300 : Colors.grey.shade200)),
                    width: isSelected || needsTransfer ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: width > 600 ? 13 : 12,
                          color: isSelected
                              ? Colors.white
                              : (isOutOfStock ? Colors.grey.shade500 : Colors.black),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.price.toStringAsFixed(2)} €',
                        style: GoogleFonts.poppins(
                          fontSize: width > 600 ? 12 : 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : (isOutOfStock ? Colors.grey.shade400 : Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Badge de stock dynamique
                      _buildStockBadge(p, isSelected),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStockBadge(Product p, bool isSelected) {
    if (!p.trackStock) return const SizedBox.shrink();

    if (p.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Épuisé',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
        ),
      );
    }

    if (p.needsDeskTransfer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.amber.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2, size: 10, color: isSelected ? Colors.white : Colors.amber.shade900),
            const SizedBox(width: 3),
            Text(
              'En réserve (${p.stockReserve})',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.amber.shade900,
              ),
            ),
          ],
        ),
      );
    }

    // Stock bureau OK
    final isLow = p.isLowStock;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.25)
            : (isLow ? Colors.orange.shade100 : Colors.blue.shade50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${p.stockBureau} dispo',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSelected
              ? Colors.white
              : (isLow ? Colors.orange.shade900 : Colors.blue.shade900),
        ),
      ),
    );
  }

  // Dialogue de transfert rapide si bureau vide lors de la vente
  void _showPromptTransferDialog(BuildContext context, Product p) {
    final boxSize = p.standardBoxSize.clamp(1, p.stockReserve);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Icon(Icons.move_to_inbox, color: Colors.amber.shade800, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Bureau vide')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Il n\'y a plus de ${p.name} au bureau, mais il en reste ${p.stockReserve} en réserve.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'Transférer une boîte (+$boxSize) au bureau maintenant pour débloquer la vente ?',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              try {
                final service = context.read<FirebaseService>();
                await service.transferStock(productId: p.id, quantity: boxSize);

                if (!ctx.mounted) return;
                Navigator.pop(ctx);

                if (mounted) {
                  setState(() {
                    _selectedProduct = p;
                    _quantity = 1;
                  });
                  showCustomSnackBar(
                    context,
                    message: 'Boîte de $boxSize dosette(s) transférée au bureau.',
                    backgroundColor: Colors.green,
                    icon: Icons.check_circle,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  showCustomSnackBar(context, message: 'Erreur transfert : $e', backgroundColor: Colors.red);
                }
              }
            },
            child: Text('Transférer +$boxSize et vendre'),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPaymentSelector() {
    final methods = ['Crédit', 'Espèces', 'Lydia', 'Autre'];
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: methods.map((m) {
              final isSelected = _paymentMethod == m;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _paymentMethod = m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)] : [],
                    ),
                    child: Center(
                      child: Text(
                        m,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: constraints.maxWidth < 400 ? 11 : 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildQuantitySelector() {
    final maxAvailable = (_selectedProduct != null && _selectedProduct!.trackStock)
        ? _selectedProduct!.stockBureau
        : 999;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 32,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 24),
            Text(
              '$_quantity',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 24),
            IconButton(
              onPressed: (_quantity < maxAvailable) ? () => setState(() => _quantity++) : null,
              icon: const Icon(Icons.add_circle_outline),
              iconSize: 32,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
        if (_selectedProduct != null && _selectedProduct!.trackStock && _quantity >= maxAvailable && maxAvailable > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Stock bureau maximum atteint ($maxAvailable dispo)',
              style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckoutSection() {
    final total = (_selectedProduct?.price ?? 0.0) * _quantity;
    final canProcess = _selectedStudent != null && _selectedProduct != null;
    final navigator = Navigator.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.poppins(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w500)),
              Text('${total.toStringAsFixed(2)} €', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            ],
          ),
          const SizedBox(height: 24),
          _isProcessing
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: canProcess ? () => _processSale(navigator) : null,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                  child: const Text('CONFIRMER L\'ACHAT'),
                ),
        ],
      ),
    );
  }

  Future<void> _processSale(NavigatorState navigator) async {
    if (_selectedStudent == null || _selectedProduct == null) return;

    // Vérification de la connexion Internet
    final firebaseService = context.read<FirebaseService>();
    final isConnected = await firebaseService.isConnected();

    if (!mounted) return;
    if (!isConnected) {
      showCustomSnackBar(
        context,
        message: 'Aucune connexion Internet. Transaction impossible.',
        backgroundColor: Colors.orange,
        icon: Icons.wifi_off,
      );
      return;
    }

    setState(() => _isProcessing = true);
    final totalPrice = _selectedProduct!.price * _quantity;

    if (_paymentMethod == 'Crédit' && _selectedStudent!.balance < totalPrice) {
      setState(() => _isProcessing = false);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
              const SizedBox(width: 12),
              const Expanded(child: Text('Solde insuffisant', overflow: TextOverflow.visible)),
            ],
          ),
          content: Text(
            'Le solde de ${_selectedStudent!.fullName} va devenir négatif (${(_selectedStudent!.balance - totalPrice).toStringAsFixed(2)} €).\nVoulez-vous quand même valider cette vente ?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Valider'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        return;
      }
      if (!mounted) return;
      setState(() => _isProcessing = true);
    }

    try {
      if (!mounted) return;
      final user = Provider.of<AppUser?>(context, listen: false);

      String finalPaymentMethod = _paymentMethod;
      if (_paymentMethod == 'Autre') {
        final reason = _otherPaymentController.text.trim();
        finalPaymentMethod = 'Autre${reason.isNotEmpty ? " ($reason)" : ""}';
      }

      final transaction = CafeTransaction(
        id: '',
        studentId: _selectedStudent!.id,
        studentName: _selectedStudent!.fullName,
        responsibleId: user?.id ?? 'unknown',
        responsibleName: user?.displayName ?? user?.email ?? 'Anonyme',
        amount: _quantity.toDouble(),
        price: totalPrice,
        type: TransactionType.purchase,
        paymentMethod: finalPaymentMethod,
        productId: _selectedProduct!.id.isNotEmpty ? _selectedProduct!.id : null,
        productName: _selectedProduct!.name,
        timestamp: DateTime.now(),
      );

      await firebaseService.addTransaction(transaction);

      if (!mounted) return;

      // Affichage d'une popup de succès
      final shouldStay = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 30),
              const SizedBox(width: 12),
              const Expanded(child: Text('Vente Validée', overflow: TextOverflow.visible)),
            ],
          ),
          content: Text(
            'La vente de ${_selectedProduct!.name} (x$_quantity) pour ${_selectedStudent!.fullName} a été enregistrée avec succès.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Retour à l\'accueil'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Nouvelle Vente'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      // Réinitialiser l'état local
      setState(() {
        _selectedProduct = null;
        _selectedStudent = null;
        _quantity = 1;
      });

      if (shouldStay != true) {
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          context.read<TabProvider>().setTab(0);
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          message: 'Erreur : $e',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
