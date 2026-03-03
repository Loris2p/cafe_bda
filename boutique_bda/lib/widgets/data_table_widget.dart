import 'dart:ui';
import 'package:flutter/material.dart';

class DataTableWidget extends StatefulWidget {
  final List<String> headers;
  final List<List<dynamic>> data;
  final bool isLoading;
  final Function(int)? onSort;
  final int? sortColumnIndex;
  final bool sortAscending;

  const DataTableWidget({
    super.key,
    required this.headers,
    required this.data,
    this.isLoading = false,
    this.onSort,
    this.sortColumnIndex,
    this.sortAscending = true,
  });

  @override
  State<DataTableWidget> createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Theme(
          data: theme.copyWith(
            cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
          ),
          child: SingleChildScrollView(
            child: PaginatedDataTable(
              header: null,
              columns: widget.headers.asMap().entries.map((e) {
                return DataColumn(
                  label: Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onSort: widget.onSort != null ? (index, _) => widget.onSort!(e.key) : null,
                );
              }).toList(),
              source: _DataSource(widget.data),
              rowsPerPage: _rowsPerPage,
              availableRowsPerPage: const [5, 10, 20, 50],
              onRowsPerPageChanged: (value) => setState(() => _rowsPerPage = value ?? 10),
              showFirstLastButtons: true,
              columnSpacing: 20,
              horizontalMargin: 10,
            ),
          ),
        ),
        if (widget.isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: Colors.white.withValues(alpha: 0.2),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }
}

class _DataSource extends DataTableSource {
  final List<List<dynamic>> data;
  _DataSource(this.data);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final row = data[index];
    return DataRow(
      cells: row.map((cell) {
        return DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              cell?.toString() ?? '',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
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
