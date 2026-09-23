import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/app_user.dart';
import 'firebase_service.dart';

/// Service gérant l'authentification des utilisateurs de l'application via le SDK officiel Firebase Auth.
class AuthService {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Flux unifié émettant l'utilisateur actuellement connecté ([AppUser]).
  /// Enrichit les données de base (Firebase Auth) avec les métadonnées de Firestore.
  Stream<AppUser?> get user {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user != null) {
        final userDoc = await _firebaseService.getUserDocument(user.uid);
        return AppUser(
          id: user.uid,
          email: user.email,
          displayName: userDoc?['displayName'] ?? user.displayName,
          mustChangePassword: userDoc?['mustChangePassword'] ?? false,
        );
      }
      return null;
    });
  }

  /// Récupère l'utilisateur actuel de manière synchrone (données minimales).
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user != null) {
      return AppUser(id: user.uid, email: user.email, displayName: user.displayName);
    }
    return null;
  }

  /// Connecte un utilisateur via email/mot de passe.
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Déconnecte l'utilisateur actuel.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Envoie un email de réinitialisation de mot de passe.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Inscrit un nouvel utilisateur sans déconnecter l'administrateur actuel.
  Future<void> registerUser(String email, String name, String password) async {
    // Création via une instance secondaire pour ne pas perdre la session admin
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'TempApp-${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    String uid;
    try {
      final credential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);
      uid = credential.user!.uid;
      await credential.user?.updateDisplayName(name);
    } finally {
      await tempApp.delete();
    }
    
    // Initialisation du document utilisateur dans Firestore
    await _firebaseService.createUserDocument(uid, email, name, true); // true pour forcer le changement au 1er login
  }

  /// Met à jour le mot de passe de l'utilisateur actuel et lève le flag [mustChangePassword].
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
    
    final uid = currentUser?.id;
    if (uid != null) {
      await _firebaseService.updateUserPasswordFlag(uid, false);
    }
  }
}
