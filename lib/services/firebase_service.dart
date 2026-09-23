import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/student.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/payment_method.dart';
import '../core/utils.dart';

/// Service central gérant toutes les opérations de données avec Firebase Firestore
/// via le SDK officiel [cloud_firestore].
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Vérifie si l'appareil est connecté à Internet.
  Future<bool> isConnected() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }

  // --- STATISTIQUES ---

  /// Récupère les statistiques globales via les agrégations Firestore natives.
  Future<Map<String, dynamic>> getGlobalStats() async {
    final collection = _firestore.collection('transactions');
    
    // On récupère tout ce qui est identifié comme achat (a un produit)
    final purchaseQuery = collection.where('productName', isNull: false);
    final purchaseSnapshot = await purchaseQuery.aggregate(
      sum('price'),
      sum('amount'),
      count(),
    ).get();

    // On récupère le TOTAL global pour déduire les rechargements
    final totalSnapshot = await collection.aggregate(
      sum('price'),
    ).get();

    final purchaseRev = purchaseSnapshot.getSum('price') ?? 0.0;
    final globalRev = totalSnapshot.getSum('price') ?? 0.0;

    return {
      'totalRevenue': purchaseRev,
      'totalItems': purchaseSnapshot.getSum('amount') ?? 0.0,
      'totalCount': purchaseSnapshot.count ?? 0,
      'totalCredits': globalRev - purchaseRev, // Le reste est du rechargement
    };
  }

  // --- ÉTUDIANTS ---

  /// Récupère le flux des étudiants inscrits, triés par nom.
  Stream<List<Student>> getStudents() {
    return _firestore
        .collection('students')
        .orderBy('lastName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList(),
        );
  }

  /// Ajoute un nouvel étudiant. L'ID du document est son N° Étudiant (studentId).
  Future<void> addStudent(Student student) {
    return _firestore.collection('students').doc(student.studentId).set(student.toFirestore());
  }

  /// Met à jour les informations d'un étudiant.
  Future<void> updateStudent(Student student) {
    return _firestore.collection('students').doc(student.id).update(student.toFirestore());
  }

  // --- PRODUITS (CATALOGUE) ---

  /// Récupère la liste des produits en temps réel.
  Stream<List<Product>> getProducts() {
    return _firestore.collection('products').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
        );
  }

  /// Ajoute un produit au catalogue.
  Future<void> addProduct(Product product) {
    return _firestore.collection('products').add(product.toFirestore());
  }

  /// Met à jour les données d'un produit existant.
  Future<void> updateProduct(Product product) {
    return _firestore.collection('products').doc(product.id).update(product.toFirestore());
  }

  /// Transfère une quantité de produit de la Réserve vers le Bureau de manière atomique.
  Future<void> transferStock({required String productId, required int quantity}) async {
    if (quantity <= 0) return;
    final docRef = _firestore.collection('products').doc(productId);
    return _firestore.runTransaction((transactionObj) async {
      final snap = await transactionObj.get(docRef);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final currentBureau = parseInt(data['stockBureau'], 0);
      final currentReserve = parseInt(data['stockReserve'], 0);
      final actualTransfer = quantity.clamp(0, currentReserve);
      transactionObj.update(docRef, {
        'stockBureau': currentBureau + actualTransfer,
        'stockReserve': currentReserve - actualTransfer,
      });
    });
  }

  /// Ajoute du stock (arrivage fournisseur) en Réserve ou au Bureau.
  Future<void> restockProduct({required String productId, required int quantity, bool toReserve = true}) async {
    if (quantity <= 0) return;
    final field = toReserve ? 'stockReserve' : 'stockBureau';
    final docRef = _firestore.collection('products').doc(productId);
    await docRef.update({
      field: FieldValue.increment(quantity),
    });
  }

  /// Met à jour manuellement les stocks d'un produit.
  Future<void> updateProductStocks({
    required String productId,
    required int stockBureau,
    required int stockReserve,
  }) async {
    final cleanBureau = stockBureau < 0 ? 0 : stockBureau;
    final cleanReserve = stockReserve < 0 ? 0 : stockReserve;
    await _firestore.collection('products').doc(productId).update({
      'stockBureau': cleanBureau,
      'stockReserve': cleanReserve,
    });
  }

  /// Met à jour en lot tous les stocks lors d'un inventaire physique.
  Future<void> batchUpdateInventory(Map<String, ({int bureau, int reserve})> inventory) async {
    final batch = _firestore.batch();
    for (final entry in inventory.entries) {
      final docRef = _firestore.collection('products').doc(entry.key);
      batch.update(docRef, {
        'stockBureau': entry.value.bureau < 0 ? 0 : entry.value.bureau,
        'stockReserve': entry.value.reserve < 0 ? 0 : entry.value.reserve,
      });
    }
    await batch.commit();
  }

  // --- MÉTHODES DE PAIEMENT ---

  /// Récupère les configurations de paiement (Lydia, Espèces, etc.).
  Stream<List<PaymentMethod>> getPaymentMethods() {
    return _firestore.collection('payment_methods').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => PaymentMethod.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addPaymentMethod(PaymentMethod method) {
    return _firestore.collection('payment_methods').add(method.toFirestore());
  }

  Future<void> updatePaymentMethod(PaymentMethod method) {
    return _firestore.collection('payment_methods').doc(method.id).update(method.toFirestore());
  }

  Future<void> deletePaymentMethod(String id) {
    return _firestore.collection('payment_methods').doc(id).delete();
  }

  // --- TRANSACTIONS & LOGIQUE MÉTIER ---

  /// Enregistre une vente ou un rechargement et met à jour le solde de l'étudiant
  /// via une transaction Firestore atomique.
  /// 
  /// Applique la logique de fidélité : 1 crédit de 0.50€ offert tous les 10 cafés achetés.
  Future<void> addTransaction(CafeTransaction transaction) async {
    return _firestore.runTransaction((transactionObj) async {
      final studentRef = _firestore.collection('students').doc(transaction.studentId);
      final studentSnapshot = await transactionObj.get(studentRef);
      if (!studentSnapshot.exists) throw Exception("Étudiant introuvable");

      DocumentReference? productRef;
      DocumentSnapshot? productSnapshot;
      if (transaction.type == TransactionType.purchase && transaction.productId != null && transaction.productId!.isNotEmpty) {
        productRef = _firestore.collection('products').doc(transaction.productId);
        productSnapshot = await transactionObj.get(productRef);
      }

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

      final transRef = _firestore.collection('transactions').doc();
      transactionObj.set(transRef, transaction.toFirestore());

      transactionObj.update(studentRef, {
        'balance': currentBalance + balanceChange,
        'totalBought': currentTotalBought + boughtChange,
        'loyaltyBonus': currentLoyaltyBonus + bonusChange,
        'lastTransactionAt': FieldValue.serverTimestamp(),
      });

      // Décrémentation du stock bureau si produit spécifié et suivi de stock actif
      if (productRef != null && productSnapshot != null && productSnapshot.exists) {
        final productData = (productSnapshot.data() as Map<String, dynamic>?) ?? {};
        final bool track = productData['trackStock'] ?? true;
        if (track) {
          final int currentBureau = parseInt(productData['stockBureau'], 0);
          final int newBureau = currentBureau - transaction.amount.toInt();
          transactionObj.update(productRef, {
            'stockBureau': newBureau < 0 ? 0 : newBureau,
          });
        }
      }
    });
  }

  /// Récupère l'historique paginé des transactions en temps réel.
  Stream<List<CafeTransaction>> getRecentTransactions({int limit = 20}) {
    return _firestore
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => CafeTransaction.fromFirestore(doc)).toList(),
        );
  }

  // --- UTILISATEURS DE L'APP ---

  /// Initialise le document Firestore d'un nouvel utilisateur.
  Future<void> createUserDocument(String uid, String email, String name, bool mustChangePassword) {
    return _firestore.collection('users').doc(uid).set({
      'email': email,
      'displayName': name,
      'mustChangePassword': mustChangePassword,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Récupère le profil utilisateur.
  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Active ou désactive l'obligation de changement de mot de passe.
  Future<void> updateUserPasswordFlag(String uid, bool mustChangePassword) {
    return _firestore.collection('users').doc(uid).update({
      'mustChangePassword': mustChangePassword,
    });
  }

  // --- CONTRÔLE DE VERSION ---

  /// Récupère le numéro de la dernière version publiée.
  Future<String?> getLatestVersion() async {
    try {
      final doc = await _firestore.collection('config').doc('app_version').get();
      return doc.data()?['latest'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Met à jour la version de référence sur le serveur.
  Future<void> updateRemoteVersion(String version) {
    return _firestore.collection('config').doc('app_version').set({
      'latest': version,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
