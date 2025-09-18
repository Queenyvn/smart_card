import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;


  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "106105989505-qpcjo56p5hbf4jg280d817gim70a3v1r.apps.googleusercontent.com",
  );

  Future<User?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser =
          await _googleSignIn.signInSilently();

      // If not signed in, fall back to popup login
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User cancelled the login
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential for Firebase 
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print("Google sign-in failed: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
