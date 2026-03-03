import 'package:flutter/material.dart';
import '../core/table_manager.dart';

class TableView extends StatelessWidget {
  final TableManager manager;
  const TableView({Key? key, required this.manager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        if (manager.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (manager.error != null) {
          return Center(
            child: ErrorDisplay(
              message: manager.error!,
              onRetry: () => manager.refreshCurrent(),
            ),
          );
        }
        final data = manager.currentData;
        if (data == null) {
          return const Center(child: Text('Aucun tableau sélectionné'));
        }
        return ListView.builder(
          itemCount: data.rows.length,
          itemBuilder: (context, index) {
            // ListView.builder est virtuel : ne charge pas tous les widgets à la fois
            final row = data.rows[index];
            return ListTile(title: Text(row));
          },
        );
      },
    );
  }
}

class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorDisplay({Key? key, required this.message, required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Erreur: $message', textAlign: TextAlign.center),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
    ]);
  }
}
