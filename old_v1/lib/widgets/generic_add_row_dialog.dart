import 'package:flutter/material.dart';

class GenericAddRowDialog extends StatefulWidget {
  final List<String> columnNames;
  final String tableName;

  const GenericAddRowDialog({
    super.key,
    required this.columnNames,
    required this.tableName,
  });

  @override
  State<GenericAddRowDialog> createState() => _GenericAddRowDialogState();
}

class _GenericAddRowDialogState extends State<GenericAddRowDialog> {
  late final List<TextEditingController> _controllers;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.columnNames.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ajouter une ligne - ${widget.tableName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Remplissez les champs ci-dessous pour ajouter une nouvelle entrée.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < widget.columnNames.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TextFormField(
                      controller: _controllers[i],
                      decoration: InputDecoration(
                        labelText: widget.columnNames[i],
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: _getKeyboardType(widget.columnNames[i]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final rowData = _controllers.map((c) => c.text).toList();
              Navigator.pop(context, rowData);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  TextInputType _getKeyboardType(String columnName) {
    final lower = columnName.toLowerCase();
    if (lower.contains('prix') || 
        lower.contains('quantité') || 
        lower.contains('nb') || 
        lower.contains('valeur') ||
        lower.contains('montant') ||
        lower.contains('solde')) {
      return TextInputType.number;
    }
    if (lower.contains('date')) {
      return TextInputType.datetime;
    }
    if (lower.contains('téléphone') || lower.contains('tel')) {
      return TextInputType.phone;
    }
    return TextInputType.text;
  }
}
