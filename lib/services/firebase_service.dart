import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/cafe_transaction.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Récupère la liste complète des étudiants depuis Firestore
  /// (Dénormalisée pour être compatible avec votre interface actuelle)
  Future<List<List<dynamic>>> getStudentsForTable() async {
    try {
      final snapshot = await _db.collection('students').get();
      
      // On commence avec l'en-tête (pour rester compatible avec votre UI existante)
      List<List<dynamic>> rows = [[
        'Nom', 'Prénom', 'Num etudiant', 'Cycle + groupe', 
        'Solde Restant', 'Total Crédité', 'Total Consommé sur Crédit', 
        'Total Payé Cash', 'Fidélité (Bonus)'
      ]];

      final List<Student> students = snapshot.docs
          .map((doc) => Student.fromFirestore(doc))
          .toList();

      // Ajout des lignes d'étudiants
      rows.addAll(students.map((s) => s.toSheetsRow()));
      
      return rows;
    } catch (e) {
      print('Erreur Firestore (getStudentsForTable): $e');
      rethrow;
    }
  }

  /// Recherche un étudiant par son ID
  Future<Student?> getStudentById(String studentId) async {
    try {
      final doc = await _db.collection('students').doc(studentId).get();
      if (!doc.exists) return null;
      return Student.fromFirestore(doc);
    } catch (e) {
      print('Erreur Firestore (getStudentById): $e');
      return null;
    }
  }

  /// Met à jour un étudiant dans Firestore
  Future<void> updateStudent(Student student) async {
    try {
      await _db.collection('students').doc(student.studentId).set(student.toFirestore());
    } catch (e) {
      print('Erreur Firestore (updateStudent): $e');
      rethrow;
    }
  }

  /// Ajoute un nouvel étudiant
  Future<void> addStudent(Student student) async {
    try {
      await _db.collection('students').doc(student.studentId).set(student.toFirestore());
    } catch (e) {
      print('Erreur Firestore (addStudent): $e');
      rethrow;
    }
  }

  /// Ajoute une transaction dans Firestore
  Future<void> addTransaction(CafeTransaction transaction) async {
    try {
      await _db.collection('transactions').add(transaction.toFirestore());
    } catch (e) {
      print('Erreur Firestore (addTransaction): $e');
      rethrow;
    }
  }
}
