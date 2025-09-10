import 'package:flutter/material.dart';

class DataTableWidget extends StatelessWidget {
  final List<List<dynamic>> data;
  final bool showZebraStriping;
  final Color? headerColor;
  final Color? rowColor1;
  final Color? rowColor2;
  final Color? headerTextColor;
  final Color? borderColor;
  final double borderRadius;

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
    final defaultHeaderColor = theme.colorScheme.primary;
    final defaultBorderColor = theme.dividerColor;

    // Créer les colonnes avec un style moderne
    final columns = data[0].asMap().entries.map((entry) {
      final headerText =
          data[0][entry.key]?.toString() ?? 'Colonne ${entry.key + 1}';

      return DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: headerColor ?? defaultHeaderColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(entry.key == 0 ? borderRadius : 0),
              bottom: Radius.circular(
                entry.key == data[0].length - 1 ? borderRadius : 0,
              ),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              headerText,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: headerTextColor ?? Colors.white,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        tooltip: headerText,
      );
    }).toList();

    final rows = data.length > 1
        ? data.skip(1).mapIndexed((rowIndex, row) {
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>((states) {
                if (!showZebraStriping) return null;
                return rowIndex % 2 == 0
                    ? rowColor1 ?? theme.cardColor
                    : rowColor2 ?? theme.canvasColor;
              }),
              cells: row.asMap().entries.map((cellEntry) {
                final cellValue = cellEntry.value?.toString() ?? '';
                final isFormula = cellValue.startsWith('=');
                final isNumeric =
                    double.tryParse(cellValue) != null && !isFormula;
                final isBoolean =
                    cellValue.toLowerCase() == 'true' ||
                    cellValue.toLowerCase() == 'false' && !isFormula;

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
                            ? 'Formule: $cellValue'
                            : cellValue.isEmpty
                            ? 'Vide'
                            : cellValue,
                        child: SelectableText(
                          isFormula ? 'Calculé' : cellValue,
                          style: TextStyle(
                            fontStyle: isFormula
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: isFormula
                                ? theme.colorScheme.secondary
                                : isBoolean
                                ? Colors.green.shade700
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: cellValue == 'N/A'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          // overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList()
        : <DataRow>[];

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
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
    );
  }
}

// Extension pour mapIndexed
extension IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) {
    var index = 0;
    return map((element) => f(index++, element));
  }
}
