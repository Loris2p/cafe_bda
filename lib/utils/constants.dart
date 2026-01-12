/// Contient les valeurs constantes utilisées dans toute l'application.
///
/// L'utilisation de constantes centralisées permet d'éviter les fautes de frappe ("Magic Strings")
/// et facilite la maintenance si le nom d'une table ou d'un champ venait à changer.
class AppConstants {
  // --- Noms des Feuilles (Onglets) Google Sheets ---
  
  static const String studentsTable = 'Étudiants';
  static const String creditsTable = 'Credits';
  static const String paymentsTable = 'Paiements';
  static const String stockTable = 'Stocks';
  static const String infosPaiementTable = 'InfosPaiement';

  // --- Clés des champs du formulaire d'inscription ---
  
  static const String regFormName = 'Nom';
  static const String regFormFirstName = 'Prenom';
  static const String regFormStudentId = 'Num etudiant';
  static const String regFormClass = 'Cycle + groupe';

  // --- Clés des champs du formulaire de crédit ---
  
  static const String creditFormDate = 'Date';
  static const String creditFormManager = 'Responsable';
  static const String creditFormStudentId = 'Numéro étudiant';
  static const String creditFormName = 'Nom';
  static const String creditFormFirstName = 'Prenom';
  static const String creditFormClass = 'Classe + Groupe';
  static const String creditFormValue = 'Valeur (€)';
  static const String creditFormCoffees = 'Nb de Cafés';
  static const String creditFormPaymentMethod = 'Moyen Paiement';

  // --- Clés des champs du formulaire de commande ---
  
  static const String orderFormDate = 'Date';
  static const String orderFormPaymentMethod = 'Moyen Paiement';
  static const String orderFormLastName = 'Nom de famille';
  static const String orderFormFirstName = 'Prénom';
  static const String orderFormStudentId = 'Numéro étudiant';
  static const String orderFormCoffees = 'Nb de Cafés';
  static const String applicationTable = 'Application';

  // Sécurité
  static const String adminPin = '1234'; // Code PIN par défaut pour le mode Admin
}