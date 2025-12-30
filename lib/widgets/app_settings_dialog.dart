import 'package:cafe_bda/utils/constants.dart';
import 'package:flutter/material.dart';

/// Un widget pour configurer les paramètres généraux de l'application.
class AppSettingsWidget extends StatefulWidget {
  /// Map des en-têtes pour toutes les tables (Nom Table -> Liste Colonnes).
  final Map<String, List<String>> allHeaders;

  /// Map de visibilité pour toutes les tables (Nom Table -> Liste Visibilité).
  final Map<String, List<bool>> allVisibility;

  /// Le nom actuel du responsable.
  final String? responsableName;

  /// La version de l'application à afficher.
  final String appVersion;

  /// Callback appelé lorsqu'un interrupteur de visibilité est basculé.
  final Function(String tableName, int colIndex, bool isVisible) onVisibilityChanged;
  
  /// Callback appelé lors de la sauvegarde du nom du responsable.
  final Function(String) onResponsableNameSaved;

  /// Callback appelé pour révoquer l'accès (changement de compte).
  final VoidCallback? onRevokeAccess;

  const AppSettingsWidget({
    super.key,
    required this.allHeaders,
    required this.allVisibility,
    required this.responsableName,
    required this.appVersion,
    required this.onVisibilityChanged,
    required this.onResponsableNameSaved,
    this.onRevokeAccess,
  });

  @override
  State<AppSettingsWidget> createState() => _AppSettingsWidgetState();
}

class _AppSettingsWidgetState extends State<AppSettingsWidget> {
  late final TextEditingController _responsableController;
  // Index du panneau actuellement ouvert (-1 si aucun)
  int _expandedIndex = -1;

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nom du responsable enregistré !'), duration: Duration(seconds: 2)),
    );
  }

  IconData _getIconForTable(String tableName) {
    switch (tableName) {
      case AppConstants.studentsTable:
        return Icons.people_alt_rounded;
      case AppConstants.stockTable:
        return Icons.inventory_2_rounded;
      case AppConstants.creditsTable:
        return Icons.history_edu_rounded;
      case AppConstants.paymentsTable:
        return Icons.payments_rounded;
      default:
        return Icons.table_chart_rounded;
    }
  }

  Color _getColorForTable(BuildContext context, String tableName) {
    // Utilisation de couleurs cohérentes avec le dashboard
    switch (tableName) {
      case AppConstants.studentsTable:
        return Colors.blue.shade700;
      case AppConstants.stockTable:
        return Colors.orange.shade800;
      case AppConstants.creditsTable:
        return Colors.purple.shade700;
      case AppConstants.paymentsTable:
        return Colors.green.shade700;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tableNames = widget.allHeaders.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête Paramètres
          Row(
            children: [
              Icon(Icons.settings, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Text(
                'Paramètres',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Section Responsable
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Votre nom de responsable',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _responsableController,
                    decoration: InputDecoration(
                      labelText: 'Votre nom',
                      hintText: 'Ex: Jean Dupont',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saveResponsableName,
                      icon: const Icon(Icons.save),
                      label: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Section Visibilité des colonnes
          Text(
            'Personnalisation des tableaux',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez les colonnes à afficher pour chaque tableau.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          
          if (tableNames.isEmpty)
             const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ExpansionPanelList(
              elevation: 0,
              expandedHeaderPadding: const EdgeInsets.symmetric(vertical: 8),
              dividerColor: Colors.transparent,
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  if (_expandedIndex == index) {
                     _expandedIndex = -1;
                  } else {
                     _expandedIndex = index;
                  }
                });
              },
              children: tableNames.asMap().entries.map<ExpansionPanel>((entry) {
                final index = entry.key;
                final tableName = entry.value;
                final headers = widget.allHeaders[tableName] ?? [];
                final visibility = widget.allVisibility[tableName] ?? [];
                final isExpanded = _expandedIndex == index;
                final color = _getColorForTable(context, tableName);

                return ExpansionPanel(
                  backgroundColor: isExpanded 
                      ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surface,
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.1),
                        child: Icon(_getIconForTable(tableName), color: color, size: 20),
                      ),
                      title: Text(
                        tableName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isExpanded ? color : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  },
                  body: headers.isEmpty 
                      ? const Padding(padding: EdgeInsets.all(16.0), child: Text('Aucune colonne trouvée'))
                      : Column(
                          children: [
                            const Divider(height: 1),
                            for (int i = 0; i < headers.length; i++)
                              SwitchListTile(
                                title: Text(headers[i], style: const TextStyle(fontSize: 14)),
                                value: (i < visibility.length) ? visibility[i] : true,
                                activeThumbColor: color,
                                activeTrackColor: color.withValues(alpha: 0.4),
                                onChanged: (bool value) {
                                  widget.onVisibilityChanged(tableName, i, value);
                                },
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                                dense: true,
                              ),
                             const SizedBox(height: 8),
                          ],
                        ),
                  isExpanded: isExpanded,
                  canTapOnHeader: true,
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 32),
          
          if (widget.onRevokeAccess != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Révoquer l\'accès ?'),
                      content: const Text('Cela déconnectera votre compte et forcera la demande de permissions à la prochaine connexion.\n\nUtilisez cette option pour changer de compte Google.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Révoquer')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    widget.onRevokeAccess!();
                  }
                },
                icon: const Icon(Icons.person_off),
                label: const Text('Révoquer l\'accès Google (Changer de compte)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'Version ${widget.appVersion}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
