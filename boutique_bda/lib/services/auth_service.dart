import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firedart/firedart.dart' as fd_auth;
import '../models/app_user.dart';

class AuthService {
  static bool get isLinuxNative => !kIsWeb && Platform.isLinux;

  // Stream unifié renvoyant un AppUser
  Stream<AppUser?> get user {
    if (isLinuxNative) {
      return fd_auth.FirebaseAuth.instance.signInState.map((isSignedIn) {
        if (isSignedIn) {
          // Firedart ne donne pas toujours l'email dans le stream, on peut le récupérer si besoin
          return AppUser(id: fd_auth.FirebaseAuth.instance.userId);
        }
        return null;
      });
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
    if (isLinuxNative) {
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
    if (isLinuxNative) {
      await fd_auth.FirebaseAuth.instance.signIn(email, password);
    } else {
      await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  }

  Future<void> signOut() async {
    if (isLinuxNative) {
      fd_auth.FirebaseAuth.instance.signOut();
    } else {
      await fb_auth.FirebaseAuth.instance.signOut();
    }
  }
}
