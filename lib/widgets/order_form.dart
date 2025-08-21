import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrderForm extends StatefulWidget {
  final List<List<dynamic>> studentsData;
  final List<List<dynamic>> stockData;
  final Function(Map<String, dynamic>) onSubmit;
  final Function() onCancel;

  const OrderForm({
    super.key,
    required this.studentsData,
    required this.stockData,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  OrderFormState createState() => OrderFormState();
}

class OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdFocusNode = FocusNode();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _coffeeCountController = TextEditingController();

  String _selectedStudentId = '';
  Map<String, dynamic> _selectedStudent = {};
  String? _selectedCoffee;
  String? _selectedPaymentMethod;

  final List<String> _paymentMethods = [
    'Crédit',
    'Lydia',
    'Échange',
    'Espèce',
    'Virement',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _studentIdFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _studentIdFocusNode.dispose();
    _studentIdController.dispose();
    _dateController.dispose();
    _coffeeCountController.dispose();
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

  List<String> get _availableCoffees {
    if (widget.stockData.isEmpty || widget.stockData.length < 2) return [];
    return widget.stockData
        .skip(1)
        .where((row) {
          if (row.length >= 2) {
            final quantity = int.tryParse(row[1]?.toString() ?? '0') ?? 0;
            return quantity > 0;
          }
          return false;
        })
        .map((row) => row[0]?.toString() ?? '')
        .toList();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un étudiant')),
      );
      return;
    }
    if (_selectedCoffee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un café')),
      );
      return;
    }
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un moyen de paiement'),
        ),
      );
      return;
    }

    try {
      final formData = {
        'Date': _dateController.text,
        'Moyen Paiement': _selectedPaymentMethod!,
        'Nom de famille': _selectedStudent['Nom'] ?? '',
        'Prénom': _selectedStudent['Prenom'] ?? '',
        'Numéro étudiant': _selectedStudentId,
        'Nb de Cafés': int.parse(_coffeeCountController.text),
        'Café pris': _selectedCoffee!,
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
      title: const Text('Nouvelle commande'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date et heure
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date et heure *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La date et heure sont obligatoires';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Numéro étudiant
              TextFormField(
                focusNode: _studentIdFocusNode,
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
                        Text('Numéro: ${_selectedStudent['Numéro étudiant']}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Sélection du café
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Café choisi *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_availableCoffees.isEmpty)
                      const Text(
                        'Aucun café en stock',
                        style: TextStyle(color: Colors.red),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedCoffee,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: _availableCoffees.map((String coffee) {
                          return DropdownMenuItem<String>(
                            value: coffee,
                            child: Text(coffee),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCoffee = newValue;
                          });
                        },
                        validator: (value) => value == null
                            ? 'Veuillez sélectionner un café'
                            : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Nombre de cafés
              TextFormField(
                controller: _coffeeCountController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de cafés *',
                  hintText: 'Ex: 2',
                  border: OutlineInputBorder(),
                  suffixText: 'cafés',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nombre de cafés est obligatoire';
                  }
                  final count = int.tryParse(value);
                  if (count == null || count <= 0) {
                    return 'Veuillez saisir un nombre valide (> 0)';
                  }
                  if (count > 10) {
                    return 'Le nombre maximum est 10';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Moyen de paiement
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Moyen de paiement *',
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
                        onSelected: (selected) => setState(
                          () =>
                              _selectedPaymentMethod = selected ? method : null,
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
