import 'package:cafe_bda/widgets/student_search_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formulaire pour créditer le compte d'un étudiant (Rechargement).
///
/// Permet de :
/// * Rechercher et sélectionner un étudiant.
/// * Saisir un montant ou un nombre de cafés (conversion automatique).
/// * Choisir le moyen de paiement (Lydia, Espèce, etc.).
class CreditForm extends StatefulWidget {
  /// La liste complète des étudiants pour la recherche.
  final List<List<dynamic>> studentsData;
  
  /// Callback appelé lors de la soumission valide. Retourne null si succès.
  final Future<String?> Function(Map<String, dynamic>) onSubmit;

  /// Le nom initial à pré-remplir pour le champ "Responsable".
  final String? initialResponsableName;

  const CreditForm({
    super.key,
    required this.studentsData,
    required this.onSubmit,
    this.initialResponsableName,
  });

  @override
  _CreditFormState createState() => _CreditFormState();
}

class _CreditFormState extends State<CreditForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs de texte
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _responsibleController = TextEditingController();
  final TextEditingController _coffeeCountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _otherPaymentController = TextEditingController();

  Map<String, dynamic> _selectedStudent = {};
  bool _isLoading = false;
  
  // Prix unitaire du café (pour conversion automatique)
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
    // Pré-remplissage avec la date du jour et le nom du responsable
    _dateController.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    _responsibleController.text = widget.initialResponsableName ?? '';
  }

  @override
  void dispose() {
    _dateController.dispose();
    _responsibleController.dispose();
    _coffeeCountController.dispose();
    _amountController.dispose();
    _otherPaymentController.dispose();
    super.dispose();
  }

  /// Calcule le montant en € en fonction du nombre de cafés saisis.
  void _calculateAmountFromCoffee() {
    try {
      final coffeeCount = double.tryParse(_coffeeCountController.text) ?? 0;
      _amountController.text = (coffeeCount * _coffeePrice).toStringAsFixed(2);
    } catch (e) {
      debugPrint('Erreur de calcul montant: $e');
      _amountController.clear();
    }
  }

  /// Calcule le nombre de cafés en fonction du montant en € saisi.
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

  /// Ouvre la boîte de dialogue de recherche d'étudiant.
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

  /// Valide et soumet le formulaire.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validations manuelles supplémentaires
    if (_selectedStudent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un étudiant'),
        ),
      );
      return;
    }
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

    setState(() => _isLoading = true);

    try {
      final paymentMethod = _selectedPaymentMethod == 'Autre'
          ? _otherPaymentController.text
          : _selectedPaymentMethod!;

      final formData = {
        'Date': _dateController.text,
        'Responsable': _responsibleController.text,
        'Numéro étudiant': _selectedStudent['Numéro étudiant'],
        'Nom': _selectedStudent['Nom'] ?? '',
        'Prenom': _selectedStudent['Prenom'] ?? '',
        'Classe + Groupe': _selectedStudent['Classe + Groupe'] ?? '',
        'Valeur (€)': double.parse(_amountController.text),
        'Nb de Cafés': int.parse(_coffeeCountController.text),
        'Moyen Paiement': paymentMethod,
      };
      
      final error = await widget.onSubmit(formData);

      if (mounted) {
        setState(() => _isLoading = false);

        if (error == null) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Succès'),
              content: const Text('Le crédit a bien été ajouté.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                )
              ],
            ),
          );

          // Reset form
          setState(() {
             _selectedStudent = {};
             _coffeeCountController.clear();
             _amountController.clear();
             _selectedPaymentMethod = null;
             _otherPaymentController.clear();
             _showOtherPaymentField = false;
             // Keep Date and Responsable
          });
        } else {
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
        Text('Créditer un étudiant', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        _buildDateSection(),
        const SizedBox(height: 16),
        _buildResponsibleSection(),
        const SizedBox(height: 16),
        _buildStudentSection(),
        const SizedBox(height: 16),
        _buildStudentInfo(),
        const SizedBox(height: 16),
        _buildCreditDetailsSection(),
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
        Text('Créditer un étudiant', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colonne Gauche : Infos
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   _buildDateSection(),
                   const SizedBox(height: 24),
                   _buildResponsibleSection(),
                   const SizedBox(height: 24),
                   _buildStudentSection(),
                   const SizedBox(height: 24),
                   _buildStudentInfo(),
                ],
              ),
            ),
            const SizedBox(width: 48),
            // Colonne Droite : Crédit
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
                      Text('Détails du rechargement', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 24),
                      _buildCreditDetailsSection(),
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
          return 'La date est obligatoire';
        }
        return null;
      },
    );
  }

  Widget _buildResponsibleSection() {
    return TextFormField(
      controller: _responsibleController,
      decoration: const InputDecoration(
        labelText: 'Responsable *',
        hintText: 'Ex: Dupont',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Le responsable est obligatoire';
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
                Text('N°: ${_selectedStudent['Numéro étudiant']}', style: Theme.of(context).textTheme.bodyMedium),
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

  Widget _buildCreditDetailsSection() {
    return Column(
      children: [
        TextFormField(
          controller: _coffeeCountController,
          decoration: const InputDecoration(
            labelText: 'Nombre de cafés *',
            hintText: 'Ex: 10',
            border: OutlineInputBorder(),
            suffixText: 'cafés',
            prefixIcon: Icon(Icons.coffee),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          enabled: !_isLoading,
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
        TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Montant (€) *',
            hintText: 'Ex: 5.00',
            border: OutlineInputBorder(),
            suffixText: '€',
            prefixIcon: Icon(Icons.euro),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          enabled: !_isLoading,
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
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Moyen de règlement *',
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
              onSelected: _isLoading ? null : (selected) => _handlePaymentMethodChange(
                selected ? method : null,
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
        
        // Champ "Autre" dynamique
        if (_showOtherPaymentField) ...[
          const SizedBox(height: 16),
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
    );
  }

  Widget _buildSubmitButton() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submitForm,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer le crédit'),
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          );
  }
}