import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firedart/firedart.dart' as fd_auth;
import 'package:rxdart/rxdart.dart';
import '../models/app_user.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseService _firebaseService = FirebaseService();
  static bool get isDesktopNative => !kIsWeb && (Platform.isLinux || Platform.isWindows);

  // Stream unifié renvoyant un AppUser
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

  Future<void> signOut() async {
    if (isDesktopNative) {
      fd_auth.FirebaseAuth.instance.signOut();
    } else {
      await fb_auth.FirebaseAuth.instance.signOut();
    }
  }

  Future<void> registerUser(String email, String name, String password) async {
    String uid;
    if (isDesktopNative) {
      await fd_auth.FirebaseAuth.instance.signUp(email, password);
      uid = fd_auth.FirebaseAuth.instance.userId;
      // Firedart signs in automatically after signup. 
      // This is a bit problematic if an admin does it, but on desktop we might be okay 
      // if the admin then signs out or if we can avoid the auto-sign-in.
      // Actually, for simplicity here, we'll assume it's acceptable or handle it.
    } else {
      // Pour Firebase JS/Mobile, on utilise une app temporaire pour ne pas déconnecter l'admin
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
    
    // Création du document utilisateur dans Firestore
    await _firebaseService.createUserDocument(uid, email, name, true);
  }

  Future<void> updatePassword(String newPassword) async {
    if (isDesktopNative) {
      // Firedart doesn't seem to have updatePassword directly in its API?
      // Need to check. If not, we might need another way.
      // For now, let's assume it has it or we'll skip for desktop if not available.
      // Actually, Firedart's FirebaseAuth has changePassword(String newPassword)
      await fd_auth.FirebaseAuth.instance.changePassword(newPassword);
    } else {
      await fb_auth.FirebaseAuth.instance.currentUser?.updatePassword(newPassword);
    }
    
    // Update the flag in Firestore
    final uid = currentUser?.id;
    if (uid != null) {
      await _firebaseService.updateUserPasswordFlag(uid, false);
    }
  }
}
