import '../services/google_sheets_service.dart';
import '../models/payment_config.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

/// La classe CafeRepository est responsable de la logique métier de l'application.
///
/// Elle agit comme une couche d'abstraction entre l'interface utilisateur (via le Provider)
/// et le service de données brut ([GoogleSheetsService]).
///
/// Ses responsabilités incluent :
/// * La mise en forme des données avant envoi (ordre des colonnes, formules Excel).
/// * La gestion du cache pour optimiser les performances de lecture.
/// * Le calcul des indices de ligne pour les insertions.
class CafeRepository {
  final GoogleSheetsService _sheetsService;

  // Cache en mémoire pour réduire les appels API redondants
  List<List<dynamic>>? _cachedStudents;
  DateTime? _lastFetchTime;
  
  // Durée de validité du cache (5 minutes par défaut)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Crée une instance de [CafeRepository] avec le service injecté.
  CafeRepository(this._sheetsService);

  /// Vérifie si le cache local des étudiants est toujours valide.
  ///
  /// * Returns - `true` si les données sont présentes et fraîches (< 5 min).
  bool get _isCacheValid {
    return _cachedStudents != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  /// Invalide le cache local.
  ///
  /// Doit être appelé après toute opération d'écriture (Ajout d'étudiant) pour forcer
  /// un rafraîchissement des données lors de la prochaine lecture.
  void invalidateCache() {
    _cachedStudents = null;
    _lastFetchTime = null;
  }

  /// Récupère la liste des étudiants, en utilisant le cache si possible.
  ///
  /// * [forceRefresh] - Si `true`, ignore le cache et force un appel API.
  /// * Returns - Une liste de lignes (chaque ligne étant une liste de cellules).
  Future<List<List<dynamic>>?> getStudentsTable({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cachedStudents;
    }

    final data = await _sheetsService.readTable(AppConstants.studentsTable);
    if (data != null) {
      _cachedStudents = data;
      _lastFetchTime = DateTime.now();
    }
    return data;
  }

  /// Récupère les configurations de paiement.
  Future<List<PaymentConfig>> getPaymentConfigs() async {
    return await _sheetsService.getPaymentConfigs();
  }

  /// Ajoute un nouvel étudiant à la feuille 'Étudiants'.
  ///
  /// Cette méthode complexe gère :
  /// 1. Le calcul du numéro de la prochaine ligne disponible (basé sur le cache ou un fetch).
  /// 2. La construction de la ligne avec les formules Excel dynamiques (Calcul solde, fidélité...).
  /// 3. L'invalidation du cache après insertion.
  ///
  /// * [formData] - Map contenant les clés 'Nom', 'Prenom', 'Num etudiant', etc.
  Future<void> addStudent(Map<String, dynamic> formData) async {
    // Déterminer le numéro de ligne pour les formules
    int nextRow = 1;
    final currentData = await getStudentsTable();
    if (currentData != null && currentData.isNotEmpty) {
       // +1 pour l'index 0-based, +1 pour la nouvelle ligne
       // On suppose que la plage nommée inclut les en-têtes.
       nextRow = currentData.length + 1; 
    } else {
       // Fallback : on assume ligne 2 (la ligne 1 étant l'en-tête)
       nextRow = 2;
    }

    // Préparation des données avec injection des formules Excel
    // Les formules font référence à la ligne courante (nextRow)
    final List<dynamic> rowData = [
      formData['Nom'],
      formData['Prenom'],
      formData['Num etudiant'],
      formData['Cycle + groupe'],
      '=F$nextRow-G$nextRow+I$nextRow', // Solde Restant (Crédit - Dépense + Bonus)
      '=SIERREUR(SOMME.SI(Credit[Numéro étudiant];C$nextRow; Credit[Nb de Cafés]); 0)', // Total Crédité
      '=SIERREUR(SOMME.SI.ENS(Paiements[Nb de Cafés]; Paiements[Numéro étudiant]; C$nextRow; Paiements[Moyen Paiement]; "Crédit");0)', // Total Consommé sur Crédit
      '=SIERREUR(SOMME.SI.ENS(Paiements[Nb de Cafés]; Paiements[Numéro étudiant]; C$nextRow; Paiements[Moyen Paiement]; "<>Crédit"); 0)', // Total Payé Cash
      '=ENT((G$nextRow+H$nextRow)/10)', // Fidélité (1 café offert tous les 10)
    ];

    await _sheetsService.appendToTable(
      AppConstants.studentsTable, 
      rowData, 
      valueInputOption: 'USER_ENTERED',
    );
    
    // Le cache est obsolète car une ligne a été ajoutée
    invalidateCache();

    // Log de l'action
    await logAction('Inscription', '${formData['Nom']} ${formData['Prenom']}');
  }

  /// Ajoute une transaction de crédit (rechargement) dans la feuille 'Credits'.
  ///
  /// * [formData] - Map contenant les infos du crédit (Montant, date, responsable...).
  Future<void> addCreditRecord(Map<String, dynamic> formData) async {
     // Mappe les données du formulaire vers l'ordre exact des colonnes du Google Sheet
    final List<dynamic> rowData = [
      formData['Date'],
      formData['Responsable'],
      formData['Numéro étudiant'],
      formData['Nom'],
      formData['Prenom'],
      formData['Classe + Groupe'],
      formData['Valeur (€)'],
      formData['Nb de Cafés'],
      formData['Moyen Paiement'],
    ];

    await _sheetsService.appendToTable(AppConstants.creditsTable, rowData, valueInputOption: 'USER_ENTERED');
    
    // Log de l'action
    await logAction('Crédit', '${formData['Nom']} ${formData['Prenom']} : ${formData['Valeur (€)']}€ (${formData['Moyen Paiement']})');
  }

  /// Ajoute une commande (consommation) dans la feuille 'Paiements'.
  ///
  /// * [formData] - Map contenant les infos de la commande (Café pris, quantité, étudiant...).
  Future<void> addOrderRecord(Map<String, dynamic> formData) async {
    // Mappe les données vers l'ordre des colonnes de la table Paiements
    final List<dynamic> rowData = [
      formData['Date'],
      formData['Moyen Paiement'],
      formData['Nom de famille'],
      formData['Prénom'],
      formData['Numéro étudiant'],
      formData['Nb de Cafés'],
      formData['Café pris'],
    ];
    await _sheetsService.appendToTable(AppConstants.paymentsTable, rowData, valueInputOption: 'USER_ENTERED');

    // Log de l'action
    await logAction('Commande', '${formData['Nom de famille']} ${formData['Prénom']} : ${formData['Nb de Cafés']} café(s)');
  }

  /// Méthode générique pour lire n'importe quelle table sans logique métier spécifique.
  ///
  /// Utilisée pour charger les stocks, l'historique des paiements, etc.
  ///
  /// * [tableName] - Le nom de la table ou plage nommée.
  /// * [renderOption] - Option de rendu (ex: 'FORMULA').
  /// * Returns - Les données brutes ou null.
  Future<List<List<dynamic>>?> getGenericTable(String tableName, {String? renderOption}) async {
    return await _sheetsService.readTable(tableName, valueRenderOption: renderOption);
  }

  /// Met à jour la valeur d'une cellule spécifique.
  ///
  /// * [tableName] - Le nom de la table à mettre à jour.
  /// * [rowIndex] - L'index de la ligne de données (base 0, après l'en-tête).
  /// * [colIndex] - L'index de la colonne (base 0).
  /// * [newValue] - La nouvelle valeur.
  Future<void> updateCellValue(String tableName, int rowIndex, int colIndex, dynamic newValue) async {
    await _sheetsService.updateCell(tableName, rowIndex, colIndex, newValue);
  }

  /// Supprime une ligne d'une table donnée.
  ///
  /// * [tableName] - Le nom de la feuille.
  /// * [rowIndex] - L'index absolu de la ligne à supprimer (base 0, incluant l'en-tête si présent dans le contexte d'appel, mais ici attend l'index physique de la feuille).
  ///
  /// Note: Si la ligne index est 0 (header), cela supprimera le header.
  Future<void> deleteRow(String tableName, int rowIndex) async {
    await _sheetsService.deleteRow(tableName, rowIndex);
  }

  /// Ajoute une ligne générique à une table.
  Future<void> addGenericRow(String tableName, List<dynamic> rowData) async {
    await _sheetsService.appendToTable(tableName, rowData, valueInputOption: 'USER_ENTERED');
  }

  /// Enregistre une action dans la table 'Logs'.
  ///
  /// * [action] - Le type d'action (ex: "Ajout Étudiant").
  /// * [details] - Détails supplémentaires (ex: "Nom Prénom").
  Future<void> logAction(String action, String details) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);
      
      // Essayer de récupérer l'email de l'utilisateur connecté
      String user = 'Inconnu';
      if (_sheetsService.currentUser != null) {
        user = _sheetsService.currentUser!.email;
      }

      await _sheetsService.appendToTable(
        AppConstants.logsTable,
        [dateStr, user, action, details],
        valueInputOption: 'USER_ENTERED',
      );
    } catch (e) {
      // On ne veut pas que l'échec du log bloque l'action principale
      print('Erreur lors du logging: $e');
    }
  }
}