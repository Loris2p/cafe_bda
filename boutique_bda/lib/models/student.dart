import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String studentId;
  final String classGroup;
  final double balance;
  final int loyaltyBonus;
  final int totalBought; // Nombre total de cafés achetés
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
