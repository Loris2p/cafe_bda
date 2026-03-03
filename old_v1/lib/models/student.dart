import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String studentId;
  final String lastName;
  final String firstName;
  final String classGroup;
  final double balance;
  final double totalCredited;
  final double totalConsumedOnCredit;
  final double totalPaidCash;
  final int loyaltyBonus;
  final DateTime? lastUpdated;

  Student({
    required this.studentId,
    required this.lastName,
    required this.firstName,
    required this.classGroup,
    required this.balance,
    required this.totalCredited,
    required this.totalConsumedOnCredit,
    required this.totalPaidCash,
    required this.loyaltyBonus,
    this.lastUpdated,
  });

  /// Crée un objet Student à partir d'un document Firestore
  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Student(
      studentId: data['studentId'] ?? '',
      lastName: data['lastName'] ?? '',
      firstName: data['firstName'] ?? '',
      classGroup: data['classGroup'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      totalCredited: (data['totalCredited'] ?? 0.0).toDouble(),
      totalConsumedOnCredit: (data['totalConsumedOnCredit'] ?? 0.0).toDouble(),
      totalPaidCash: (data['totalPaidCash'] ?? 0.0).toDouble(),
      loyaltyBonus: (data['loyaltyBonus'] ?? 0).toInt(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  /// Convertit un Student en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'lastName': lastName,
      'firstName': firstName,
      'classGroup': classGroup,
      'balance': balance,
      'totalCredited': totalCredited,
      'totalConsumedOnCredit': totalConsumedOnCredit,
      'totalPaidCash': totalPaidCash,
      'loyaltyBonus': loyaltyBonus,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// Utile pour transformer un Student en ligne pour vos Widgets existants (DataTable)
  List<dynamic> toSheetsRow() {
    return [
      lastName,
      firstName,
      studentId,
      classGroup,
      balance,
      totalCredited,
      totalConsumedOnCredit,
      totalPaidCash,
      loyaltyBonus,
    ];
  }
}
