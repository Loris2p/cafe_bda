import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreditForm extends StatefulWidget {
  final List<List<dynamic>> studentsData;
  final Function(Map<String, dynamic>) onSubmit;
  final Function() onCancel;

  const CreditForm({
    super.key,
    required this.studentsData,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  _CreditFormState createState() => _CreditFormState();
}

class _CreditFormState extends State<CreditForm> {
  final _formKey = GlobalKey<FormState>();
  final _dateFocusNode = FocusNode();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _responsibleController = TextEditingController();
  final TextEditingController _coffeeCountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _otherPaymentController = TextEditingController();

  String _selectedStudentId = '';
  Map<String, dynamic> _selectedStudent = {};
  final double _coffeePrice = 0.50;
  final List<String> _paymentMethods = [
    'Lydia',
    'Échange',
    'Espèce',
    'Virement',
    'Autre',
  ];
  String? _selectedPaymentMethod;
  bool _showOtherPaymentField = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text = '${now.day}/${now.month}/${now.year}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dateFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _dateFocusNode.dispose();
    _studentIdController.dispose();
    _dateController.dispose();
    _responsibleController.dispose();
    _coffeeCountController.dispose();
    _amountController.dispose();
    _otherPaymentController.dispose();
    super.dispose();
  }

  void _findStudent(String studentId) {
    if (widget.studentsData.isEmpty || widget.studentsData.length < 2) return;
    final student = widget.studentsData
        .skip(1)
        .firstWhere(
          (row) => row.length > 2 && row[2]?.toString() == studentId,
          orElse: () => [],
        );
    setState(() {
      _selectedStudentId = student.isNotEmpty ? studentId : '';
      _selectedStudent = student.isNotEmpty
          ? {
              'Numéro étudiant': student[2],
              'Nom': student[0],
              'Prenom': student[1],
              'Classe + Groupe': student[3],
            }
          : {};
    });
  }

  void _calculateAmountFromCoffee() {
    try {
      final coffeeCount = double.tryParse(_coffeeCountController.text) ?? 0;
      _amountController.text = (coffeeCount * _coffeePrice).toStringAsFixed(2);
    } catch (e) {
      debugPrint('Erreur de calcul montant: $e');
      _amountController.clear();
    }
  }

  void _calculateCoffeeFromAmount() {
    try {
      final amount = double.tryParse(_amountController.text) ?? 0;
      final coffeeCount = (amount / _coffeePrice).round();
      _coffeeCountController.text = coffeeCount.toString();
    } catch (e) {
      debugPrint('Erreur de calcul cafés: $e');
      _coffeeCountController.clear();
    }
  }

  void _handlePaymentMethodChange(String? method) {
    setState(() {
      _selectedPaymentMethod = method;
      _showOtherPaymentField = method == 'Autre';
      if (!_showOtherPaymentField) {
        _otherPaymentController.clear();
      }
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un moyen de règlement'),
        ),
      );
      return;
    }
    if (_selectedPaymentMethod == 'Autre' &&
        _otherPaymentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez préciser le moyen de règlement'),
        ),
      );
      return;
    }

    try {
      final paymentMethod = _selectedPaymentMethod == 'Autre'
          ? _otherPaymentController.text
          : _selectedPaymentMethod!;

      final formData = {
        'Date': _dateController.text,
        'Responsable': _responsibleController.text,
        'Numéro étudiant': _selectedStudentId,
        'Nom': _selectedStudent['Nom'] ?? '',
        'Prenom': _selectedStudent['Prenom'] ?? '',
        'Classe + Groupe': _selectedStudent['Classe + Groupe'] ?? '',
        'Valeur (€)': double.parse(_amountController.text),
        'Nb de Cafés': int.parse(_coffeeCountController.text),
        'Moyen Paiement': paymentMethod,
      };
      widget.onSubmit(formData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de soumission: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créditer un étudiant'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date
              TextFormField(
                focusNode: _dateFocusNode,
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date (JJ/MM/AAAA) *',
                  hintText: 'Ex: 21/08/2025',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La date est obligatoire';
                  }
                  final parts = value.split('/');
                  if (parts.length != 3) {
                    return 'Format invalide (JJ/MM/AAAA)';
                  }
                  final day = int.tryParse(parts[0]);
                  final month = int.tryParse(parts[1]);
                  final year = int.tryParse(parts[2]);
                  if (day == null || month == null || year == null) {
                    return 'Format invalide (JJ/MM/AAAA)';
                  }
                  if (day < 1 ||
                      day > 31 ||
                      month < 1 ||
                      month > 12 ||
                      year < 2000 ||
                      year > 2100) {
                    return 'Date invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Responsable
              TextFormField(
                controller: _responsibleController,
                decoration: const InputDecoration(
                  labelText: 'Responsable *',
                  hintText: 'Ex: Dupont',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le responsable est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Numéro étudiant
              TextFormField(
                controller: _studentIdController,
                decoration: InputDecoration(
                  labelText: 'Numéro étudiant *',
                  hintText: 'Ex: 123456',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _findStudent(_studentIdController.text),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (_selectedStudentId != value) {
                    setState(() => _selectedStudent = {});
                  }
                },
                onEditingComplete: () =>
                    _findStudent(_studentIdController.text),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le numéro étudiant est obligatoire';
                  }
                  if (_selectedStudent.isEmpty) {
                    return 'Étudiant non trouvé';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Informations étudiant
              if (_selectedStudent.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedStudent['Nom']} ${_selectedStudent['Prenom']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text('Classe: ${_selectedStudent['Classe + Groupe']}'),
                      ],
                    ),
                  ),
                ),
              ],
              // Nombre de cafés
              TextFormField(
                controller: _coffeeCountController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de cafés *',
                  hintText: 'Ex: 10',
                  border: OutlineInputBorder(),
                  suffixText: 'cafés',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => _calculateAmountFromCoffee(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nombre de cafés est obligatoire';
                  }
                  final count = int.tryParse(value);
                  if (count == null || count <= 0) {
                    return 'Veuillez saisir un nombre valide (> 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Montant
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant (€) *',
                  hintText: 'Ex: 5.00',
                  border: OutlineInputBorder(),
                  suffixText: '€',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) => _calculateCoffeeFromAmount(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le montant est obligatoire';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Veuillez saisir un montant valide (> 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Moyen de règlement
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Moyen de règlement *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: _paymentMethods.map((method) {
                      return FilterChip(
                        label: Text(method),
                        selected: _selectedPaymentMethod == method,
                        onSelected: (selected) => _handlePaymentMethodChange(
                          selected ? method : null,
                        ),
                        selectedColor: Colors.blue,
                        checkmarkColor: Colors.white,
                        showCheckmark: true,
                      );
                    }).toList(),
                  ),
                  if (_selectedPaymentMethod == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Ce champ est obligatoire',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              // Champ "Autre"
              if (_showOtherPaymentField) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _otherPaymentController,
                  decoration: const InputDecoration(
                    labelText: 'Précisez le moyen de règlement *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedPaymentMethod == 'Autre' &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser le moyen de règlement';
                    }
                    return null;
                  },
                ),
              ],
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  '1 café = 0,50 €',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
