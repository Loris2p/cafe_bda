import 'package:flutter/material.dart';

/// Un dialogue pour configurer les paramètres généraux de l'application.
class AppSettingsDialog extends StatefulWidget {
  /// La liste des noms de colonnes.
  final List<dynamic> columnNames;

  /// La liste des états de visibilité actuels pour chaque colonne.
  final List<bool> visibility;

  /// Le nom actuel du responsable.
  final String? responsableName;

  /// Callback appelé lorsqu'un interrupteur de visibilité est basculé.
  final Function(int, bool) onVisibilityChanged;
  
  /// Callback appelé lors de la sauvegarde du nom du responsable.
  final Function(String) onResponsableNameSaved;

  const AppSettingsDialog({
    super.key,
    required this.columnNames,
    required this.visibility,
    required this.responsableName,
    required this.onVisibilityChanged,
    required this.onResponsableNameSaved,
  });

  @override
  State<AppSettingsDialog> createState() => _AppSettingsDialogState();
}

class _AppSettingsDialogState extends State<AppSettingsDialog> {
  late final TextEditingController _responsableController;

  @override
  void initState() {
    super.initState();
    _responsableController = TextEditingController(text: widget.responsableName);
  }

  @override
  void dispose() {
    _responsableController.dispose();
    super.dispose();
  }

  void _saveResponsableName() {
    widget.onResponsableNameSaved(_responsableController.text);
    // Optionnel: afficher un feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nom du responsable enregistré !'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paramètres'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Section Nom du Responsable
              Text('Responsable par défaut', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _responsableController,
                decoration: const InputDecoration(
                  labelText: 'Votre nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _saveResponsableName,
                  child: const Text('Enregistrer'),
                ),
              ),
              const Divider(height: 32),

              // Section Visibilité des colonnes
              Text('Visibilité des colonnes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Le parent est déjà scrollable
                itemCount: widget.columnNames.length,
                itemBuilder: (context, index) {
                  return SwitchListTile(
                    title: Text(widget.columnNames[index]?.toString() ?? 'Colonne ${index + 1}'),
                    value: widget.visibility.length > index ? widget.visibility[index] : true,
                    onChanged: (bool value) {
                      widget.onVisibilityChanged(index, value);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Fermer'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
