import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_store;
import 'package:firedart/firedart.dart' as fd_store;
import '../models/student.dart';
import '../models/product.dart';
import '../models/transaction.dart';

class FirebaseService {
  static bool get isLinuxNative => !kIsWeb && Platform.isLinux;

  // --- Students ---
  Stream<List<Student>> getStudents() {
    if (isLinuxNative) {
      return Stream.fromFuture(fd_store.Firestore.instance.collection('students').get()).map(
            (docs) {
              return docs.map((doc) => _studentFromFiredart(doc)).toList();
            },
          );
    } else {
      return fb_store.FirebaseFirestore.instance.collection('students').orderBy('lastName').snapshots().map(
            (snapshot) => snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList(),
          );
    }
  }

  Future<void> addStudent(Student student) {
    if (isLinuxNative) {
      return fd_store.Firestore.instance.collection('students').document(student.studentId).set(student.toFirestore());
    } else {
      return fb_store.FirebaseFirestore.instance.collection('students').doc(student.studentId).set(student.toFirestore());
    }
  }

  Future<void> updateStudent(Student student) {
    if (isLinuxNative) {
      return fd_store.Firestore.instance.collection('students').document(student.id).update(student.toFirestore());
    } else {
      return fb_store.FirebaseFirestore.instance.collection('students').doc(student.id).update(student.toFirestore());
    }
  }

  // --- Products ---
  Stream<List<Product>> getProducts() {
    if (isLinuxNative) {
      return Stream.fromFuture(fd_store.Firestore.instance.collection('products').get()).map(
            (docs) => docs.map((doc) => _productFromFiredart(doc)).toList(),
          );
    } else {
      return fb_store.FirebaseFirestore.instance.collection('products').snapshots().map(
            (snapshot) => snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
          );
    }
  }

  Future<void> addProduct(Product product) {
    if (isLinuxNative) {
      return fd_store.Firestore.instance.collection('products').add(product.toFirestore());
    } else {
      return fb_store.FirebaseFirestore.instance.collection('products').add(product.toFirestore());
    }
  }

  Future<void> updateProduct(Product product) {
    if (isLinuxNative) {
      return fd_store.Firestore.instance.collection('products').document(product.id).update(product.toFirestore());
    } else {
      return fb_store.FirebaseFirestore.instance.collection('products').doc(product.id).update(product.toFirestore());
    }
  }

  // --- Transactions ---
  Future<void> addTransaction(CafeTransaction transaction) async {
    if (isLinuxNative) {
      await fd_store.Firestore.instance.collection('transactions').add(transaction.toFirestore());
      
      final studentRef = fd_store.Firestore.instance.collection('students').document(transaction.studentId);
      final studentDoc = await studentRef.get();
      
      final currentBalance = (studentDoc['balance'] ?? 0.0).toDouble();
      final currentTotalBought = (studentDoc['totalBought'] ?? 0).toInt();
      
      double balanceChange = 0;
      int boughtChange = 0;
      int bonusChange = 0;

      if (transaction.type == TransactionType.purchase) {
        boughtChange = transaction.amount.toInt();
        if (transaction.paymentMethod == 'Crédit') {
          // IMPORTANT: On retire le PRIX (Euros) et non l'amount (Quantité)
          balanceChange = -transaction.price;
        }
        // Calcul fidélité : 1 café offert (valeur 0.50€) tous les 10 achetés
        int newTotalBought = currentTotalBought + boughtChange;
        int nBonus = (newTotalBought ~/ 10).toInt();
        int cBonus = (currentTotalBought ~/ 10).toInt();
        bonusChange = nBonus - cBonus;
        balanceChange += (bonusChange * 0.50); // Le bonus crédite 0.50€ par café offert
      } else {
        balanceChange = transaction.amount; // En rechargement, amount = Euros
      }

      await studentRef.update({
        'balance': currentBalance + balanceChange,
        'totalBought': currentTotalBought + boughtChange,
        'loyaltyBonus': (studentDoc['loyaltyBonus'] ?? 0) + bonusChange,
      });
    } else {
      return fb_store.FirebaseFirestore.instance.runTransaction((transactionObj) async {
        final studentRef = fb_store.FirebaseFirestore.instance.collection('students').doc(transaction.studentId);
        final studentSnapshot = await transactionObj.get(studentRef);
        if (!studentSnapshot.exists) throw Exception("Étudiant introuvable");

        final studentData = studentSnapshot.data()!;
        final currentBalance = (studentData['balance'] ?? 0.0).toDouble();
        final currentTotalBought = (studentData['totalBought'] ?? 0).toInt();
        final currentLoyaltyBonus = (studentData['loyaltyBonus'] ?? 0).toInt();

        double balanceChange = 0;
        int boughtChange = 0;
        int bonusChange = 0;

        if (transaction.type == TransactionType.purchase) {
          boughtChange = transaction.amount.toInt();
          if (transaction.paymentMethod == 'Crédit') {
            balanceChange = -transaction.price; // On retire le PRIX (Euros)
          }
          int newTotalBought = currentTotalBought + boughtChange;
          int nBonus = (newTotalBought ~/ 10).toInt();
          int cBonus = (currentTotalBought ~/ 10).toInt();
          bonusChange = nBonus - cBonus;
          balanceChange += (bonusChange * 0.50);
        } else {
          balanceChange = transaction.amount;
        }

        final transRef = fb_store.FirebaseFirestore.instance.collection('transactions').doc();
        transactionObj.set(transRef, transaction.toFirestore());

        transactionObj.update(studentRef, {
          'balance': currentBalance + balanceChange,
          'totalBought': currentTotalBought + boughtChange,
          'loyaltyBonus': currentLoyaltyBonus + bonusChange,
          'lastTransactionAt': fb_store.FieldValue.serverTimestamp(),
        });
      });
    }
  }

  Stream<List<CafeTransaction>> getRecentTransactions({int limit = 20}) {
    if (isLinuxNative) {
      return Stream.fromFuture(fd_store.Firestore.instance.collection('transactions').get()).map(
            (docs) => docs.map((doc) => _transactionFromFiredart(doc)).toList(),
          );
    } else {
      return fb_store.FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map((doc) => CafeTransaction.fromFirestore(doc)).toList(),
          );
    }
  }

  // --- Helpers ---
  Student _studentFromFiredart(fd_store.Document doc) {
    DateTime? lastTx;
    final rawDate = doc['lastTransactionAt'];
    if (rawDate != null) {
      if (rawDate is DateTime) lastTx = rawDate;
      else if (rawDate is String) lastTx = DateTime.tryParse(rawDate);
    }

    return Student(
      id: doc.id,
      firstName: doc['firstName'] ?? '',
      lastName: doc['lastName'] ?? '',
      studentId: doc['studentId'] ?? '',
      classGroup: doc['classGroup'] ?? '',
      balance: (doc['balance'] ?? 0.0).toDouble(),
      loyaltyBonus: (doc['loyaltyBonus'] ?? 0).toInt(),
      totalBought: (doc['totalBought'] ?? 0).toInt(),
      lastTransactionAt: lastTx,
    );
  }

  Product _productFromFiredart(fd_store.Document doc) {
    return Product(
      id: doc.id,
      name: doc['name'] ?? '',
      price: (doc['price'] ?? 0.0).toDouble(),
      isAvailable: doc['isAvailable'] ?? true,
      category: doc['category'] ?? 'Café',
    );
  }

  CafeTransaction _transactionFromFiredart(fd_store.Document doc) {
    DateTime? ts;
    final rawDate = doc['timestamp'];
    if (rawDate != null) {
      if (rawDate is DateTime) ts = rawDate;
      else if (rawDate is String) ts = DateTime.tryParse(rawDate);
    }

    return CafeTransaction(
      id: doc.id,
      studentId: doc['studentId'] ?? '',
      studentName: doc['studentName'] ?? '',
      responsibleId: doc['responsibleId'] ?? '',
      responsibleName: doc['responsibleName'] ?? '',
      amount: (doc['amount'] ?? 0.0).toDouble(),
      price: (doc['price'] ?? 0.0).toDouble(),
      type: doc['type'] == 'topUp' ? TransactionType.topUp : TransactionType.purchase,
      paymentMethod: doc['paymentMethod'] ?? '',
      productName: doc['productName'],
      timestamp: ts ?? DateTime.now(),
    );
  }
}
