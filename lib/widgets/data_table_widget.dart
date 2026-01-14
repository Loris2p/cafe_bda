import 'dart:ui';
import 'package:flutter/material.dart';
import 'edit_cell_dialog.dart';

/// Un widget réutilisable pour afficher des données sous forme de tableau dynamique.
/// Utilise PaginatedDataTable pour optimiser les performances sur les grands jeux de données.
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

  /// Callback optionnel pour déterminer si une cellule spécifique est éditable.
  /// Si null, toutes les cellules sont considérées éditables (si onCellUpdate est fourni).
  /// Retourne true si éditable, false sinon.
  final bool Function(int rowIndex, int colIndex)? isCellEditable;

  /// Callback pour déterminer le type d'éditeur pour une cellule donnée.
  final EditType Function(int rowIndex, int colIndex)? getEditType;

  /// Callback pour obtenir les options d'une liste déroulante (si getEditType retourne dropdown).
  final List<String> Function(int rowIndex, int colIndex)? getDropdownOptions;

  /// Callback pour la suppression d'une ligne.
  /// Si fourni, une colonne "Actions" avec un bouton de suppression sera ajoutée.
  final Function(int rowIndex)? onDeleteRow;

  const DataTableWidget({
    super.key,
    required this.data,
    this.showZebraStriping = true,
    this.headerColor,
    this.rowColor1,
    this.rowColor2,
    this.headerTextColor, // Default handled in build
    this.borderColor,
    this.borderRadius = 12.0,
    this.onCellUpdate,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.isCellEditable,
    this.getEditType,
    this.getDropdownOptions,
    this.onDeleteRow,
  });

  @override
  State<DataTableWidget> createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  // Key unique pour forcer le rebuild du PaginatedDataTable si les données changent drastiquement
  Key _tableKey = UniqueKey();
  
  // Nombre de lignes par page
  int _rowsPerPage = 20;

  // État de chargement pour la transition de pagination
  bool _isLoading = false;
  
  @override
  void didUpdateWidget(DataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la structure des données change (nombre de colonnes ou lignes), on peut reset la vue
    if (widget.data.length != oldWidget.data.length || 
        (widget.data.isNotEmpty && oldWidget.data.isNotEmpty && widget.data[0].length != oldWidget.data[0].length)) {
      _tableKey = UniqueKey();
    }
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
    final effectiveHeaderTextColor = widget.headerTextColor ?? theme.colorScheme.onPrimary;

    // Check for numeric columns based on the first row of data
    bool isColumnNumeric(int index) {
      if (widget.data.length < 2) return false;
      if (index >= widget.data[1].length) return false;
      final value = widget.data[1][index];
      if (value == null) return false;
      // Check if it's a number and not a formula
      final str = value.toString();
      return !str.startsWith('=') && num.tryParse(str) != null;
    }

    // Colonnes
    final columns = widget.data[0].asMap().entries.map<DataColumn>((entry) {
      final headerText = entry.value?.toString() ?? 'Colonne ${entry.key + 1}';
      final isNumeric = isColumnNumeric(entry.key);

      return DataColumn(
        label: Text(
          headerText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: effectiveHeaderTextColor,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: isNumeric ? TextAlign.right : TextAlign.left,
        ),
        numeric: isNumeric,
        tooltip: headerText,
        onSort: widget.onSort != null ? (columnIndex, _) => widget.onSort!(columnIndex) : null,
      );
    }).toList();

    if (widget.onDeleteRow != null) {
      columns.add(DataColumn(
        label: Text(
          'Actions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: effectiveHeaderTextColor,
            fontSize: 14,
          ),
        ),
      ));
    }

    // Source de données
    final source = _DataSource(
      data: widget.data, // Passe toutes les données
      context: context,
      showZebraStriping: widget.showZebraStriping,
      rowColor1: widget.rowColor1,
      rowColor2: widget.rowColor2,
      onCellUpdate: widget.onCellUpdate,
      isCellEditable: widget.isCellEditable,
      getEditType: widget.getEditType,
      getDropdownOptions: widget.getDropdownOptions,
      onDeleteRow: widget.onDeleteRow,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: widget.borderColor ?? defaultBorderColor),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      cardTheme: const CardThemeData(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                    ),
                    child: PaginatedDataTable(
                      key: _tableKey,
                      columns: columns,
                      source: source,
                      sortColumnIndex: widget.sortColumnIndex,
                      sortAscending: widget.sortAscending,
                      header: null, // On n'utilise pas le header par défaut du widget
                      rowsPerPage: _rowsPerPage,
                      availableRowsPerPage: const [10, 20, 50, 100],
                      onRowsPerPageChanged: (value) {
                        if (value != null && value != _rowsPerPage) {
                          setState(() {
                            _isLoading = true;
                          });
                          // Petit délai pour l'effet visuel
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              setState(() {
                                _rowsPerPage = value;
                                _isLoading = false;
                              });
                            }
                          });
                        }
                      },
                      showCheckboxColumn: false,
                      columnSpacing: 16.0,
                      horizontalMargin: 20,
                      headingRowColor: WidgetStateProperty.all(widget.headerColor ?? defaultHeaderColor),
                      headingRowHeight: 50,
                      showFirstLastButtons: true,
                    ),
                  ),
                ),
                if (_isLoading)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.1),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    );
  }
}

class _DataSource extends DataTableSource {
  final List<List<dynamic>> data;
  final BuildContext context;
  final bool showZebraStriping;
  final Color? rowColor1;
  final Color? rowColor2;
  final Function(int rowIndex, int colIndex, dynamic newValue)? onCellUpdate;
  final bool Function(int rowIndex, int colIndex)? isCellEditable;
  final EditType Function(int rowIndex, int colIndex)? getEditType;
  final List<String> Function(int rowIndex, int colIndex)? getDropdownOptions;
  final Function(int rowIndex)? onDeleteRow;

  _DataSource({
    required this.data,
    required this.context,
    this.showZebraStriping = true,
    this.rowColor1,
    this.rowColor2,
    this.onCellUpdate,
    this.isCellEditable,
    this.getEditType,
    this.getDropdownOptions,
    this.onDeleteRow,
  });

  @override
  DataRow? getRow(int index) {
    // data[0] est le header, donc l'index réel dans data est index + 1
    final int realIndex = index + 1;
    
    if (realIndex >= data.length) return null;

    final row = data[realIndex];
    final theme = Theme.of(context);

    final List<DataCell> cells = row.asMap().entries.map((cellEntry) {
        final dynamic cellValue = cellEntry.value;
        final String cellString = cellValue?.toString() ?? '';
        final int colIndex = cellEntry.key;
        
        final isFormula = cellString.startsWith('=');
        final isNumeric = double.tryParse(cellString) != null && !isFormula;

        // Check if cell is editable via callback if provided, otherwise fallback to formula check
        // Note: isFormula here is checking the DISPLAY value, so it's likely false.
        // That's why we added isCellEditable which checks the backend formula data.
        final bool canEdit = onCellUpdate != null && 
                             (isCellEditable == null || isCellEditable!(index, colIndex));

        bool isBoolean = false;
        bool? boolValue;

        if (cellValue is bool) {
          isBoolean = true;
          boolValue = cellValue;
        } else if ((cellString.toLowerCase() == 'true' || cellString.toLowerCase() == 'false') && !isFormula) {
          isBoolean = true;
          boolValue = cellString.toLowerCase() == 'true';
        }

        if (isBoolean && onCellUpdate != null && boolValue != null) {
          return DataCell(
            Center(
              child: Checkbox(
                key: ValueKey('cb_${index}_${colIndex}_$boolValue'),
                value: boolValue,
                onChanged: canEdit ? (bool? newValue) {
                  if (newValue != null) {
                    onCellUpdate!(index, colIndex, newValue); // index est le rowIndex relatif aux données (sans header)
                  }
                } : null,
              ),
            ),
          );
        }
        
        return DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8, // Réduit légèrement
              horizontal: 8,
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
                child: Text( // SelectableText peut être lourd dans de grandes listes, Text est plus performant
                  isFormula ? 'Calculé' : cellString,
                  style: TextStyle(
                    fontStyle: isFormula
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: isFormula
                        ? theme.colorScheme.secondary
                        : isBoolean
                            ? Colors.green.shade700
                            : canEdit ? theme.textTheme.bodyMedium?.color : Colors.grey.shade600, // Grisé si non éditable
                    fontWeight: cellString == 'N/A'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ),
          onTap: (canEdit && !isFormula) ? () async {
             // Déterminer le type d'éditeur
             EditType editType = EditType.text;
             List<String>? options;
             
             if (getEditType != null) {
               editType = getEditType!(index, colIndex);
             } else if (isNumeric) {
               editType = EditType.numeric;
             }
             
             if (getDropdownOptions != null && editType == EditType.dropdown) {
               options = getDropdownOptions!(index, colIndex);
             }

             final result = await showDialog(
               context: context,
               builder: (context) {
                 return EditCellDialog(
                   initialValue: cellString,
                   editType: editType,
                   dropdownOptions: options,
                 );
               }
             );
             
             if (result != null) {
                onCellUpdate!(index, colIndex, result);
             }
          } : null,
        );
      }).toList();

      if (onDeleteRow != null) {
        cells.add(DataCell(
          IconButton(
            icon: Icon(Icons.delete, color: theme.colorScheme.error),
            onPressed: () => onDeleteRow!(index),
          ),
        ));
      }

    return DataRow.byIndex(
      index: index,
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (!showZebraStriping) return null;
        return index % 2 == 0
            ? rowColor1 ?? theme.colorScheme.surface
            : rowColor2 ?? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
      }),
      cells: cells,
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length > 1 ? data.length - 1 : 0;

  @override
  int get selectedRowCount => 0;
}