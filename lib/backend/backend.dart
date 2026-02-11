import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// ========================================================
/// GENERIC RESULT MODEL
/// ========================================================
class BackendResult {
  final bool success;
  final String? message;

  BackendResult({required this.success, this.message});
}



/// ========================================================
/// CALENDAR MODELS
/// ========================================================
class CalendarEvent {
  final String title;
  final String venue;
  final String description;
  final String? imageUrl;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool approved;

  CalendarEvent({
    required this.title,
    required this.venue,
    required this.description,
    this.imageUrl,
    required this.startTime,
    required this.endTime,
    required this.approved,
  });
}

class UpcomingEvent {
  final DateTime date;
  final CalendarEvent event;

  UpcomingEvent({required this.date, required this.event});
}





/// ========================================================
/// CENTRAL BACKEND SERVICE
/// ========================================================
class BackendService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  
static List<CalendarEvent> getEventsForDay(DateTime day) {
  return [];
}

// =========================================================
// LOGIN
// =========================================================

static Future<BackendResult> login({
  required String username,
  required String password,
}) async {
  // DEV MODE LOGIN
  if (kDebugMode) {
    if (username == 'dev' && password == 'dev') {
      await Future.delayed(const Duration(milliseconds: 500));
      return BackendResult(success: true);
    }
    return BackendResult(success: false, message: 'DEV MODE: use username: dev, password: dev');
  }
  
  try {
    String emailToUse = username.trim();
    
    // If username doesn't contain @, look it up in Firestore
    if (!username.contains('@')) {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return BackendResult(
          success: false,
          message: "Username not found.",
        );
      }
      
      emailToUse = querySnapshot.docs.first.data()['email'];
    }
    
    // Authenticate with Firebase
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: emailToUse,
      password: password.trim(),
    );

    // Check if user document exists in Firestore
    final userDoc = await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    
    if (!userDoc.exists) {
      await _auth.signOut();
      return BackendResult(
        success: false,
        message: "User profile not found. Please contact administrator.",
      );
    }

    //  get the approved field with null check
    final userData = userDoc.data();
    if (userData == null || userData['approved'] != true) {
      await _auth.signOut();
      return BackendResult(
        success: false,
        message: "Account not yet approved by admin.",
      );
    }

    return BackendResult(success: true);
    
  } on FirebaseAuthException catch (e) {
    // user-friendly error messages pag tanga yung user input or may ibang auth issues
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = "No account found with this email.";
        break;
      case 'wrong-password':
        message = "Incorrect password.";
        break;
      case 'invalid-email':
        message = "Invalid email format.";
        break;
      case 'user-disabled':
        message = "This account has been disabled.";
        break;
      case 'invalid-credential':
        message = "Invalid email or password.";
        break;
      default:
        message = "Login failed: ${e.message}";
    }
    return BackendResult(success: false, message: message);
    
  } catch (e) {
    return BackendResult(
      success: false,
      message: "An error occurred: ${e.toString()}",
    );
  }
}

// =========================================================
// REGISTRATION
// =========================================================
static Future<BackendResult> registerUserForApproval({
  required String username,
  required String email,
  required String password,
  required String address,
  required String userType,
  String? businessName,
  String? businessNature,
  String? professionalTitle,
}) async {
  try {
    // Check if username already exists
    final usernameCheck = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();
    
    if (usernameCheck.docs.isNotEmpty) {
      return BackendResult(
        success: false,
        message: "Username already taken. Please choose another.",
      );
    }

    // Create Firebase Authentication account
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // Save user info in Firestore with approved = false
    await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'username': username.trim(),
      'email': email.trim(),
      'address': address.trim(),
      'userType': userType,
      'businessName': businessName?.trim(),
      'businessNature': businessNature?.trim(),
      'professionalTitle': professionalTitle?.trim(),
      'approved': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return BackendResult(success: true);
    
  } on FirebaseAuthException catch (e) {
    String message;
    switch (e.code) {
      case 'email-already-in-use':
        message = "This email is already registered.";
        break;
      case 'invalid-email':
        message = "Invalid email format.";
        break;
      case 'weak-password':
        message = "Password is too weak.";
        break;
      default:
        message = "Registration failed: ${e.message}";
    }
    return BackendResult(success: false, message: message);
    
  } catch (e) {
    return BackendResult(
      success: false,
      message: "An error occurred: ${e.toString()}",
    );
  }
}


  /// ========================================================
  /// SUBMIT EVENT (USER to ADMIN APPROVAL)
  /// ========================================================
  static Future<String> submitEventForApproval({
    required String title,
    required String venue,
    required String description,
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    required String? posterUrl,
    required int availableSlots,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in'); // an accoxnt must be logged in to submit an event
    }

    final normalizedDate = DateTime(date.year, date.month, date.day);

    final docRef = await _firestore.collection('events').add({
      'title': title.trim(),
      'venue': venue.trim(),
      'description': description.trim(),
      'imageUrl': posterUrl,
      'date': Timestamp.fromDate(normalizedDate),
      'startHour': start.hour,
      'startMinute': start.minute,
      'endHour': end.hour,
      'endMinute': end.minute,
      'approved': false,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'availableSlots': availableSlots,
    });

    return docRef.id;
  }

  /// ========================================================
  /// APPROVED EVENTS STREAM (FOR CALENDAR)
  /// ========================================================
  static Stream<List<UpcomingEvent>> approvedEventsStream() {
    return _firestore
        .collection('events')
        .where('approved', isEqualTo: true) // filter only approved events 
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final d = doc.data();
        final date = (d['date'] as Timestamp).toDate();

        return UpcomingEvent(
          date: date,
          event: CalendarEvent(
            title: d['title'],
            venue: d['venue'],
            description: d['description'],
            imageUrl: d['imageUrl'],
            startTime: TimeOfDay(
              hour: d['startHour'],
              minute: d['startMinute'],
            ),
            endTime: TimeOfDay(
              hour: d['endHour'],
              minute: d['endMinute'],
            ),
            approved: true,
          ),
        );
      }).toList();
    });
  }

  /// ========================================================
  /// USER NOTIFICATION (EVENT APPROVED)
  /// ========================================================
  static Stream<QuerySnapshot> userApprovalNotifications() {
    return _firestore
        .collection('events')
        .where('createdBy', isEqualTo: _auth.currentUser!.uid) 
        .where('approved', isEqualTo: true)
        .snapshots();
  }

  /// ========================================================
  /// EVENT ATTENDANCE
  /// ========================================================
  static Future<BackendResult> attendEvent({
    required CalendarEvent event,
    required DateTime date,
  }) async {
    try {
      await _firestore.collection('event_attendance').add({
        'uid': _auth.currentUser!.uid,
        'eventTitle': event.title,
        'venue': event.venue,
        'date': Timestamp.fromDate(date),
        'status': 'attending',
        'createdAt': Timestamp.now(),
      });

      return BackendResult(success: true);
    } catch (e) {
      return BackendResult(success: false, message: e.toString());
    }
  }


  // ========================================================
  // PROFILE METHODS
  // ========================================================
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return doc.data();
  }

  static Future<BackendResult> saveUserProfile({
    required String name,
    required String phone,
    required String address,
    Map<String, dynamic>? location,
    List<Map<String, dynamic>>? businesses,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'businesses': businesses,
      }, SetOptions(merge: true));

      return BackendResult(success: true);
    } catch (e) {
      return BackendResult(success: false, message: e.toString());
    }
  }  
}


