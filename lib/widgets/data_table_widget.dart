import 'package:flutter/material.dart';

class DataTableWidget extends StatefulWidget {
  final List<String> headers;
  final List<List<dynamic>> data;
  final bool isLoading;
  final Function(int)? onSort;
  final Function(int)? onRowTap;
  final int? sortColumnIndex;
  final bool sortAscending;

  const DataTableWidget({
    super.key,
    required this.headers,
    required this.data,
    this.isLoading = false,
    this.onSort,
    this.onRowTap,
    this.sortColumnIndex,
    this.sortAscending = true,
  });

  @override
  State<DataTableWidget> createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  int _rowsPerPage = 10;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  late List<List<dynamic>> _sortedData;

  @override
  void initState() {
    super.initState();
    _sortedData = List.from(widget.data);
  }

  @override
  void didUpdateWidget(DataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _applySort();
    }
  }

  void _applySort() {
    setState(() {
      _sortedData = List.from(widget.data);
      if (_sortColumnIndex != null) {
        _performSort(_sortColumnIndex!, _sortAscending);
      }
    });
  }

  void _performSort(int columnIndex, bool ascending) {
    _sortedData.sort((a, b) {
      dynamic aValue = a[columnIndex];
      dynamic bValue = b[columnIndex];

      if (aValue == null) return ascending ? -1 : 1;
      if (bValue == null) return ascending ? 1 : -1;

      if (aValue is num && bValue is num) {
        return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      }
      
      String aStr = aValue.toString();
      String bStr = bValue.toString();
      
      if (aStr.contains('€')) {
        double aNum = double.tryParse(aStr.replaceAll(' €', '').replaceAll(',', '.')) ?? 0.0;
        double bNum = double.tryParse(bStr.replaceAll(' €', '').replaceAll(',', '.')) ?? 0.0;
        return ascending ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
      }

      return ascending ? aStr.toLowerCase().compareTo(bStr.toLowerCase()) : bStr.toLowerCase().compareTo(aStr.toLowerCase());
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _performSort(columnIndex, ascending);
    });
    if (widget.onSort != null) {
      widget.onSort!(columnIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Theme(
              data: theme.copyWith(
                cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
                dataTableTheme: DataTableThemeData(
                  headingRowColor: WidgetStateProperty.all(theme.colorScheme.primary.withValues(alpha: 0.1)),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                      maxWidth: 1200, 
                    ),
                    child: PaginatedDataTable(
                      header: null,
                      showCheckboxColumn: false,
                      headingRowHeight: 50,
                      dataRowMinHeight: 40,
                      dataRowMaxHeight: 55,
                      columnSpacing: 16,
                      horizontalMargin: 12,
                      columns: widget.headers.asMap().entries.map((e) {
                        return DataColumn(
                          label: Text(e.value),
                          onSort: (index, ascending) => _onSort(index, ascending),
                        );
                      }).toList(),
                      source: _DataSource(_sortedData, widget.onRowTap),
                      rowsPerPage: _rowsPerPage,
                      availableRowsPerPage: const [10, 20, 50],
                      onRowsPerPageChanged: (value) => setState(() => _rowsPerPage = value ?? 10),
                      showFirstLastButtons: true,
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.isLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }
}

class _DataSource extends DataTableSource {
  final List<List<dynamic>> data;
  final Function(int)? onRowTap;
  _DataSource(this.data, this.onRowTap);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final row = data[index];
    return DataRow(
      onSelectChanged: onRowTap != null ? (_) => onRowTap!(index) : null,
      cells: row.map((cell) {
        return DataCell(Text(cell?.toString() ?? ''));
      }).toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
}
