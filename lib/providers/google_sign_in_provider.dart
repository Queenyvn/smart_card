import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'google_sign_in/google_sign_in.dart';

class GoogleSignInProvider {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    Future<User?> signInWithGoogle() async {
        try {
            // Google Sign-In Process
            final GoogleSignInAccount? googleUser =  
            await _googleSignIn.signIn();
            if (googleUser == null) return null;

            // Get authentication details
            final GoggleSignInAuthentication googleAuth = 
            await googleUser.authentication;

            // Create a new credential firebase
            final AuthCredential credential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
            );

            // Sign with firebase
            final UserCredential userCredential = 
            await _auth.signInWithCredential(credential);

            return userCredential.user;
        } catch (e)  {
            debugPrint("Error during Google Sign-In: $e");
            return null;
        }
    }
    Future<void> signOut() async {
        await _auth.signOut();
        await _googleSignIn.signOut();
    }
}