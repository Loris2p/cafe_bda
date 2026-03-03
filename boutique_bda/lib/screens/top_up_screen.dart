import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../models/transaction.dart';
import '../services/firebase_service.dart';
import '../widgets/student_search_delegate.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  Student? _selectedStudent;
  final TextEditingController _amountController = TextEditingController();
  String _paymentMethod = 'Espèces';
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créditer un compte'),
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

            const Text('2. Montant du rechargement', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildAmountPresets(),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Montant personnalisé (€)',
                prefixIcon: const Icon(Icons.euro),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            const Text('3. Mode de règlement', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildPaymentSelector(),
            const SizedBox(height: 40),

            _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _processTopUp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('VALIDER LE RECHARGEMENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
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
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(_selectedStudent?.fullName ?? 'Choisir un étudiant'),
            subtitle: _selectedStudent != null ? Text('Solde actuel: ${_selectedStudent!.balance.toStringAsFixed(2)} €') : null,
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

  Widget _buildAmountPresets() {
    final presets = [5, 10, 20, 50];
    return Wrap(
      spacing: 10,
      children: presets.map((amt) => ActionChip(
        label: Text('$amt €'),
        onPressed: () => setState(() => _amountController.text = amt.toString()),
        backgroundColor: _amountController.text == amt.toString() ? Colors.blue.shade100 : null,
      )).toList(),
    );
  }

  Widget _buildPaymentSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'Espèces', label: Text('Espèces')),
        ButtonSegment(value: 'Lydia', label: Text('Lydia')),
        ButtonSegment(value: 'Virement', label: Text('Virement')),
      ],
      selected: {_paymentMethod},
      onSelectionChanged: (val) => setState(() => _paymentMethod = val.first),
    );
  }

  Future<void> _processTopUp() async {
    final amount = double.tryParse(_amountController.text);
    if (_selectedStudent == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs correctement.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = context.read<User?>();
      final transaction = CafeTransaction(
        id: '',
        studentId: _selectedStudent!.id,
        studentName: _selectedStudent!.fullName,
        responsibleId: user?.uid ?? 'unknown',
        responsibleName: user?.displayName ?? 'Anonyme',
        amount: amount,
        price: amount,
        type: TransactionType.topUp,
        paymentMethod: _paymentMethod,
        timestamp: DateTime.now(),
      );

      await context.read<FirebaseService>().addTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte crédité avec succès !'), backgroundColor: Colors.green),
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
