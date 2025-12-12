/// Contains constant values used throughout the application.
///
/// Using constants helps to avoid typos and makes the code more maintainable.
class AppConstants {
  // Table names
  static const String studentsTable = 'Étudiants';
  static const String creditsTable = 'Credits';
  static const String paymentsTable = 'Paiements';
  static const String stockTable = 'Stocks';

  // Form field keys for registration
  static const String regFormName = 'Nom';
  static const String regFormFirstName = 'Prenom';
  static const String regFormStudentId = 'Num etudiant';
  static const String regFormClass = 'Cycle + groupe';

  // Form field keys for credit
  static const String creditFormDate = 'Date';
  static const String creditFormManager = 'Responsable';
  static const String creditFormStudentId = 'Numéro étudiant';
  static const String creditFormName = 'Nom';
  static const String creditFormFirstName = 'Prenom';
  static const String creditFormClass = 'Classe + Groupe';
  static const String creditFormValue = 'Valeur (€)';
  static const String creditFormCoffees = 'Nb de Cafés';
  static const String creditFormPaymentMethod = 'Moyen Paiement';

  // Form field keys for order
  static const String orderFormDate = 'Date';
  static const String orderFormPaymentMethod = 'Moyen Paiement';
  static const String orderFormLastName = 'Nom de famille';
  static const String orderFormFirstName = 'Prénom';
  static const String orderFormStudentId = 'Numéro étudiant';
  static const String orderFormCoffees = 'Nb de Cafés';
  static const String orderFormCoffeeTaken = 'Café pris';
}
