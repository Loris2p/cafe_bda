import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { purchase, topUp }

class CafeTransaction {
  final String id;
  final String studentId;
  final String studentName;
  final String responsibleId;
  final String responsibleName;
  final double amount; // Quantité de cafés ou montant en € selon le type
  final double price; // Montant total en €
  final TransactionType type;
  final String paymentMethod; // Lydia, Espèces, Crédit
  final String? productName;
  final DateTime timestamp;

  CafeTransaction({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.responsibleId,
    required this.responsibleName,
    required this.amount,
    required this.price,
    required this.type,
    required this.paymentMethod,
    this.productName,
    required this.timestamp,
  });

  factory CafeTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CafeTransaction(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      responsibleId: data['responsibleId'] ?? '',
      responsibleName: data['responsibleName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      price: (data['price'] ?? 0.0).toDouble(),
      type: data['type'] == 'topUp' ? TransactionType.topUp : TransactionType.purchase,
      paymentMethod: data['paymentMethod'] ?? '',
      productName: data['productName'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'responsibleId': responsibleId,
      'responsibleName': responsibleName,
      'amount': amount,
      'price': price,
      'type': type == TransactionType.topUp ? 'topUp' : 'purchase',
      'paymentMethod': paymentMethod,
      'productName': productName,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
