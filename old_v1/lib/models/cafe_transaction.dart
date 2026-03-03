import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { purchase, topUp }

class CafeTransaction {
  final String id;
  final TransactionType type;
  final DateTime date;
  final String studentId;
  final String studentName;
  final double amount;
  final String paymentMethod;
  final String productName;
  final String responsible;

  CafeTransaction({
    required this.id,
    required this.type,
    required this.date,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.paymentMethod,
    this.productName = '',
    required this.responsible,
  });

  /// Convertit une CafeTransaction en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'type': type == TransactionType.purchase ? 'purchase' : 'top-up',
      'date': Timestamp.fromDate(date),
      'studentId': studentId,
      'studentName': studentName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'productName': productName,
      'responsible': responsible,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Crée un objet CafeTransaction à partir d'un document Firestore
  factory CafeTransaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CafeTransaction(
      id: doc.id,
      type: data['type'] == 'purchase' ? TransactionType.purchase : TransactionType.topUp,
      date: (data['date'] as Timestamp).toDate(),
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      productName: data['productName'] ?? '',
      responsible: data['responsible'] ?? '',
    );
  }
}
