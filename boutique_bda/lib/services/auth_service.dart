import 'dart:io' show Platform;
import 'dart:convert' show jsonEncode, jsonDecode;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firedart/firedart.dart' as fd_auth;
import 'package:rxdart/rxdart.dart';
import '../models/app_user.dart';
import 'firebase_service.dart';
import '../firebase_options.dart';

/// Service gérant l'authentification des utilisateurs de l'application.
/// 
/// Supporte nativement :
/// - [firedart] pour le Desktop.
/// - [firebase_auth] pour Mobile/Web.
class AuthService {
  final FirebaseService _firebaseService = FirebaseService();
  
  /// Indique si l'application tourne sur un bureau (hors Web).
  static bool get isDesktopNative => !kIsWeb && (Platform.isLinux || Platform.isWindows);

  /// Flux unifié émettant l'utilisateur actuellement connecté ([AppUser]).
  /// Enrichit les données de base (Firebase Auth) avec les métadonnées de Firestore.
  Stream<AppUser?> get user {
    if (isDesktopNative) {
      return fd_auth.FirebaseAuth.instance.signInState
          .asyncMap((isSignedIn) async {
            if (isSignedIn) {
              final uid = fd_auth.FirebaseAuth.instance.userId;
              final userDoc = await _firebaseService.getUserDocument(uid);
              try {
                final user = await fd_auth.FirebaseAuth.instance.getUser();
                return AppUser(
                  id: user.id,
                  email: user.email,
                  displayName: userDoc?['displayName'] ?? user.displayName,
                  mustChangePassword: userDoc?['mustChangePassword'] ?? false,
                );
              } catch (e) {
                // Repli si le profil Auth n'est pas accessible
                return AppUser(
                  id: uid,
                  displayName: userDoc?['displayName'],
                  mustChangePassword: userDoc?['mustChangePassword'] ?? false,
                );
              }
            }
            return null;
          })
          .startWith(currentUser)
          .distinct();
    } else {
      return fb_auth.FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
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
  }

  /// Récupère l'utilisateur actuel de manière synchrone (données minimales).
  AppUser? get currentUser {
    if (isDesktopNative) {
      if (fd_auth.FirebaseAuth.instance.isSignedIn) {
        return AppUser(id: fd_auth.FirebaseAuth.instance.userId);
      }
      return null;
    } else {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        return AppUser(id: user.uid, email: user.email, displayName: user.displayName);
      }
      return null;
    }
  }

  /// Connecte un utilisateur via email/mot de passe.
  Future<void> signInWithEmail(String email, String password) async {
    if (isDesktopNative) {
      await fd_auth.FirebaseAuth.instance.signIn(email, password);
    } else {
      await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  }

  /// Déconnecte l'utilisateur actuel.
  Future<void> signOut() async {
    if (isDesktopNative) {
      fd_auth.FirebaseAuth.instance.signOut();
    } else {
      await fb_auth.FirebaseAuth.instance.signOut();
    }
  }

  /// Envoie un email de réinitialisation de mot de passe.
  Future<void> sendPasswordResetEmail(String email) async {
    if (isDesktopNative) {
      // Utilisation de l'API REST Firebase Identity Toolkit car Firedart ne le supporte pas
      final apiKey = DefaultFirebaseOptions.windows.apiKey;
      final url = 'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$apiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestType': 'PASSWORD_RESET',
          'email': email,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de l\'envoi du mail de réinitialisation : ${response.body}');
      }
    } else {
      await fb_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    }
  }

  /// Inscrit un nouvel utilisateur sans déconnecter l'administrateur actuel.
  Future<void> registerUser(String email, String name, String password) async {
    String uid;
    if (isDesktopNative) {
      // Sur Desktop, on utilise l'API REST directement pour créer le compte
      // Cela évite que Firedart ne nous connecte automatiquement avec le nouveau compte
      final apiKey = DefaultFirebaseOptions.windows.apiKey;
      final url = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la création du compte : ${response.body}');
      }
      
      final data = jsonDecode(response.body);
      uid = data['localId'];
    } else {
      // Création via une instance secondaire pour ne pas perdre la session admin
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempApp-${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      try {
        final credential = await fb_auth.FirebaseAuth.instanceFor(app: tempApp)
            .createUserWithEmailAndPassword(email: email, password: password);
        uid = credential.user!.uid;
        await credential.user?.updateDisplayName(name);
      } finally {
        await tempApp.delete();
      }
    }
    
    // Initialisation du document utilisateur dans Firestore
    await _firebaseService.createUserDocument(uid, email, name, false);

    // Envoyer immédiatement un email de réinitialisation
    await sendPasswordResetEmail(email);
  }

  /// Met à jour le mot de passe de l'utilisateur actuel et lève le flag [mustChangePassword].
  Future<void> updatePassword(String newPassword) async {
    if (isDesktopNative) {
      await fd_auth.FirebaseAuth.instance.changePassword(newPassword);
    } else {
      await fb_auth.FirebaseAuth.instance.currentUser?.updatePassword(newPassword);
    }
    
    final uid = currentUser?.id;
    if (uid != null) {
      await _firebaseService.updateUserPasswordFlag(uid, false);
    }
  }
}
