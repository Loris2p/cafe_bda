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
            const SizedBox(height: 32),

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
            const SizedBox(height: 32),

            _buildSectionTitle('Sélectionner un produit'),
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
      }
    );
  }

  Widget _buildProductGrid() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1000 ? 5 : (width > 600 ? 4 : 2);
    
    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final allProducts = snapshot.data ?? [];
        final products = allProducts.where((p) => p.isAvailable).toList();

        if (products.isEmpty && snapshot.hasData) {
          return const Center(child: Text('Aucun produit disponible en stock.'));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: width > 600 ? 2.2 : 1.8,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            final isSelected = _selectedProduct?.id == p.id;

            return InkWell(
              onTap: () => setState(() => _selectedProduct = p),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.white,
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
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200, 
                    width: 2
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
                          color: isSelected ? Colors.white : Colors.black,
                          height: 1.2,
                        )
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.price.toStringAsFixed(2)} €', 
                        style: GoogleFonts.poppins(
                          fontSize: width > 600 ? 12 : 11,
                          fontWeight: FontWeight.w600, 
                          color: isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.black54
                        )
                      ),
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
                          color: isSelected ? Theme.of(context).primaryColor : Colors.black45
                        )
                      )
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }
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
        // Navigation sécurisée vers l'accueil
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

  Widget _buildQuantitySelector() {
    return Row(
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
          onPressed: () => setState(() => _quantity++),
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 32,
          color: Theme.of(context).primaryColor,
        ),
      ],
    );
  }
}
