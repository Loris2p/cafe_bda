import 'package:flutter/material.dart';

/// Un widget réutilisable pour afficher des données sous forme de tableau dynamique.
class DataTableWidget extends StatefulWidget {
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
  State<DataTableWidget> createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    if (widget.data.first.isEmpty) {
      return const Center(child: Text('Les en-têtes sont manquants'));
    }

    final theme = Theme.of(context);
    final defaultHeaderColor = theme.colorScheme.primary; 
    final defaultBorderColor = theme.colorScheme.outlineVariant;

    final columns = widget.data[0].asMap().entries.map((entry) {
      final headerText =
          widget.data[0][entry.key]?.toString() ?? 'Colonne ${entry.key + 1}';

      return DataColumn(
        label: Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              headerText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.headerTextColor ?? theme.colorScheme.onPrimary,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        tooltip: headerText,
        onSort: widget.onSort != null ? (columnIndex, _) => widget.onSort!(columnIndex) : null,
      );
    }).toList();

    final rows = widget.data.length > 1
        ? widget.data.skip(1).mapIndexed((rowIndex, row) {
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>((states) {
                if (!widget.showZebraStriping) return null;
                return rowIndex % 2 == 0
                    ? widget.rowColor1 ?? theme.colorScheme.surface
                    : widget.rowColor2 ?? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
              }),
              cells: row.asMap().entries.map((cellEntry) {
                final dynamic cellValue = cellEntry.value;
                final String cellString = cellValue?.toString() ?? '';
                final int colIndex = cellEntry.key;
                
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

                if (isBoolean && widget.onCellUpdate != null && boolValue != null) {
                  return DataCell(
                    Center(
                      child: Checkbox(
                        value: boolValue,
                        onChanged: (bool? newValue) {
                          if (newValue != null) {
                            widget.onCellUpdate!(rowIndex, colIndex, newValue);
                          }
                        },
                      ),
                    ),
                  );
                }
                
                return DataCell(
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    child: Align(
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
                                    ? Colors.green.shade700
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

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        scrollDirection: Axis.vertical,
        child: Center(
          child: Column(
            children: [
              Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: const SizedBox.shrink(), // Required child for Scrollbar
              ),
              SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: widget.borderColor ?? defaultBorderColor),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: DataTable(
                      sortColumnIndex: widget.sortColumnIndex,
                      sortAscending: widget.sortAscending,
                      columnSpacing: 16.0,
                      horizontalMargin: 0,
                      headingRowHeight: 50.0,
                      dataRowMinHeight: 48.0, // Use min/max height
                      dataRowMaxHeight: 48.0,
                      headingRowColor: WidgetStateProperty.all(
                        widget.headerColor ?? defaultHeaderColor,
                      ),
                      dividerThickness: 1.0,
                      columns: columns,
                      rows: rows,
                    ),
                  ),
                ),
              ),
            ],
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