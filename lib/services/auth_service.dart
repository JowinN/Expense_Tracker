import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/models.dart';

abstract class AuthService {
  Stream<AppUser?> get onAuthStateChanged;
  AppUser? get currentUser;
  Future<AppUser?> loginWithEmailAndPassword(String email, String password);
  Future<AppUser?> registerWithEmailAndPassword(String email, String name, String password);
  Future<void> signOut();
  bool get isMock;
}

class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  @override
  bool get isMock => false;

  AppUser? _userFromFirebase(fb.User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? user.email?.split('@').first ?? 'User',
      photoUrl: user.photoURL,
    );
  }

  @override
  Stream<AppUser?> get onAuthStateChanged {
    return _auth.authStateChanges().map(_userFromFirebase);
  }

  @override
  AppUser? get currentUser {
    return _userFromFirebase(_auth.currentUser);
  }

  @override
  Future<AppUser?> loginWithEmailAndPassword(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _userFromFirebase(credential.user);
  }

  @override
  Future<AppUser?> registerWithEmailAndPassword(
      String email, String name, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    // Reload user to fetch updated displayName
    await credential.user?.reload();
    return _userFromFirebase(_auth.currentUser);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
