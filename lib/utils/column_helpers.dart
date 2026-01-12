import 'package:cafe_bda/widgets/edit_cell_dialog.dart';
import 'package:cafe_bda/providers/cafe_data_provider.dart';

class ColumnHelpers {
  static EditType getEditType(String headerName) {
    final lowerName = headerName.toLowerCase();
    
    if (lowerName.contains('date')) {
      return EditType.date;
    } else if (lowerName.contains('moyen paiement') || lowerName == 'type') {
      return EditType.dropdown;
    } else if (lowerName.contains('prix') || 
               lowerName.contains('solde') || 
               lowerName.contains('crédit') || 
               lowerName.contains('nb de cafés') || 
               lowerName.contains('stock') ||
               lowerName.contains('valeur')) {
      return EditType.numeric;
    }
    
    return EditType.text;
  }

  static List<String> getDropdownOptions(String headerName, CafeDataProvider provider) {
    final lowerName = headerName.toLowerCase();

    if (lowerName.contains('moyen paiement')) {
       // Récupérer les moyens de paiement actifs + 'Crédit' si non présent
       final options = provider.paymentConfigs.map((c) => c.label).toList();
       if (!options.contains('Crédit')) options.add('Crédit');
       // Ajouter Espèces si pas là (souvent par défaut)
       if (!options.contains('Espèces')) options.add('Espèces');
       return options;
    }
    
    return [];
  }
}
