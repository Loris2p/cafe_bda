import 'package:flutter/material.dart';

/// Un widget réutilisable pour afficher des données sous forme de tableau dynamique.
///
/// Ce widget prend une liste de listes (Matrix) en entrée et génère un [DataTable]
/// scrollable horizontalement et verticalement.
///
/// Fonctionnalités :
/// * Style zébré optionnel pour la lisibilité.
/// * Détection automatique des types (Numérique, Formule, Booléen) pour l'alignement.
/// * Tooltips sur les en-têtes et cellules.
class DataTableWidget extends StatelessWidget {
  /// Les données brutes à afficher. La première ligne est considérée comme l'en-tête.
  final List<List<dynamic>> data;
  
  /// Active ou désactive l'alternance de couleurs des lignes (Zebra striping).
  final bool showZebraStriping;
  
  /// Couleur de fond de l'en-tête.
  final Color? headerColor;
  
  /// Couleur des lignes paires (si [showZebraStriping] est true).
  final Color? rowColor1;
  
  /// Couleur des lignes impaires (si [showZebraStriping] est true).
  final Color? rowColor2;
  
  /// Couleur du texte de l'en-tête.
  final Color? headerTextColor;
  
  /// Couleur de la bordure du tableau.
  final Color? borderColor;
  
  /// Rayon des coins du tableau.
  final double borderRadius;

    /// Callback pour la mise à jour d'une cellule.

    /// Passe (rowIndex, colIndex, newValue).

    final Function(int rowIndex, int colIndex, dynamic newValue)? onCellUpdate;

  

    /// Index de la colonne actuellement triée.

    final int? sortColumnIndex;

  

    /// Indique si le tri est ascendant ou descendant.

    final bool sortAscending;

  

    /// Callback déclenché lors du clic sur un en-tête de colonne pour le tri.

    final Function(int columnIndex)? onSort;

  

    const DataTableWidget({

      super.key,

      required this.data,

      this.showZebraStriping = true,

      this.headerColor,

      this.rowColor1,

      this.rowColor2,

      this.headerTextColor = Colors.white,

      this.borderColor,

      this.borderRadius = 12.0,

      this.onCellUpdate,

      this.sortColumnIndex,

      this.sortAscending = true,

      this.onSort,

    });

  

    @override

    Widget build(BuildContext context) {

      if (data.isEmpty) {

        return const Center(child: Text('Aucune donnée disponible'));

      }

  

      if (data.first.isEmpty) {

        return const Center(child: Text('Les en-têtes sont manquants'));

      }

  

      final theme = Theme.of(context);

      // Utilisation de primaryContainer pour un look moins agressif que le primary pur

      final defaultHeaderColor = theme.colorScheme.primary; 

      final defaultBorderColor = theme.colorScheme.outlineVariant;

  

      // Création des colonnes à partir de la première ligne de données (Headers)

      final columns = data[0].asMap().entries.map((entry) {

        final headerText =

            data[0][entry.key]?.toString() ?? 'Colonne ${entry.key + 1}';

  

        return DataColumn(

          label: Expanded( // Expanded pour remplir l'espace de l'en-tête

            child: Container(

              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),

              alignment: Alignment.centerLeft, // Alignement cohérent

              child: Text(

                headerText,

                style: TextStyle(

                  fontWeight: FontWeight.bold,

                  color: headerTextColor ?? theme.colorScheme.onPrimary,

                  fontSize: 14,

                ),

                overflow: TextOverflow.ellipsis,

              ),

            ),

          ),

          tooltip: headerText,

          onSort: onSort != null ? (columnIndex, _) => onSort!(columnIndex) : null,

        );

      }).toList();

  

      // Création des lignes de données (Rows)

      // On ignore la première ligne car elle a servi pour les en-têtes

      final rows = data.length > 1

          ? data.skip(1).mapIndexed((rowIndex, row) {

              return DataRow(

                color: WidgetStateProperty.resolveWith<Color?>((states) {

                  if (!showZebraStriping) return null;

                  // Alternance subtile basée sur la couleur primaire

                  return rowIndex % 2 == 0

                      ? rowColor1 ?? theme.colorScheme.surface

                      : rowColor2 ?? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);

                }),

                cells: row.asMap().entries.map((cellEntry) {

                  final dynamic cellValue = cellEntry.value;

                  final String cellString = cellValue?.toString() ?? '';

                  final int colIndex = cellEntry.key;

                  

                  // Détection améliorée du type de contenu

                  final isFormula = cellString.startsWith('=');

                  final isNumeric =

                      double.tryParse(cellString) != null && !isFormula;

  

                  bool isBoolean = false;

                  bool? boolValue;

  

                  if (cellValue is bool) {

                    isBoolean = true;

                    boolValue = cellValue;

                  } else if ((cellString.toLowerCase() == 'true' || cellString.toLowerCase() == 'false') && !isFormula) {

                    isBoolean = true;

                    boolValue = cellString.toLowerCase() == 'true';

                  }

  

                  // --- Cellule éditable pour les booléens ---

                  if (isBoolean && onCellUpdate != null && boolValue != null) {

                    return DataCell(

                      Center(

                        child: Checkbox(

                          value: boolValue,

                          onChanged: (bool? newValue) {

                            if (newValue != null) {

                              onCellUpdate!(rowIndex, colIndex, newValue);

                            }

                          },

                        ),

                      ),

                      // placeholder: true, // Décommentez si vous voulez un indicateur de chargement

                    );

                  }

                  

                  // --- Affichage standard pour les autres types ---

                  return DataCell(

                    Padding(

                      padding: const EdgeInsets.symmetric(

                        vertical: 10,

                        horizontal: 12,

                      ),

                      child: Align(

                        // Alignement à droite pour les nombres

                        alignment: isNumeric

                            ? Alignment.centerRight

                            : Alignment.centerLeft,

                        child: Tooltip(

                          message: isFormula

                              ? 'Formule: $cellString'

                              : cellString.isEmpty

                              ? 'Vide'

                              : cellString,

                          child: SelectableText(

                            isFormula ? 'Calculé' : cellString,

                            style: TextStyle(

                              fontStyle: isFormula

                                  ? FontStyle.italic

                                  : FontStyle.normal,

                              color: isFormula

                                  ? theme.colorScheme.secondary

                                  : isBoolean

                                      ? Colors.green.shade700 // Afficher le texte si non modifiable

                                      : theme.textTheme.bodyMedium?.color,

                              fontWeight: cellString == 'N/A'

                                  ? FontWeight.bold

                                  : FontWeight.normal,

                            ),

                          ),

                        ),

                      ),

                    ),

                  );

                }).toList(),

              );

            }).toList()

          : <DataRow>[];

  

      // Structure scrollable double (Vertical + Horizontal)

      return SingleChildScrollView(

        scrollDirection: Axis.vertical,

        child: Center(

          child: SingleChildScrollView(

            scrollDirection: Axis.horizontal,

            child: Container(

              decoration: BoxDecoration(

                border: Border.all(color: borderColor ?? defaultBorderColor),

                borderRadius: BorderRadius.circular(borderRadius),

              ),

              child: ClipRRect(

                borderRadius: BorderRadius.circular(borderRadius),

                child: DataTable(

                  sortColumnIndex: sortColumnIndex,

                  sortAscending: sortAscending,

                  columnSpacing: 16.0,

                  horizontalMargin: 0,

                  headingRowHeight: 50.0,

                  dataRowHeight: 48.0,

                  headingRowColor: WidgetStateProperty.all(

                    headerColor ?? defaultHeaderColor,

                  ),

                  dividerThickness: 1.0,

                  columns: columns,

                  rows: rows,

                ),

              ),

            ),

          ),

        ),

      );
  }
}

/// Extension utilitaire pour obtenir l'index dans un map() sur un itérable.
extension IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) {
    var index = 0;
    return map((element) => f(index++, element));
  }
}