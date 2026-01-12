import 'package:flutter/material.dart';
import 'edit_cell_dialog.dart';

/// Une classe utilitaire fournissant des méthodes statiques pour afficher les dialogues de recherche.
class SearchDialog {
  
  /// Affiche une boîte de dialogue listant les résultats de recherche.
  ///
  /// * [context] - Le contexte de build.
  /// * [searchTerm] - Le terme recherché (pour l'afficher dans le titre).
  /// * [results] - La liste des lignes trouvées.
  /// * [fullData] - La liste complète des données (pour retrouver l'index réel de la ligne).
  /// * [onRowSelected] - Callback déclenché lorsqu'un utilisateur tape sur un résultat.
  static void showSearchResults(
    BuildContext context, {
    required String searchTerm,
    required List<List<dynamic>> results,
    required List<List<dynamic>> fullData,
    required Function(List<dynamic>) onRowSelected,
  }) {
    // Attempt to get headers from fullData if available (unused for now)
    // final headers = fullData.isNotEmpty ? fullData[0] : [];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Résultats pour "$searchTerm"',
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${results.length} résultat(s) trouvé(s)',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Fermer',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // List
                Expanded(
                  child: results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.outline),
                              const SizedBox(height: 16),
                              Text('Aucun résultat trouvé', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: results.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          separatorBuilder: (context, index) => const Divider(indent: 72, endIndent: 24, height: 1),
                          itemBuilder: (context, index) {
                            final row = results[index];
                            final firstVal = row.isNotEmpty ? row[0].toString() : '';
                            final secondVal = row.length > 1 ? row[1].toString() : '';
                            final thirdVal = row.length > 2 ? row[2].toString() : '';
                            
                            // Heuristic: If it looks like a name, use initials.
                            final initial = firstVal.isNotEmpty ? firstVal[0].toUpperCase() : '?';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                                foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                                child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              title: Text(
                                firstVal,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis
                              ),
                              subtitle: Text(
                                [secondVal, thirdVal].where((e) => e.isNotEmpty).join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.of(context).pop();
                                onRowSelected(row);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Affiche une boîte de dialogue avec le détail complet d'une ligne.
  ///
  /// * [row] - La ligne de données à afficher.
  /// * [columnNames] - Les noms des colonnes pour étiqueter chaque valeur.
  /// * [visibleColumns] - Liste optionnelle de booléens indiquant la visibilité de chaque colonne.
  /// * [canEdit] - Si vrai, permet de modifier les valeurs.
  /// * [onEdit] - Callback (colIndex, newValue) appelé lors d'une modification.
  static void showRowDetails(
    BuildContext context, {
    required List<dynamic> row,
    required List<dynamic> columnNames,
    List<bool>? visibleColumns,
    bool canEdit = false,
    Function(int colIndex, dynamic newValue)? onEdit,
    EditType Function(int colIndex)? getEditType,
    List<String> Function(int colIndex)? getDropdownOptions,
    bool Function(int colIndex)? isCellEditable,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Nécessaire pour mettre à jour l'UI après une édition locale
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 16),
                          Text('Détails', style: Theme.of(context).textTheme.headlineSmall),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (row.isEmpty)
                              const Text('Aucune donnée disponible')
                            else ...[
                              for (int i = 0; i < row.length; i++)
                                if (i < columnNames.length)
                                   if (visibleColumns == null || (i < visibleColumns.length && visibleColumns[i]))
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              columnNames[i].toString(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: SelectableText(
                                                    row[i]?.toString() ?? '-',
                                                    style: Theme.of(context).textTheme.bodyLarge,
                                                  ),
                                                ),
                                                if (canEdit && onEdit != null && (isCellEditable == null || isCellEditable(i)))
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, size: 18),
                                                    color: Theme.of(context).colorScheme.secondary,
                                                    onPressed: () async {
                                                      final currentVal = row[i]?.toString() ?? '';
                                                      
                                                      EditType editType = EditType.text;
                                                      List<String>? options;
                                                      if (getEditType != null) {
                                                        editType = getEditType(i);
                                                      }
                                                      if (getDropdownOptions != null && editType == EditType.dropdown) {
                                                        options = getDropdownOptions(i);
                                                      }

                                                      final newVal = await showDialog(
                                                        context: context,
                                                        builder: (ctx) {
                                                          return EditCellDialog(
                                                            initialValue: currentVal,
                                                            editType: editType,
                                                            dropdownOptions: options,
                                                          );
                                                        }
                                                      );

                                                      if (newVal != null) {
                                                        // Update UI locale
                                                        setState(() {
                                                           row[i] = newVal;
                                                        });
                                                        // Call backend
                                                        onEdit(i, newVal);
                                                      }
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Fermer'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }
}