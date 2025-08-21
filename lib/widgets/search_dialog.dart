import 'package:flutter/material.dart';

class SearchDialog {
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
          title: Text('Résultats pour "$searchTerm"'),
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

  static void showRowDetails(
    BuildContext context, {
    required List<dynamic> row,
    required List<dynamic> columnNames,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Détails de la ligne'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (row.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Aucune donnée disponible'),
                  )
                else ...[
                  for (int i = 0; i < row.length; i++)
                    if (i < columnNames.length)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: RichText(
                          text: TextSpan(
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
