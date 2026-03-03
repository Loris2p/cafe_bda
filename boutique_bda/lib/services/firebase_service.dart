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
      // Firedart ne supporte pas les streams sur les collections, on simule un stream one-shot
      return Stream.fromFuture(fd_store.Firestore.instance.collection('students').get()).map(
            (docs) => docs.map((doc) => _studentFromFiredart(doc)).toList(),
          );
    } else {
      return fb_store.FirebaseFirestore.instance.collection('students').orderBy('lastName').snapshots().map(
            (snapshot) => snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList(),
          );
    }
  }

  Future<void> addStudent(Student student) {
    if (isLinuxNative) {
      return fd_store.Firestore.instance.collection('students').add(student.toFirestore());
    } else {
      return fb_store.FirebaseFirestore.instance.collection('students').add(student.toFirestore());
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

  // --- Transactions ---
  Future<void> addTransaction(CafeTransaction transaction) async {
    if (isLinuxNative) {
      await fd_store.Firestore.instance.collection('transactions').add(transaction.toFirestore());
      
      final studentRef = fd_store.Firestore.instance.collection('students').document(transaction.studentId);
      final studentDoc = await studentRef.get();
      final currentBalance = (studentDoc['balance'] ?? 0.0).toDouble();
      
      double change = transaction.type == TransactionType.topUp ? transaction.amount : -transaction.amount;
      await studentRef.update({'balance': currentBalance + change});
    } else {
      final batch = fb_store.FirebaseFirestore.instance.batch();
      final transRef = fb_store.FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(transRef, transaction.toFirestore());

      final studentRef = fb_store.FirebaseFirestore.instance.collection('students').doc(transaction.studentId);
      double balanceChange = transaction.type == TransactionType.topUp ? transaction.amount : -transaction.amount;
      
      batch.update(studentRef, {
        'balance': fb_store.FieldValue.increment(balanceChange),
        'lastTransactionAt': fb_store.FieldValue.serverTimestamp(),
      });
      return batch.commit();
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

  // --- Helpers de conversion ---
  Student _studentFromFiredart(fd_store.Document doc) {
    return Student(
      id: doc.id,
      firstName: doc['firstName'] ?? '',
      lastName: doc['lastName'] ?? '',
      studentId: doc['studentId'] ?? '',
      classGroup: doc['classGroup'] ?? '',
      balance: (doc['balance'] ?? 0.0).toDouble(),
      loyaltyBonus: doc['loyaltyBonus'] ?? 0,
      lastTransactionAt: doc['lastTransactionAt'],
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
      timestamp: doc['timestamp'] ?? DateTime.now(),
    );
  }
}
