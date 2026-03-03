import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/app_user.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passer une vente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('1. Sélectionner l\'étudiant', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildStudentSelector(firebaseService),
            const SizedBox(height: 24),

            const Text('2. Choisir le produit', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildProductGrid(firebaseService),
            const SizedBox(height: 24),

            if (_selectedProduct != null) ...[
              const Text('3. Mode de règlement', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPaymentSelector(),
              const SizedBox(height: 32),
              _buildCheckoutSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSelector(FirebaseService service) {
    return StreamBuilder<List<Student>>(
      stream: service.getStudents(),
      builder: (context, snapshot) {
        final students = snapshot.data ?? [];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _selectedStudent == null ? Colors.grey : Colors.deepPurple,
              child: Icon(_selectedStudent == null ? Icons.person_outline : Icons.person, color: Colors.white),
            ),
            title: Text(_selectedStudent?.fullName ?? 'Cliquer pour choisir un étudiant'),
            subtitle: _selectedStudent != null ? Text('Solde actuel: ${_selectedStudent!.balance.toStringAsFixed(2)} €') : null,
            trailing: const Icon(Icons.search),
            onTap: () async {
              final result = await showSearch<Student?>(
                context: context,
                delegate: StudentSearchDelegate(students),
              );
              if (result != null) setState(() => _selectedStudent = result);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductGrid(FirebaseService service) {
    return StreamBuilder<List<Product>>(
      stream: service.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(child: Text('Aucun produit disponible.'));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            final isSelected = _selectedProduct?.id == p.id;
            return InkWell(
              onTap: p.isAvailable ? () => setState(() => _selectedProduct = p) : null,
              child: Opacity(
                opacity: p.isAvailable ? 1.0 : 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurple.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? Colors.deepPurple : Colors.grey.shade300, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${p.price.toStringAsFixed(2)} €'),
                      if (!p.isAvailable) const Text('Indisponible', style: TextStyle(color: Colors.red, fontSize: 10)),
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

  Widget _buildPaymentSelector() {
    final methods = ['Crédit', 'Espèces', 'Lydia'];
    return SegmentedButton<String>(
      segments: methods.map((m) => ButtonSegment(value: m, label: Text(m))).toList(),
      selected: {_paymentMethod},
      onSelectionChanged: (val) => setState(() => _paymentMethod = val.first),
    );
  }

  Widget _buildCheckoutSection() {
    final canValidate = _selectedStudent != null && _selectedProduct != null;
    final total = _selectedProduct?.price ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total à payer :', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${total.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            ],
          ),
          const SizedBox(height: 16),
          _isProcessing
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: canValidate ? _processSale : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('VALIDER LA VENTE'),
                ),
        ],
      ),
    );
  }

  Future<void> _processSale() async {
    if (_selectedStudent == null || _selectedProduct == null) return;

    if (_paymentMethod == 'Crédit' && _selectedStudent!.balance < _selectedProduct!.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solde insuffisant !'), backgroundColor: Colors.red),
      );
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vente enregistrée avec succès !'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
