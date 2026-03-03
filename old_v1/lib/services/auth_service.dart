import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    _googleSignIn = GoogleSignIn(
      clientId: !isAndroid ? dotenv.env['GOOGLE_WEB_CLIENT_ID'] : null,
      scopes: [
        'email',
        'https://www.googleapis.com/auth/spreadsheets',
      ],
    );
  }

  Stream<User?> get user => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? _accessToken;
  String? get accessToken => _accessToken;

  Future<User?> signInWithGoogle() async {
    try {
      // 1. Déclencher le flux d'authentification Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // L'utilisateur a annulé

      // 2. Obtenir les détails d'authentification de la demande
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      _accessToken = googleAuth.accessToken;

      // 3. Créer un nouvel identifiant Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Une fois connecté, renvoyer l'utilisateur Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Erreur AuthService.signInWithGoogle: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Erreur AuthService.signOut: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      await _auth.signOut();
    } catch (e) {
      print('Erreur AuthService.disconnect: $e');
    }
  }

  Future<User?> signInSilently() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        _accessToken = googleAuth.accessToken;
        
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
      return _auth.currentUser;
    } catch (e) {
      print('Erreur AuthService.signInSilently: $e');
      return null;
    }
  }
}
