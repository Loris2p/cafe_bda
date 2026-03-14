import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_store;
import 'package:firedart/firedart.dart' as fd_store;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/student.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/payment_method.dart';
import '../core/utils.dart';

/// Service central gérant toutes les opérations de données avec Firebase Firestore.
/// 
/// Ce service utilise une architecture hybride pour supporter :
/// 1. Le mode "Desktop Native" (Windows/Linux) via le package [firedart].
/// 2. Le mode "Standard" (Android/iOS/Web) via le SDK officiel [cloud_firestore].
class FirebaseService {
  /// Indique si l'application tourne sur un bureau (hors Web).
  static bool get isDesktopNative => !kIsWeb && (Platform.isLinux || Platform.isWindows);

  /// Vérifie si l'appareil est connecté à Internet.
  Future<bool> isConnected() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }

  // --- STATISTIQUES ---

  /// Récupère les statistiques globales via les agrégations Firestore (si disponible).
  Future<Map<String, dynamic>> getGlobalStats() async {
    if (isDesktopNative) {
      // Firedart ne supporte pas encore les agrégations natives
      // On simule en récupérant les transactions récentes (comportement actuel)
      final docs = await fd_store.Firestore.instance.collection('transactions').get();
      double totalRevenue = 0;
      int totalCount = 0;
      for (var doc in docs) {
        if (doc['type'] == 'purchase') {
          totalRevenue += (doc['price'] ?? 0.0).toDouble();
          totalCount += ((doc['amount'] ?? 0) as num).toInt();
        }
      }
      return {
        'totalRevenue': totalRevenue,
        'totalCount': totalCount,
      };
    } else {
      // Utilisation des agrégations natives Firestore (Optimisé et gratuit < 1000/jour)
      final collection = fb_store.FirebaseFirestore.instance.collection('transactions');
      final query = collection.where('type', isEqualTo: 'purchase');
      
      final aggregateSnapshot = await query.aggregate(
        fb_store.sum('price'),
        fb_store.sum('amount'),
        fb_store.count(),
      ).get();

      return {
        'totalRevenue': aggregateSnapshot.getSum('price') ?? 0.0,
        'totalItems': aggregateSnapshot.getSum('amount') ?? 0.0,
        'totalCount': aggregateSnapshot.count ?? 0,
      };
    }
  }

  // --- ÉTUDIANTS ---

  /// Récupère le flux des étudiants inscrits.
  /// Note: Sur Desktop, le flux est simulé à partir d'un Future unique.
  Stream<List<Student>> getStudents() {
    if (isDesktopNative) {
      return Stream.fromFuture(fd_store.Firestore.instance.collection('students').get()).map(
            (docs) => docs.map((doc) => _studentFromFiredart(doc)).toList(),
          );
    } else {
      return fb_store.FirebaseFirestore.instance.collection('students').orderBy('lastName').snapshots().map(
            (snapshot) => snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList(),
          );
    }
  }

  /// Ajoute un nouvel étudiant. L'ID du document est son N° Étudiant (studentId).
  Future<void> addStudent(Student student) {
    if (isDesktopNative) {
      return fd_store.Firestore.instance.collection('students').document(student.studentId).set(student.toFirestore());
    } else {
      return fb_store.FirebaseFirestore.instance.collection('students').doc(student.studentId).set(student.toFirestore());
    }
  }

  /// Met à jour les informations d'un étudiant.
  Future<void> updateStudent(Student student) {
    if (isDesktopNative) {
      return fd_store.Firestore.instance.collection('students').document(student.id).update(student.toFirestore());
    } else {
      return fb_store.FirebaseFirestore.instance.collection('students').doc(student.id).update(student.toFirestore());
    }
  }

  // --- PRODUITS (CATALOGUE) ---

  /// Récupère la liste des produits disponibles ou non.
  Stream<List<Product>> getProducts() {
    if (isDesktopNative) {
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
    if (isDesktopNative) {
      return fd_store.Firestore.instance.collection('products').add(product.toFirestore());
    } else {
      return fb_store.FirebaseFirestore.instance.collection('products').add(product.toFirestore());
    }
  }

  Future<void> updateProduct(Product product) {
    if (isDesktopNative) {
      return fd_store.Firestore.instance.collection('products').document(product.id).update(product.toFirestore());
    } else {
      return fb_store.FirebaseFirestore.instance.collection('products').doc(product.id).update(product.toFirestore());
    }
  }

  // --- MÉTHODES DE PAIEMENT ---

  /// Récupère les configurations de paiement (Lydia, Espèces, etc.).
  Stream<List<PaymentMethod>> getPaymentMethods() {
    if (isDesktopNative) {
      return Stream.fromFuture(fd_store.Firestore.instance.collection('payment_methods').get()).map(
            (docs) => docs.map((doc) => PaymentMethod.fromMap(doc.id, doc.map)).toList(),
          );
    } else {
      return fb_store.FirebaseFirestore.instance.collection('payment_methods').snapshots().map(
            (snapshot) => snapshot.docs.map((doc) => PaymentMethod.fromFirestore(doc)).toList(),
          );
    }
  }

  Future<void> addPaymentMethod(PaymentMethod method) {
    if (isDesktopNative) {
      return fd_store.Firestore.instance.collection('payment_methods').add(method.toFirestore());
    } else {
      return fb_store.FirebaseFirestore.instance.collection('payment_methods').add(method.toFirestore());
    }
  }

  Future<void> updatePaymentMethod(PaymentMethod method) {
    if (isDesktopNative) {
      return fd_store.Firestore.instance.collection('payment_methods').document(method.id).update(method.toFirestore());
    } else {
      return fb_store.FirebaseFirestore.instance.collection('payment_methods').doc(method.id).update(method.toFirestore());
    }
  }

  Future<void> deletePaymentMethod(String id) {
    if (isDesktopNative) {
      return fd_store.Firestore.instance.collection('payment_methods').document(id).delete();
    } else {
      return fb_store.FirebaseFirestore.instance.collection('payment_methods').doc(id).delete();
    }
  }

  // --- TRANSACTIONS & LOGIQUE MÉTIER ---

  /// Enregistre une vente ou un rechargement et met à jour le solde de l'étudiant.
  /// 
  /// Applique la logique de fidélité : 1 crédit de 0.50€ offert tous les 10 cafés achetés.
  Future<void> addTransaction(CafeTransaction transaction) async {
    if (isDesktopNative) {
      // Version Desktop : Opérations séquentielles
      await fd_store.Firestore.instance.collection('transactions').add(transaction.toFirestore());
      
      final studentRef = fd_store.Firestore.instance.collection('students').document(transaction.studentId);
      final studentDoc = await studentRef.get();
      
      final double currentBalance = parseDouble(studentDoc['balance']);
      final int currentTotalBought = parseInt(studentDoc['totalBought']);
      final int currentLoyaltyBonus = parseInt(studentDoc['loyaltyBonus']);
      
      double balanceChange = 0;
      int boughtChange = 0;
      int bonusChange = 0;

      if (transaction.type == TransactionType.purchase) {
        boughtChange = transaction.amount.toInt();
        if (transaction.paymentMethod == 'Crédit') {
          balanceChange = -transaction.price;
        }
        // Calcul du bonus fidélité (nb de tranches de 10 atteintes)
        int newTotalBought = currentTotalBought + boughtChange;
        bonusChange = (newTotalBought ~/ 10) - (currentTotalBought ~/ 10);
        balanceChange += (bonusChange * 0.50);
      } else {
        balanceChange = transaction.amount;
      }

      await studentRef.update({
        'balance': currentBalance + balanceChange,
        'totalBought': currentTotalBought + boughtChange,
        'loyaltyBonus': currentLoyaltyBonus + bonusChange,
      });
    } else {
      // Version Mobile/Web : Transaction Firestore atomique
      return fb_store.FirebaseFirestore.instance.runTransaction((transactionObj) async {
        final studentRef = fb_store.FirebaseFirestore.instance.collection('students').doc(transaction.studentId);
        final studentSnapshot = await transactionObj.get(studentRef);
        if (!studentSnapshot.exists) throw Exception("Étudiant introuvable");

        final studentData = studentSnapshot.data()!;
        final double currentBalance = parseDouble(studentData['balance']);
        final int currentTotalBought = parseInt(studentData['totalBought']);
        final int currentLoyaltyBonus = parseInt(studentData['loyaltyBonus']);

        double balanceChange = 0;
        int boughtChange = 0;
        int bonusChange = 0;

        if (transaction.type == TransactionType.purchase) {
          boughtChange = transaction.amount.toInt();
          if (transaction.paymentMethod == 'Crédit') {
            balanceChange = -transaction.price;
          }
          int newTotalBought = currentTotalBought + boughtChange;
          bonusChange = (newTotalBought ~/ 10) - (currentTotalBought ~/ 10);
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

  /// Récupère l'historique paginé des transactions.
  Stream<List<CafeTransaction>> getRecentTransactions({int limit = 20}) {
    if (isDesktopNative) {
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

  // --- UTILISATEURS DE L'APP ---

  /// Initialise le document Firestore d'un nouvel utilisateur.
  Future<void> createUserDocument(String uid, String email, String name, bool mustChangePassword) {
    final data = {
      'email': email,
      'displayName': name,
      'mustChangePassword': mustChangePassword,
    };
    if (isDesktopNative) {
      return fd_store.Firestore.instance.collection('users').document(uid).set(data);
    } else {
      return fb_store.FirebaseFirestore.instance.collection('users').doc(uid).set({
        ...data,
        'createdAt': fb_store.FieldValue.serverTimestamp(),
      });
    }
  }

  /// Récupère le profil utilisateur.
  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    try {
      if (isDesktopNative) {
        final doc = await fd_store.Firestore.instance.collection('users').document(uid).get();
        return doc.map;
      } else {
        final doc = await fb_store.FirebaseFirestore.instance.collection('users').doc(uid).get();
        return doc.data();
      }
    } catch (e) {
      return null;
    }
  }

  /// Active ou désactive l'obligation de changement de mot de passe.
  Future<void> updateUserPasswordFlag(String uid, bool mustChangePassword) {
    final data = {'mustChangePassword': mustChangePassword};
    if (isDesktopNative) {
      return fd_store.Firestore.instance.collection('users').document(uid).update(data);
    } else {
      return fb_store.FirebaseFirestore.instance.collection('users').doc(uid).update(data);
    }
  }

  // --- CONTRÔLE DE VERSION ---

  /// Récupère le numéro de la dernière version publiée.
  Future<String?> getLatestVersion() async {
    try {
      if (isDesktopNative) {
        final doc = await fd_store.Firestore.instance.collection('config').document('app_version').get();
        return doc.map['latest'];
      } else {
        final doc = await fb_store.FirebaseFirestore.instance.collection('config').doc('app_version').get();
        return doc.data()?['latest'] as String?;
      }
    } catch (e) {
      return null;
    }
  }

  /// Met à jour la version de référence sur le serveur.
  Future<void> updateRemoteVersion(String version) {
    final data = {'latest': version};
    if (isDesktopNative) {
      return fd_store.Firestore.instance.collection('config').document('app_version').set({
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } else {
      return fb_store.FirebaseFirestore.instance.collection('config').doc('app_version').set({
        ...data,
        'updatedAt': fb_store.FieldValue.serverTimestamp(),
      });
    }
  }

  // --- HELPERS DE CONVERSION ---

  Student _studentFromFiredart(fd_store.Document doc) {
    return Student(
      id: doc.id,
      firstName: doc['firstName'] ?? '',
      lastName: doc['lastName'] ?? '',
      studentId: doc['studentId'] ?? '',
      classGroup: doc['classGroup'] ?? '',
      balance: (doc['balance'] ?? 0.0).toDouble(),
      loyaltyBonus: (doc['loyaltyBonus'] ?? 0).toInt(),
      totalBought: (doc['totalBought'] ?? 0).toInt(),
      lastTransactionAt: parseFirestoreDate(doc['lastTransactionAt']),
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
      timestamp: parseRequiredFirestoreDate(doc['timestamp']),
    );
  }
}
