import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firedart/firedart.dart' as fd_auth;
import 'package:rxdart/rxdart.dart';
import '../models/app_user.dart';

class AuthService {
  static bool get isDesktopNative => !kIsWeb && (Platform.isLinux || Platform.isWindows);

  // Stream unifié renvoyant un AppUser
  Stream<AppUser?> get user {
    if (isDesktopNative) {
      // Pour Firedart, on transforme le stream de bool en stream d'AppUser
      // et on s'assure qu'il émet l'état actuel immédiatement au démarrage.
      return fd_auth.FirebaseAuth.instance.signInState
          .asyncMap((isSignedIn) async {
            if (isSignedIn) {
              try {
                final user = await fd_auth.FirebaseAuth.instance.getUser();
                return AppUser(
                  id: user.id,
                  email: user.email,
                  displayName: user.displayName,
                );
              } catch (e) {
                // En cas d'erreur de récupération du profil, on renvoie au moins l'ID
                return AppUser(id: fd_auth.FirebaseAuth.instance.userId);
              }
            }
            return null;
          })
          .startWith(currentUser) // Émission immédiate de l'état actuel
          .distinct();
    } else {
      return fb_auth.FirebaseAuth.instance.authStateChanges().map((user) {
        if (user != null) {
          return AppUser(
            id: user.uid,
            email: user.email,
            displayName: user.displayName,
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
}
