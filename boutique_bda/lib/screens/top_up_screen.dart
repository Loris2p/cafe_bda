import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/student.dart';
import '../models/transaction.dart';
import '../models/app_user.dart';
import '../services/firebase_service.dart';
import '../widgets/student_search_delegate.dart';
import '../main.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  Student? _selectedStudent;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _otherPaymentController = TextEditingController();
  String _paymentMethod = 'Espèces';
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    _otherPaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Rechargement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Étudiant à créditer'),
            const SizedBox(height: 12),
            _buildStudentSelector(firebaseService),
            const SizedBox(height: 32),

            _buildSectionTitle('Montant'),
            const SizedBox(height: 12),
            _buildAmountPresets(),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Montant personnalisé',
                prefixIcon: const Icon(Icons.euro),
                suffixText: '€',
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Moyen de paiement'),
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
                ),
              ),
            ],
            const SizedBox(height: 48),

            _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _processTopUp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    child: const Text('VALIDER LE RECHARGEMENT'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade700));
  }

  Widget _buildStudentSelector(FirebaseService service) {
    return InkWell(
      onTap: () async {
        final students = await service.getStudents().first;
        if (!mounted) return;
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
              child: Icon(_selectedStudent != null ? Icons.person : Icons.person_search, color: _selectedStudent != null ? Colors.white : Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedStudent?.fullName ?? 'Sélectionner un étudiant', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (_selectedStudent != null)
                    Text('Solde actuel: ${_selectedStudent!.balance.toStringAsFixed(2)} €', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountPresets() {
    final presets = [5, 10, 20, 50];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: presets.map((amt) {
        final isSelected = _amountController.text == amt.toString();
        return InkWell(
          onTap: () => setState(() => _amountController.text = amt.toString()),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200, width: 2),
            ),
            child: Text('$amt €', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernPaymentSelector() {
    final methods = ['Espèces', 'Lydia', 'Virement', 'Autre'];
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
                child: Center(child: Text(m, style: GoogleFonts.poppins(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Theme.of(context).primaryColor : Colors.grey))),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _processTopUp() async {
    final amountText = _amountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(amountText);
    
    if (_selectedStudent == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un étudiant et saisir un montant valide.'), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isProcessing = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
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
        amount: amount,
        price: amount,
        type: TransactionType.topUp,
        paymentMethod: finalPaymentMethod,
        timestamp: DateTime.now(),
      );

      await context.read<FirebaseService>().addTransaction(transaction);
      
      if (!mounted) return;

      // Affichage d'une popup de succès au lieu d'un simple SnackBar
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 12),
              Text('Rechargement Validé'),
            ],
          ),
          content: Text(
            'Le compte de ${_selectedStudent!.fullName} a été crédité de ${amount.toStringAsFixed(2)} € avec succès.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      // Réinitialisation
      setState(() {
        _selectedStudent = null;
        _amountController.clear();
        _otherPaymentController.clear();
      });

      // Navigation sécurisée
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        context.read<TabProvider>().setTab(0);
      }
      
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
