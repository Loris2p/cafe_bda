import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils.dart';

/// Type de transaction financière.
enum TransactionType { purchase, topUp }

/// Représente une opération (vente ou rechargement) effectuée dans la boutique.
class CafeTransaction {
  final String id;
  
  /// Client concerné.
  final String studentId;
  final String studentName;
  
  /// Administrateur ayant effectué l'opération.
  final String responsibleId;
  final String responsibleName;
  
  /// Quantité (nb produits) pour une vente, ou Montant (€) pour un rechargement.
  final double amount;
  
  /// Montant total TTC en Euros de l'opération.
  final double price;
  
  final TransactionType type;
  
  /// Méthode de règlement (Lydia, Espèces, Crédit, Autre...).
  final String paymentMethod;
  
  /// Nom du produit vendu (si type == purchase).
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
      amount: parseDouble(data['amount']),
      price: parseDouble(data['price']),
      type: data['type'] == 'topUp' ? TransactionType.topUp : TransactionType.purchase,
      paymentMethod: data['paymentMethod'] ?? '',
      productName: data['productName'],
      timestamp: parseRequiredFirestoreDate(data['timestamp']),
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
      'timestamp': timestamp,
    };
  }
}
