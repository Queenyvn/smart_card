import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
/// BUSINESS PIN MODEL — used by the map widget
/// Each business inside a user's `businesses` array becomes one pin
/// ========================================================
class BusinessPin {
  final String uid;
  final String name;          // owner's name
  final String businessName;  // the business name
  final String userType;      // e.g. "Business Owner"
  final String email;
  final String phone;
  final double lat;
  final double lng;
  final String address;
  final String? logoUrl;
  final String businessDesc;

  BusinessPin({
    required this.uid,
    required this.name,
    required this.businessName,
    required this.userType,
    required this.email,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.address,
    this.logoUrl,
    this.businessDesc = '',
  });
}

/// ========================================================
/// CENTRAL BACKEND SERVICE
/// ========================================================
class BackendService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static List<CalendarEvent> getEventsForDay(DateTime day) => [];

  // =========================================================
  // LOGIN
  // =========================================================
  static Future<BackendResult> login({
    required String username,
    required String password,
  }) async {
    if (kDebugMode) {
      if (username == 'dev' && password == 'dev') {
        await Future.delayed(const Duration(milliseconds: 500));
        return BackendResult(success: true);
      }
      return BackendResult(
          success: false,
          message: 'DEV MODE: use username: dev, password: dev');
    }

    try {
      String emailToUse = username.trim();

      if (!username.contains('@')) {
        final querySnapshot = await _firestore
            .collection('users')
            .where('username', isEqualTo: username.trim())
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          return BackendResult(success: false, message: "Username not found.");
        }
        emailToUse = querySnapshot.docs.first.data()['email'];
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password.trim(),
      );

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

      final userData = userDoc.data();
      if (userData == null || userData['approved'] != true) {
        await _auth.signOut();
        return BackendResult(
            success: false, message: "Account not yet approved by admin.");
      }

      return BackendResult(success: true);
    } on FirebaseAuthException catch (e) {
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
      return BackendResult(success: false, message: "An error occurred: ${e.toString()}");
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
    Uint8List? dtiFileBytes,
    String? dtiFileName,
  }) async {
    try {
      final usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        return BackendResult(
            success: false,
            message: "Username already taken. Please choose another.");
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String? dtiUrl;
      if (dtiFileBytes != null && dtiFileName != null) {
        try {
          dtiUrl = await _uploadToCloudinary(dtiFileBytes, dtiFileName);
        } catch (e) {
          await userCredential.user!.delete();
          return BackendResult(
              success: false,
              message: "Failed to upload DTI document: ${e.toString()}");
        }
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username.trim(),
        'email': email.trim(),
        'address': address.trim(),
        'userType': userType,
        'businessName': businessName?.trim(),
        'businessNature': businessNature?.trim(),
        'professionalTitle': professionalTitle?.trim(),
        'dtiDocumentUrl': dtiUrl,
        'dtiFileName': dtiFileName,
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
      return BackendResult(success: false, message: "An error occurred: ${e.toString()}");
    }
  }

  // =========================================================
  // SUBMIT EVENT
  // =========================================================
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
    if (user == null) throw Exception('User not logged in');

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

  // =========================================================
  // APPROVED EVENTS STREAM
  // =========================================================
  static Stream<List<UpcomingEvent>> approvedEventsStream() {
    return _firestore
        .collection('events')
        .where('approved', isEqualTo: true)
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
            startTime: TimeOfDay(hour: d['startHour'], minute: d['startMinute']),
            endTime: TimeOfDay(hour: d['endHour'], minute: d['endMinute']),
            approved: true,
          ),
        );
      }).toList();
    });
  }

  // =========================================================
  // USER NOTIFICATION
  // =========================================================
  static Stream<QuerySnapshot> userApprovalNotifications() {
    return _firestore
        .collection('events')
        .where('createdBy', isEqualTo: _auth.currentUser!.uid)
        .where('approved', isEqualTo: true)
        .snapshots();
  }

  // =========================================================
  // EVENT ATTENDANCE
  // =========================================================
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

  // =========================================================
  // PROFILE METHODS
  // =========================================================
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
        'businesses': businesses,
      }, SetOptions(merge: true));

      return BackendResult(success: true);
    } catch (e) {
      return BackendResult(success: false, message: e.toString());
    }
  }

  // =========================================================
  // SAVE BUSINESS LOCATION (top-level, for backward compat)
  // =========================================================
  static Future<BackendResult> saveBusinessLocation({
    required double lat,
    required double lng,
    required String address,
    String? logoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).set({
        'location': {'lat': lat, 'lng': lng, 'address': address.trim()},
        'logoUrl': logoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return BackendResult(success: true);
    } catch (e) {
      return BackendResult(success: false, message: e.toString());
    }
  }

  // =========================================================
  // FETCH CAVITE BUSINESS PINS
  // Reads from businesses[] array (new) with top-level location fallback (old)
  // =========================================================
  static Future<List<BusinessPin>> fetchCaviteBusinessPins() async {
    const double minLat = 14.10;
    const double maxLat = 14.50;
    const double minLng = 120.60;
    const double maxLng = 121.10;

    final snapshot = await _firestore
        .collection('users')
        .where('approved', isEqualTo: true)
        .get();

    final List<BusinessPin> pins = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      bool addedFromBusinesses = false;

      // ── PRIMARY: Read each business in businesses[] array ──
      final businesses = data['businesses'];
      if (businesses != null && businesses is List) {
        for (final b in businesses) {
          if (b is! Map) continue;

          final lat = (b['lat'] as num?)?.toDouble();
          final lng = (b['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;
          if (lat < minLat || lat > maxLat ||
              lng < minLng || lng > maxLng) continue;

          final businessName = (b['name'] as String?)?.isNotEmpty == true
              ? b['name'] as String
              : (data['businessName'] as String? ??
                  data['name'] as String? ??
                  'Unknown');

          final logo = (b['logoUrl'] as String?)?.isNotEmpty == true
              ? b['logoUrl'] as String
              : data['logoUrl'] as String?;

          final addr = (b['address'] as String?)?.isNotEmpty == true
              ? b['address'] as String
              : ((data['location'] as Map?)?['address'] as String? ??
                  data['address'] as String? ??
                  '');

          pins.add(BusinessPin(
            uid: doc.id,
            name: data['name'] as String? ?? '',
            businessName: businessName,
            userType: data['userType'] as String? ?? '',
            email: data['email'] as String? ?? '',
            phone: (b['phone'] as String?)?.isNotEmpty == true
                ? b['phone'] as String
                : (data['phone'] as String? ?? ''),
            lat: lat,
            lng: lng,
            address: addr,
            logoUrl: logo,
            businessDesc: b['desc'] as String? ?? '',
          ));
          addedFromBusinesses = true;
        }
      }

      // ── FALLBACK: top-level location field (old data structure) ──
      if (!addedFromBusinesses) {
        final loc = data['location'];
        if (loc is Map) {
          final lat = (loc['lat'] as num?)?.toDouble();
          final lng = (loc['lng'] as num?)?.toDouble();
          if (lat != null && lng != null &&
              lat >= minLat && lat <= maxLat &&
              lng >= minLng && lng <= maxLng) {
            pins.add(BusinessPin(
              uid: doc.id,
              name: data['name'] as String? ?? '',
              businessName: data['businessName'] as String? ??
                  data['name'] as String? ??
                  'Unknown',
              userType: data['userType'] as String? ?? '',
              email: data['email'] as String? ?? '',
              phone: data['phone'] as String? ?? '',
              lat: lat,
              lng: lng,
              address: loc['address'] as String? ??
                  data['address'] as String? ??
                  '',
              logoUrl: data['logoUrl'] as String?,
              businessDesc: '',
            ));
          }
        }
      }
    }

    return pins;
  }

  // =========================================================
  // UPLOAD LOGO
  // =========================================================
  static Future<String?> uploadLogoImage(Uint8List bytes, String fileName) async {
    try {
      return await _uploadToCloudinary(
        bytes,
        fileName,
        folder: 'business_logos',
        resourceType: 'image',
      );
    } catch (e) {
      return null;
    }
  }

  // =========================================================
  // CLOUDINARY UPLOAD HELPER
  // =========================================================
  static Future<String> _uploadToCloudinary(
    Uint8List fileBytes,
    String fileName, {
    String folder = 'dti_documents',
    String resourceType = 'raw',
  }) async {
    const cloudName = 'Ydfwe9loex';
    const uploadPreset = 'smartcard';

    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');

    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;
    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = json.decode(responseString);
      return jsonMap['secure_url'];
    } else {
      throw Exception(
          'Cloudinary upload failed with status: ${response.statusCode}');
    }
  }
}