import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/student.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/app_user.dart';
import '../services/firebase_service.dart';
import '../widgets/student_search_delegate.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  Student? _selectedStudent;
  Product? _selectedProduct;
  String _paymentMethod = 'Crédit';
  bool _isProcessing = false;

  late Stream<List<Student>> _studentsStream;
  late Stream<List<Product>> _productsStream;
  bool _isInitialized = false;

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
            const SizedBox(height: 32),

            _buildSectionTitle('Sélectionner un produit'),
            const SizedBox(height: 12),
            _buildProductGrid(),
            const SizedBox(height: 32),

            if (_selectedProduct != null) ...[
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
                      Text(_selectedStudent?.fullName ?? 'Choisir un membre', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            final isSelected = _selectedProduct?.id == p.id;

            return InkWell(
              onTap: () => setState(() => _selectedProduct = p),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200, 
                    width: 1.5
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      p.name, 
                      textAlign: TextAlign.center, 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, 
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black,
                      )
                    ),
                    Text(
                      '${p.price.toStringAsFixed(2)} €', 
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600, 
                        color: isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.black54
                      )
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernPaymentSelector() {
    final methods = ['Crédit', 'Espèces', 'Lydia'];
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)] : [],
                ),
                child: Center(child: Text(m, style: GoogleFonts.poppins(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Theme.of(context).primaryColor : Colors.black45))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCheckoutSection() {
    final total = _selectedProduct?.price ?? 0.0;
    final canProcess = _selectedStudent != null && _selectedProduct != null;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
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
                  onPressed: canProcess ? () => _processSale(scaffoldMessenger, navigator) : null,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
                  child: const Text('CONFIRMER L\'ACHAT'),
                ),
        ],
      ),
    );
  }

  Future<void> _processSale(ScaffoldMessengerState scaffoldMessenger, NavigatorState navigator) async {
    if (_selectedStudent == null || _selectedProduct == null) return;
    if (_paymentMethod == 'Crédit' && _selectedStudent!.balance < _selectedProduct!.price) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Solde insuffisant !'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final user = context.read<AppUser?>();
      final transaction = CafeTransaction(
        id: '',
        studentId: _selectedStudent!.id,
        studentName: _selectedStudent!.fullName,
        responsibleId: user?.id ?? 'unknown',
        responsibleName: user?.displayName ?? user?.email ?? 'Anonyme',
        amount: 1,
        price: _selectedProduct!.price,
        type: TransactionType.purchase,
        paymentMethod: _paymentMethod,
        productName: _selectedProduct!.name,
        timestamp: DateTime.now(),
      );

      await context.read<FirebaseService>().addTransaction(transaction);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Vente réussie !'), backgroundColor: Colors.green));
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
