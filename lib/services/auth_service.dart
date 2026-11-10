import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  static Future<void> register(
      String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    await cred.user?.updateDisplayName(name.trim());
    await cred.user?.reload();
  }

  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> signOut() => _auth.signOut();

  /// Firebase xatolarini o'zbekchaga o'giradi.
  static String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Email manzil noto\'g\'ri.';
        case 'user-disabled':
          return 'Bu hisob bloklangan.';
        case 'user-not-found':
          return 'Bu email bilan hisob topilmadi. Avval ro\'yxatdan o\'ting.';
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return 'Email yoki parol noto\'g\'ri. Parol katta-kichik harfga '
              'sezgir. Eslay olmasangiz, "Parolni unutdingizmi?" tugmasini '
              'bosing. (${e.code})';
        case 'email-already-in-use':
          return 'Bu email allaqachon ro\'yxatdan o\'tgan.';
        case 'weak-password':
          return 'Parol juda oddiy (kamida 6 belgi).';
        case 'too-many-requests':
          return 'Juda ko\'p urinish. Birozdan keyin qayta urining.';
        case 'network-request-failed':
          return 'Internet aloqasi yo\'q.';
        case 'operation-not-allowed':
          return 'Firebase konsolida Email/Password kirish yoqilmagan.';
      }
      return '${e.message ?? 'Xatolik'} (${e.code})';
    }
    if (e is FirebaseException) {
      if (e.code == 'permission-denied') return 'Ruxsat yo\'q.';
      if (e.code == 'not-found') return 'Topilmadi.';
      return e.message ?? e.code;
    }
    return e.toString();
  }
}
