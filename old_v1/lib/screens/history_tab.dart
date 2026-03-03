import 'package:cafe_bda/providers/cafe_data_provider.dart';
import 'package:cafe_bda/utils/constants.dart';
import 'package:cafe_bda/widgets/data_table_widget.dart'; // Réutilisation du widget de table
import 'package:cafe_bda/widgets/edit_cell_dialog.dart'; // Ajout pour EditType
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  @override
  void initState() {
    super.initState();
    // Charger la table Logs dès l'affichage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CafeDataProvider>().readTable(tableName: AppConstants.logsTable);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000), // Un peu plus large pour les logs
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Historique des Actions",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const _RefreshButton(),
                  ],
                ),
              ),
              const Expanded(child: _HistoryDataDisplay()),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<CafeDataProvider>(
      builder: (context, provider, _) {
        return IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualiser',
          onPressed: provider.isLoading
              ? null
              : () => provider.readTable(forceRefresh: true),
        );
      },
    );
  }
}

// Version simplifiée de _DataDisplay dédiée à l'historique pour forcer l'ordre inversé par défaut si nécessaire
// Mais pour l'instant, réutilisons la logique standard via le Provider, 
// sauf qu'on veut peut-être trier par date décroissante par défaut.
class _HistoryDataDisplay extends StatelessWidget {
  const _HistoryDataDisplay();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CafeDataProvider>();
    
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage.isNotEmpty) {
      return Center(child: Text('Erreur: ${provider.errorMessage}', style: const TextStyle(color: Colors.red)));
    }

    final sheetData = provider.sheetData;
    if (sheetData.isEmpty) {
      return const Center(child: Text("Aucun historique disponible."));
    }

    // On inverse l'affichage pour avoir les logs récents en haut (sauf si un tri est déjà actif)
    // Le DataTableWidget gère le tri via le provider.
    // Par défaut, sheetData est dans l'ordre du fichier (chronologique).
    // On va laisser l'utilisateur trier, mais on peut proposer un tri par défaut.
    
    // Note: DataTableWidget attend les données brutes et gère le tri si sortColumnIndex est set.
    // Si on veut inverser par défaut sans toucher au provider, on le fait ici.
    // Mais le plus propre est de laisser le provider gérer.

    // On utilise simplement le DataTableWidget existant. 
    // Cependant, comme DataTableWidget est "bête", il affiche ce qu'on lui donne.
    // Si on veut les logs récents en premier, on devrait inverser la liste des données (hors header).
    
    List<List<dynamic>> displayData = List.from(sheetData);
    if (displayData.length > 1 && provider.sortColumnIndex == null) {
      // Garder le header (index 0)
      final header = displayData[0];
      final rows = displayData.sublist(1);
      // Inverser les lignes
      rows.reversed.toList(); 
      // Reconstruire (Header + Reversed Rows)
      displayData = [header, ...rows.reversed];
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTableWidget(
          data: displayData,
          sortColumnIndex: provider.sortColumnIndex, // Ceci sera probablement null si on n'a pas trié
          sortAscending: provider.sortAscending,
          onSort: (columnIndex) {
            // Le tri standard du provider
             provider.sortData(columnIndex);
          },
          // Pas d'édition dans l'historique
          getEditType: (row, col) => EditType.text,
          getDropdownOptions: (row, col) => [],
          isCellEditable: (row, col) => false,
        ),
      ),
    );
  }
}
