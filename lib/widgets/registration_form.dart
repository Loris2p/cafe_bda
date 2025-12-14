import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formulaire d'inscription d'un nouvel étudiant.
///
/// Ce widget affiche un dialogue avec les champs nécessaires :
/// * Nom
/// * Prénom
/// * Numéro étudiant (avec validation numérique)
/// * Cycle/Classe (via des ChoiceChips)
///
/// Retourne les données saisies via le callback [onSubmit].
class RegistrationForm extends StatefulWidget {
  /// Fonction appelée lorsque le formulaire est valide et soumis.
  final Function(Map<String, dynamic>) onSubmit;
  
  /// Fonction appelée lors de l'annulation.
  final Function() onCancel;
  
  /// Données initiales optionnelles pour pré-remplir le formulaire.
  final Map<String, dynamic>? initialData;

  const RegistrationForm({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    this.initialData,
  });

  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomFocusNode = FocusNode();
  
  // Stockage local des données du formulaire
  final Map<String, dynamic> _formData = {
    'Nom': '',
    'Prenom': '',
    'Num etudiant': '',
    'Cycle + groupe': '',
  };
  
  String? _selectedClass;
  
  // Liste des classes disponibles (hardcodée pour l'instant)
  final List<String> _primaryClasses = [
    'PréIng 1',
    'Pré Ing 2',
    'Ing 1',
    'Ing 2',
    'Ing 3',
  ];

  @override
  void initState() {
    super.initState();
    // Pré-remplissage si modification
    if (widget.initialData != null) {
      _formData.addAll(widget.initialData!);
      _selectedClass = widget.initialData!['Cycle + groupe'];
    }
    // Focus automatique sur le premier champ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nomFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nomFocusNode.dispose();
    super.dispose();
  }

  /// Construit la liste des champs de formulaire.
  List<Widget> _buildFormFields() {
    return [
      // Champ Nom
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: TextFormField(
          focusNode: _nomFocusNode,
          decoration: const InputDecoration(
            labelText: 'Nom *',
            hintText: 'Ex: Dupont',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom est obligatoire';
            }
            return null;
          },
          onSaved: (value) => _formData['Nom'] = value?.trim() ?? '',
        ),
      ),
      // Champ Prénom
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: TextFormField(
          decoration: const InputDecoration(
            labelText: 'Prénom *',
            hintText: 'Ex: Jean',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le prénom est obligatoire';
            }
            return null;
          },
          onSaved: (value) => _formData['Prenom'] = value?.trim() ?? '',
        ),
      ),
      // Champ Numéro étudiant
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: TextFormField(
          decoration: const InputDecoration(
            labelText: 'Numéro étudiant *',
            hintText: 'Ex: 123456',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le numéro étudiant est obligatoire';
            }
            if (value.length < 6 || value.length > 8) {
              return 'Veuillez entrer un numéro valide (6 à 8 chiffres)';
            }
            return null;
          },
          onSaved: (value) => _formData['Num etudiant'] = value ?? '',
        ),
      ),
      // Sélecteur Cycle + groupe (Chips)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cycle + groupe *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _primaryClasses.map((className) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(className),
                      selected: _selectedClass == className,
                      onSelected: (selected) {
                        setState(() {
                          _selectedClass = selected ? className : null;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_selectedClass == null)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  'Ce champ est obligatoire',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  /// Valide et soumet le formulaire.
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClass == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une classe')),
        );
        return;
      }
      _formKey.currentState!.save();
      final processedData = Map<String, dynamic>.from(_formData);
      
      // Conversion type sécurisée
      processedData['Num etudiant'] = int.parse(
        _formData['Num etudiant'].toString(),
      );
      processedData['Cycle + groupe'] = _selectedClass!;
      
      widget.onSubmit(processedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle inscription'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildFormFields(),
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