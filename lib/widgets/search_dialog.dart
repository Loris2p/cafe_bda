import 'package:flutter/material.dart';

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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Résultats pour "$searchTerm"')),
              Text(
                '${results.length} résultats',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: results.isEmpty
                ? const Center(child: Text('Aucun résultat trouvé'))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final row = results[index];
                      // Trouver l'index réel dans fullData pour un affichage correct
                      final realIndex = fullData.indexOf(row) + 1;

                      return ListTile(
                        title: Text('Ligne $realIndex'),
                        subtitle: Text(
                          row.join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onRowSelected(row);
                        },
                        trailing: const Icon(Icons.chevron_right),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  /// Affiche une boîte de dialogue avec le détail complet d'une ligne.
  ///
  /// * [row] - La ligne de données à afficher.
  /// * [columnNames] - Les noms des colonnes pour étiqueter chaque valeur.
  static void showRowDetails(
    BuildContext context, {
    required List<dynamic> row,
    required List<dynamic> columnNames,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const SelectableText('Détails de la ligne'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (row.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SelectableText('Aucune donnée disponible'),
                  )
                else ...[
                  for (int i = 0; i < row.length; i++)
                    if (i < columnNames.length)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: SelectableText.rich(
                          TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(
                                text: '${columnNames[i]}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: row[i]?.toString() ?? 'N/A',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}