import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum EditType {
  text,
  numeric,
  date,
  dropdown,
}

class EditCellDialog extends StatefulWidget {
  final String initialValue;
  final EditType editType;
  final List<String>? dropdownOptions;

  const EditCellDialog({
    super.key,
    required this.initialValue,
    this.editType = EditType.text,
    this.dropdownOptions,
  });

  @override
  State<EditCellDialog> createState() => _EditCellDialogState();
}

class _EditCellDialogState extends State<EditCellDialog> {
  late TextEditingController _textController;
  String? _selectedDropdownValue;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);

    if (widget.editType == EditType.dropdown && widget.dropdownOptions != null) {
      if (widget.dropdownOptions!.contains(widget.initialValue)) {
        _selectedDropdownValue = widget.initialValue;
      } else if (widget.dropdownOptions!.isNotEmpty) {
        _selectedDropdownValue = widget.dropdownOptions!.first;
      }
    }

    if (widget.editType == EditType.date) {
      _parseInitialDate();
    }
  }

  void _parseInitialDate() {
    try {
      // Tente de parser différents formats
      final formats = [
        DateFormat('dd/MM/yyyy'),
        DateFormat('yyyy-MM-dd'),
      ];
      
      for (var format in formats) {
         try {
           _selectedDate = format.parseLoose(widget.initialValue);
           break;
         } catch (_) {}
      }
      
      _selectedDate ??= DateTime.now();
    } catch (_) {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (widget.editType) {
      case EditType.numeric:
        content = TextField(
          controller: _textController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Valeur numérique',
            border: OutlineInputBorder(),
          ),
        );
        break;

      case EditType.date:
        content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(_selectedDate != null 
                ? DateFormat('dd/MM/yyyy').format(_selectedDate!) 
                : 'Sélectionner une date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ],
        );
        break;

      case EditType.dropdown:
        content = InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Sélectionner une valeur',
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDropdownValue,
              isDense: true,
              items: widget.dropdownOptions?.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList() ?? [],
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDropdownValue = newValue;
                });
              },
            ),
          ),
        );
        break;

      default:
        content = TextField(
          controller: _textController,
          keyboardType: TextInputType.text,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Valeur texte',
            border: OutlineInputBorder(),
          ),
        );
        break;
    }

    return AlertDialog(
      title: const Text('Modifier la cellule'),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            dynamic finalValue;
            switch (widget.editType) {
              case EditType.numeric:
                finalValue = num.tryParse(_textController.text.replaceAll(',', '.')) ?? _textController.text;
                break;
              case EditType.date:
                finalValue = _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : widget.initialValue;
                break;
              case EditType.dropdown:
                finalValue = _selectedDropdownValue ?? widget.initialValue;
                break;
              default:
                finalValue = _textController.text;
                break;
            }
            Navigator.pop(context, finalValue);
          },
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
