import 'package:flutter/material.dart';

/// Un widget pour configurer les paramètres généraux de l'application.
class AppSettingsWidget extends StatefulWidget {
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

  const AppSettingsWidget({
    super.key,
    required this.columnNames,
    required this.visibility,
    required this.responsableName,
    required this.onVisibilityChanged,
    required this.onResponsableNameSaved,
  });

  @override
  State<AppSettingsWidget> createState() => _AppSettingsWidgetState();
}

class _AppSettingsWidgetState extends State<AppSettingsWidget> {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Paramètres de l\'application', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          
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
              child: const Text('Enregistrer le nom'),
            ),
          ),
          const Divider(height: 32),

          // Section Visibilité des colonnes
          Text('Visibilité des colonnes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (widget.columnNames.isEmpty)
             const Text('Aucune colonne à configurer.'),
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
    );
  }
}
