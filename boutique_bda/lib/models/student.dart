import 'package:cloud_firestore/cloud_firestore.dart';

/// Représente un étudiant (membre) du BDA.
class Student {
  /// Identifiant technique Firestore.
  final String id;
  
  final String firstName;
  final String lastName;
  
  /// Identifiant métier (ex: matricule). Utilisé comme clé primaire logique.
  final String studentId;
  
  /// Groupe ou promo (ex: "ING1").
  final String classGroup;
  
  /// Solde actuel en Euros.
  final double balance;
  
  /// Nombre de cafés offerts restants (issus de la fidélité).
  final int loyaltyBonus;
  
  /// Nombre cumulé de cafés achetés (sert au calcul de la fidélité).
  final int totalBought;
  
  /// Date de la dernière opération.
  final DateTime? lastTransactionAt;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.studentId,
    required this.classGroup,
    this.balance = 0.0,
    this.loyaltyBonus = 0,
    this.totalBought = 0,
    this.lastTransactionAt,
  });

  /// Construit un objet [Student] depuis un document Firestore.
  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      studentId: data['studentId'] ?? '',
      classGroup: data['classGroup'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      loyaltyBonus: data['loyaltyBonus'] ?? 0,
      totalBought: data['totalBought'] ?? 0,
      lastTransactionAt: (data['lastTransactionAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convertit l'étudiant en Map pour Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'studentId': studentId,
      'classGroup': classGroup,
      'balance': balance,
      'loyaltyBonus': loyaltyBonus,
      'totalBought': totalBought,
      'lastTransactionAt': lastTransactionAt != null ? Timestamp.fromDate(lastTransactionAt!) : null,
    };
  }

  String get fullName => '$firstName $lastName';
}
