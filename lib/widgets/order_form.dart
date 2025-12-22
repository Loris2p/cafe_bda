import 'package:cafe_bda/widgets/student_search_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formulaire pour saisir une nouvelle commande de café.
///
/// Ce widget permet de :
/// * Sélectionner un étudiant.
/// * Choisir un café parmi les stocks disponibles (filtrés dynamiquement).
/// * Définir la quantité (max 10).
/// * Choisir le moyen de paiement (y compris Crédit).
class OrderForm extends StatefulWidget {
  /// Données étudiants pour la recherche.
  final List<List<dynamic>> studentsData;
  
  /// Données de stock pour lister les cafés disponibles.
  final List<List<dynamic>> stockData;
  
  /// Callback de soumission. Retourne null si succès, ou un message d'erreur.
  final Future<String?> Function(Map<String, dynamic>) onSubmit;

  const OrderForm({
    super.key,
    required this.studentsData,
    required this.stockData,
    required this.onSubmit,
  });

  @override
  OrderFormState createState() => OrderFormState();
}

class OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _coffeeCountController = TextEditingController();

  Map<String, dynamic> _selectedStudent = {};
  String? _selectedCoffee;
  String? _selectedPaymentMethod;
  bool _isLoading = false;

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
    // Initialise avec la date et l'heure actuelles
    _dateController.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    _coffeeCountController.text = '1'; // Default to 1 coffee
  }

  @override
  void dispose() {
    _dateController.dispose();
    _coffeeCountController.dispose();
    super.dispose();
  }

  /// Filtre les stocks pour ne proposer que les cafés disponibles.
  List<String> get _availableCoffees {
    if (widget.stockData.isEmpty || widget.stockData.length < 2) return [];
    
    // On suppose que la colonne 0 est le nom et la colonne 1 la disponibilité (booléen).
    return widget.stockData
        .skip(1)
        .where((row) {
          if (row.length >= 2) {
            final dynamic stockValue = row[1];
            // Gère à la fois les vrais booléens et les chaînes "true"
            if (stockValue is bool) {
              return stockValue;
            }
            return stockValue?.toString().toLowerCase() == 'true';
          }
          return false;
        })
        .map((row) => row[0]?.toString() ?? '')
        .where((name) => name.isNotEmpty) // Exclure les cafés sans nom
        .toList();
  }

  /// Ouvre le dialogue de recherche d'étudiant.
  Future<void> _openStudentSearch() async {
    final student = await showDialog<List<dynamic>>(
      context: context,
      builder: (context) =>
          StudentSearchDialog(students: widget.studentsData),
    );

    if (student != null) {
      setState(() {
        _selectedStudent = {
          'Numéro étudiant': student[2],
          'Nom': student[0],
          'Prenom': student[1],
          'Classe + Groupe': student[3],
        };
      });
    }
  }

  /// Valide et soumet la commande.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validations manuelles
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

    setState(() {
      _isLoading = true;
    });

    try {
      final formData = {
        'Date': _dateController.text,
        'Moyen Paiement': _selectedPaymentMethod!,
        'Nom de famille': _selectedStudent['Nom'] ?? '',
        'Prénom': _selectedStudent['Prenom'] ?? '',
        'Numéro étudiant': _selectedStudent['Numéro étudiant'],
        'Nb de Cafés': int.parse(_coffeeCountController.text),
        'Café pris': _selectedCoffee!,
      };
      
      final error = await widget.onSubmit(formData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (error == null) {
          // Succès
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Succès'),
              content: const Text('La commande a bien été enregistrée.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                )
              ],
            ),
          );

          // Reset form fields but keep date updated
          setState(() {
            _selectedStudent = {};
            _selectedCoffee = null;
            _selectedPaymentMethod = null;
            _coffeeCountController.text = '1';
            _dateController.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
          });
        } else {
          // Erreur retournée par le provider
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de soumission: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final content = Form(
          key: _formKey,
          child: isDesktop
              ? _buildDesktopLayout()
              : _buildMobileLayout(),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
              child: content,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nouvelle commande', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        _buildDateSection(),
        const SizedBox(height: 16),
        _buildStudentSection(),
        const SizedBox(height: 16),
        _buildStudentInfo(),
        const SizedBox(height: 16),
        _buildCoffeeSection(),
        const SizedBox(height: 16),
        _buildQuantitySection(),
        const SizedBox(height: 16),
        _buildPaymentSection(),
        const SizedBox(height: 24),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nouvelle commande', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colonne Gauche : Infos Étudiant
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDateSection(),
                  const SizedBox(height: 24),
                  _buildStudentSection(),
                  const SizedBox(height: 24),
                  _buildStudentInfo(),
                ],
              ),
            ),
            const SizedBox(width: 48),
            // Colonne Droite : Commande
            Expanded(
              flex: 5,
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Détails de la commande', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 24),
                      _buildCoffeeSection(),
                      const SizedBox(height: 16),
                      _buildQuantitySection(),
                      const SizedBox(height: 24),
                      _buildPaymentSection(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return TextFormField(
      controller: _dateController,
      decoration: const InputDecoration(
        labelText: 'Date et Heure *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (date == null) return;
        
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(now),
        );
        if (time == null) return;

        final newDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        _dateController.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(newDate);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'La date et heure sont obligatoires';
        }
        return null;
      },
    );
  }

  Widget _buildStudentSection() {
    return FormField<Map<String, dynamic>>(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner un étudiant';
        }
        return null;
      },
      builder: (FormFieldState<Map<String, dynamic>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _openStudentSearch,
              icon: const Icon(Icons.search),
              label: const Text('Rechercher un étudiant'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
      initialValue: _selectedStudent,
    );
  }

  Widget _buildStudentInfo() {
    if (_selectedStudent.isEmpty) return const SizedBox.shrink();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 48, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${_selectedStudent['Nom']} ${_selectedStudent['Prenom']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Classe: ${_selectedStudent['Classe + Groupe']}', style: Theme.of(context).textTheme.bodyLarge),
                Text('Numéro: ${_selectedStudent['Numéro étudiant']}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Positioned(
             top: 0,
             right: 0,
             child: IconButton(
               icon: const Icon(Icons.close),
               onPressed: _isLoading ? null : () => setState(() => _selectedStudent = {}),
             ),
          )
        ],
      ),
    );
  }

  Widget _buildCoffeeSection() {
    return Column(
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
            initialValue: _selectedCoffee,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              prefixIcon: Icon(Icons.coffee),
            ),
            items: _availableCoffees.map((String coffee) {
              return DropdownMenuItem<String>(
                value: coffee,
                child: Text(coffee),
              );
            }).toList(),
            onChanged: _isLoading ? null : (String? newValue) {
              setState(() {
                _selectedCoffee = newValue;
              });
            },
            validator: (value) => value == null
                ? 'Veuillez sélectionner un café'
                : null,
          ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return TextFormField(
      controller: _coffeeCountController,
      decoration: const InputDecoration(
        labelText: 'Nombre de cafés *',
        hintText: 'Ex: 2',
        border: OutlineInputBorder(),
        suffixText: 'cafés',
        prefixIcon: Icon(Icons.numbers),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      enabled: !_isLoading,
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
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Moyen de paiement *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _paymentMethods.map((method) {
            return FilterChip(
              label: Text(method),
              selected: _selectedPaymentMethod == method,
              onSelected: _isLoading ? null : (selected) => setState(
                () =>
                    _selectedPaymentMethod = selected ? method : null,
              ),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
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
    );
  }

  Widget _buildSubmitButton() {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _submitForm,
            icon: const Icon(Icons.check),
            label: const Text('Enregistrer la commande'),
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        );
  }
}