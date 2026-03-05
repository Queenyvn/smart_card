import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
// NOTE: dart:io and firebase_storage are intentionally NOT imported.
// All file uploads (logos, posts, chat images/files) use Cloudinary via
// _uploadToCloudinary(), which accepts Uint8List and works on web + mobile.

/// ========================================================
/// GENERIC RESULT MODEL
/// ========================================================
class BackendResult {
  final bool success;
  final String? message;
  BackendResult({required this.success, this.message});
}

/// ========================================================
/// PROFILE STATUS
/// ========================================================
enum ProfileStatus {
  notFound,
  pendingApproval,
  approvedExists,
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
  final String id;
  final DateTime date;
  final CalendarEvent event;
  final int availableSlots;
  UpcomingEvent({
    required this.id,
    required this.date,
    required this.event,
    required this.availableSlots,
  });
}

/// ========================================================
/// USER SUBMITTED EVENT MODEL
/// ========================================================
class UserSubmittedEvent {
  final String id;
  final String title;
  final String venue;
  final String description;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String status;
  final int availableSlots;
  final String? posterUrl;

  UserSubmittedEvent({
    required this.id,
    required this.title,
    required this.venue,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.availableSlots,
    this.posterUrl,
  });
}

/// ========================================================
/// BUSINESS PIN MODEL
/// ========================================================
class BusinessPin {
  final String uid;
  final String name;
  final String businessName;
  final String userType;
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

// =========================================================
// POST MODEL
// =========================================================
class Post {
  final String id;
  final String uid;
  final String authorName;
  final String? authorLogoUrl;
  final String content;
  final String? imageUrl;
  final int likesCount;
  final bool likedByMe;
  final DateTime createdAt;
  final List<PostComment> comments;
  final bool isRepost;
  final Post? originalPost;

  Post({
    required this.id,
    required this.uid,
    required this.authorName,
    this.authorLogoUrl,
    required this.content,
    this.imageUrl,
    required this.likesCount,
    required this.likedByMe,
    required this.createdAt,
    required this.comments,
    this.isRepost = false,
    this.originalPost,
  });
}

class PostComment {
  final String id;
  final String uid;
  final String authorName;
  final String content;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });
}

/// ========================================================
/// APP NOTIFICATION MODEL
/// ========================================================
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? eventId;
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.eventId,
    required this.createdAt,
    required this.read,
  });
}

// =========================================================
// MESSAGING MODELS
// =========================================================

/// A single conversation between two users.
class Conversation {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String?> participantLogos;
  final bool isMutual;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastSenderId;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantLogos,
    required this.isMutual,
    required this.lastMessage,
    this.lastMessageTime,
    required this.lastSenderId,
    required this.unreadCount,
  });

  /// The other participant's uid relative to [myUid].
  String otherUid(String myUid) =>
      participants.firstWhere((id) => id != myUid, orElse: () => '');
}

enum ChatMessageType { text, image, file }

/// A single message inside a conversation.
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final ChatMessageType type;
  final String? attachmentUrl;
  final String? attachmentName;
  final DateTime? timestamp;
  final List<String> readBy;
  final bool deleted;
  final String? forwardedFrom;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.type,
    this.attachmentUrl,
    this.attachmentName,
    this.timestamp,
    required this.readBy,
    required this.deleted,
    this.forwardedFrom,
  });

  bool isReadBy(String uid) => readBy.contains(uid);
}

/// ========================================================
/// CENTRAL BACKEND SERVICE
/// ========================================================
class BackendService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // No FirebaseStorage — all uploads go through Cloudinary.

  static List<CalendarEvent> getEventsForDay(DateTime day) => [];

  // =========================================================
  // CHECK USER PROFILE STATUS
  // =========================================================
  static Future<ProfileStatus> checkUserProfileExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return ProfileStatus.notFound;
      final data = doc.data();
      if (data == null) return ProfileStatus.notFound;
      if (data['approved'] == true) return ProfileStatus.approvedExists;
      return ProfileStatus.pendingApproval;
    } catch (e) {
      return ProfileStatus.notFound;
    }
  }

  // =========================================================
  // LOGIN
  // =========================================================
  static Future<BackendResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = userCredential.user!;
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _auth.signOut();
        return BackendResult(
          success: false,
          message:
              "User profile not found. Please contact administrator.",
        );
      }
      final userData = userDoc.data()!;
      final isGoogleAccount = userData['authProvider'] == 'google';
      if (!isGoogleAccount && !user.emailVerified) {
        await _auth.signOut();
        return BackendResult(
          success: false,
          message:
              "Email not verified. Please check your inbox and verify your email before logging in.",
        );
      }
      if (userData['approved'] != true) {
        await _auth.signOut();
        return BackendResult(
            success: false,
            message: "Account not yet approved by admin.");
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
      return BackendResult(
          success: false,
          message: "An error occurred: ${e.toString()}");
    }
  }

  // =========================================================
  // REGISTER GOOGLE USER FOR APPROVAL
  // =========================================================
  static Future<BackendResult> registerGoogleUserForApproval({
    required User googleUser,
    required String name,
    required String password,
    required String address,
    required String userType,
    String? businessName,
    String? businessNature,
    String? professionalTitle,
    Uint8List? orFileBytes,
    String? orFileName,
  }) async {
    try {
      try {
        final emailCred = EmailAuthProvider.credential(
          email: googleUser.email!,
          password: password.trim(),
        );
        await googleUser.linkWithCredential(emailCred);
      } catch (e) {
        // Proceed even if linking fails
      }
      String? orUrl;
      if (orFileBytes != null && orFileName != null) {
        try {
          orUrl = await _uploadToCloudinary(orFileBytes, orFileName,
              folder: 'or_documents', resourceType: 'raw');
        } catch (e) {
          return BackendResult(
              success: false,
              message:
                  "Failed to upload OR document: ${e.toString()}");
        }
      }
      await _firestore.collection('users').doc(googleUser.uid).set({
        'name': name.trim(),
        'email': googleUser.email,
        'address': address.trim(),
        'userType': userType,
        'businessName': businessName?.trim(),
        'businessNature': businessNature?.trim(),
        'orDocumentUrl': orUrl,
        'orFileName': orFileName,
        'approved': false,
        'authProvider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return BackendResult(success: true);
    } catch (e) {
      return BackendResult(
          success: false,
          message: "An error occurred: ${e.toString()}");
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
      'status': 'pending',
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'availableSlots': availableSlots,
    });
    return docRef.id;
  }

  // =========================================================
  // UPDATE PENDING EVENT
  // =========================================================
  static Future<BackendResult> updatePendingEvent({
    required String eventId,
    required String title,
    required String venue,
    required String description,
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    String? posterUrl,
    required int availableSlots,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      final doc =
          await _firestore.collection('events').doc(eventId).get();
      if (!doc.exists)
        return BackendResult(
            success: false, message: 'Event not found');
      final data = doc.data()!;
      if (data['createdBy'] != user.uid)
        return BackendResult(success: false, message: 'Unauthorized');
      if (data['approved'] == true)
        return BackendResult(
            success: false,
            message: 'Cannot edit an already approved event.');
      final normalizedDate = DateTime(date.year, date.month, date.day);
      await _firestore.collection('events').doc(eventId).update({
        'title': title,
        'venue': venue,
        'description': description,
        'imageUrl': posterUrl,
        'date': Timestamp.fromDate(normalizedDate),
        'startHour': start.hour,
        'startMinute': start.minute,
        'endHour': end.hour,
        'endMinute': end.minute,
        'availableSlots': availableSlots,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return BackendResult(success: true);
    } catch (e) {
      return BackendResult(success: false, message: e.toString());
    }
  }

  // =========================================================
  // CANCEL PENDING EVENT
  // =========================================================
  static Future<BackendResult> cancelPendingEvent(
      String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      final doc =
          await _firestore.collection('events').doc(eventId).get();
      if (!doc.exists)
        return BackendResult(
            success: false, message: 'Event not found');
      final data = doc.data()!;
      if (data['createdBy'] != user.uid)
        return BackendResult(success: false, message: 'Unauthorized');
      if (data['approved'] == true)
        return BackendResult(
            success: false,
            message:
                'Event is already approved. Use request cancellation instead.');
      await _firestore.collection('events').doc(eventId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      return BackendResult(success: true);
    } catch (e) {
      return BackendResult(success: false, message: e.toString());
    }
  }

  // =========================================================
  // REQUEST CANCELLATION (approved events)
  // =========================================================
  static Future<BackendResult> requestEventCancellation(
      String eventId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      final doc =
          await _firestore.collection('events').doc(eventId).get();
      if (!doc.exists)
        return BackendResult(
            success: false, message: 'Event not found');
      final data = doc.data()!;
      if (data['createdBy'] != user.uid)
        return BackendResult(success: false, message: 'Unauthorized');
      await _firestore.collection('events').doc(eventId).update({
        'status': 'cancel_requested',
        'cancelReason': reason.trim(),
        'cancelRequestedAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('admin_notifications').add({
        'type': 'cancel_request',
        'eventId': eventId,
        'eventTitle': data['title'],
        'requestedBy': user.uid,
        'reason': reason.trim(),
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return BackendResult(success: true);
    } catch (e) {
      return BackendResult(success: false, message: e.toString());
    }
  }

  // =========================================================
  // ADMIN: APPROVE CANCELLATION + NOTIFY RSVPed USERS
  // =========================================================
  static Future<BackendResult> adminApproveCancellation(
      String eventId) async {
    try {
      final doc =
          await _firestore.collection('events').doc(eventId).get();
      if (!doc.exists)
        return BackendResult(
            success: false, message: 'Event not found');
      final data = doc.data()!;
      await _firestore.collection('events').doc(eventId).update({
        'status': 'cancelled',
        'approved': false,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      final attendees = await _firestore
          .collection('event_attendance')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'attending')
          .get();
      final batch = _firestore.batch();
      for (final attendee in attendees.docs) {
        final attendeeUid = attendee.data()['uid'] as String?;
        if (attendeeUid == null) continue;
        final notifRef =
            _firestore.collection('user_notifications').doc();
        batch.set(notifRef, {
          'uid': attendeeUid,
          'type': 'event_cancelled',
          'title': 'Event Cancelled',
          'body': '"${data['title']}" has been cancelled.',
          'eventId': eventId,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return BackendResult(success: true);
    } catch (e) {
      return BackendResult(success: false, message: e.toString());
    }
  }

  // =========================================================
  // APPROVED EVENTS STREAM
  // =========================================================
  static Stream<List<UpcomingEvent>> approvedEventsStream() {
    return _firestore
        .collection('events')
        .where('approved', isEqualTo: true)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final d = doc.data();
        final date = (d['date'] as Timestamp).toDate();
        return UpcomingEvent(
          id: doc.id,
          date: date,
          availableSlots:
              (d['availableSlots'] as num?)?.toInt() ?? 0,
          event: CalendarEvent(
            title: d['title'],
            venue: d['venue'],
            description: d['description'],
            imageUrl: d['imageUrl'],
            startTime: TimeOfDay(
                hour: d['startHour'], minute: d['startMinute']),
            endTime: TimeOfDay(
                hour: d['endHour'], minute: d['endMinute']),
            approved: true,
          ),
        );
      }).toList();
    });
  }

  // =========================================================
  // USER'S OWN SUBMITTED EVENTS
  // =========================================================
  static Stream<List<UserSubmittedEvent>> mySubmittedEventsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('events')
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final results = snapshot.docs.map((doc) {
        final d = doc.data();
        final rawDate = d['date'];
        if (rawDate == null) return null;
        final date = (rawDate as Timestamp).toDate();
        String status = d['status'] as String? ?? 'pending';
        if (d['approved'] == true && status == 'pending')
          status = 'approved';
        return UserSubmittedEvent(
          id: doc.id,
          title: d['title'] ?? '',
          venue: d['venue'] ?? '',
          description: d['description'] ?? '',
          date: date,
          startTime: TimeOfDay(
              hour: d['startHour'] ?? 0,
              minute: d['startMinute'] ?? 0),
          endTime: TimeOfDay(
              hour: d['endHour'] ?? 0,
              minute: d['endMinute'] ?? 0),
          status: status,
          availableSlots:
              (d['availableSlots'] as num?)?.toInt() ?? 0,
          posterUrl: d['imageUrl'],
        );
      }).whereType<UserSubmittedEvent>().toList();
      results.sort((a, b) => b.date.compareTo(a.date));
      return results;
    });
  }

  // =========================================================
  // USER NOTIFICATION STREAM
  // =========================================================
  static Stream<List<AppNotification>> userNotificationsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('user_notifications')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final d = doc.data();
        return AppNotification(
          id: doc.id,
          type: d['type'] ?? '',
          title: d['title'] ?? '',
          body: d['body'] ?? '',
          eventId: d['eventId'],
          createdAt:
              (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          read: d['read'] == true,
        );
      }).toList();
    });
  }

  // =========================================================
  // RECENTLY APPROVED EVENTS STREAM
  // =========================================================
  static Stream<List<UpcomingEvent>> recentlyApprovedEventsStream() {
    return _firestore
        .collection('events')
        .where('approved', isEqualTo: true)
        .where('status', isEqualTo: 'approved')
        .where('date',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(DateTime.now()))
        .orderBy('date')
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final d = doc.data();
        final date = (d['date'] as Timestamp).toDate();
        return UpcomingEvent(
          id: doc.id,
          date: date,
          availableSlots:
              (d['availableSlots'] as num?)?.toInt() ?? 0,
          event: CalendarEvent(
            title: d['title'],
            venue: d['venue'],
            description: d['description'],
            imageUrl: d['imageUrl'],
            startTime: TimeOfDay(
                hour: d['startHour'], minute: d['startMinute']),
            endTime: TimeOfDay(
                hour: d['endHour'], minute: d['endMinute']),
            approved: true,
          ),
        );
      }).toList();
    });
  }

  // =========================================================
  // MARK NOTIFICATION AS READ
  // =========================================================
  static Future<void> markNotificationRead(String notifId) async {
    await _firestore
        .collection('user_notifications')
        .doc(notifId)
        .update({'read': true});
  }

  static Future<void> markAllNotificationsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snap = await _firestore
        .collection('user_notifications')
        .where('uid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // =========================================================
  // EVENT ATTENDANCE (RSVP)
  // =========================================================
  static Future<BackendResult> attendEvent({
    required UpcomingEvent upcomingEvent,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');
      final existing = await _firestore
          .collection('event_attendance')
          .where('uid', isEqualTo: uid)
          .where('eventId', isEqualTo: upcomingEvent.id)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        return BackendResult(
            success: false,
            message: 'Already attending this event');
      }
      await _firestore.collection('event_attendance').add({
        'uid': uid,
        'eventId': upcomingEvent.id,
        'eventTitle': upcomingEvent.event.title,
        'venue': upcomingEvent.event.venue,
        'date': Timestamp.fromDate(upcomingEvent.date),
        'status': 'attending',
        'createdAt': Timestamp.now(),
      });
      await _firestore
          .collection('events')
          .doc(upcomingEvent.id)
          .update({
        'availableSlots': FieldValue.increment(-1),
      });
      return BackendResult(success: true);
    } catch (e) {
      return BackendResult(success: false, message: e.toString());
    }
  }

  // =========================================================
  // CHECK IF USER IS ATTENDING
  // =========================================================
  static Future<bool> isAttendingEvent(String eventId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final snap = await _firestore
        .collection('event_attendance')
        .where('uid', isEqualTo: uid)
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'attending')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // =========================================================
  // NOTIFY EVENT CREATOR WHEN APPROVED
  // =========================================================
  static Future<void> notifyEventApproved(String eventId) async {
    final doc =
        await _firestore.collection('events').doc(eventId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final creatorUid = data['createdBy'] as String?;
    if (creatorUid == null) return;
    await _firestore.collection('user_notifications').add({
      'uid': creatorUid,
      'type': 'event_approved',
      'title': 'Event Approved!',
      'body':
          '"${data['title']}" has been approved and is now live.',
      'eventId': eventId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _firestore
        .collection('events')
        .doc(eventId)
        .update({'status': 'approved'});
  }

  // =========================================================
  // PROFILE METHODS
  // =========================================================
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc =
        await _firestore.collection('users').doc(user.uid).get();
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
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
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
  // SAVE BUSINESS LOCATION
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
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
        'location': {
          'lat': lat,
          'lng': lng,
          'address': address.trim()
        },
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
      final businesses = data['businesses'];
      if (businesses != null && businesses is List) {
        for (final b in businesses) {
          if (b is! Map) continue;
          final lat = (b['lat'] as num?)?.toDouble();
          final lng = (b['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;
          if (lat < minLat ||
              lat > maxLat ||
              lng < minLng ||
              lng > maxLng) continue;
          final businessName =
              (b['name'] as String?)?.isNotEmpty == true
                  ? b['name'] as String
                  : (data['businessName'] as String? ??
                      data['name'] as String? ??
                      'Unknown');
          final logo =
              (b['logoUrl'] as String?)?.isNotEmpty == true
                  ? b['logoUrl'] as String
                  : data['logoUrl'] as String?;
          final addr =
              (b['address'] as String?)?.isNotEmpty == true
                  ? b['address'] as String
                  : ((data['location'] as Map?)?['address']
                          as String? ??
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
      if (!addedFromBusinesses) {
        final loc = data['location'];
        if (loc is Map) {
          final lat = (loc['lat'] as num?)?.toDouble();
          final lng = (loc['lng'] as num?)?.toDouble();
          if (lat != null &&
              lng != null &&
              lat >= minLat &&
              lat <= maxLat &&
              lng >= minLng &&
              lng <= maxLng) {
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
  static Future<String?> uploadLogoImage(
      Uint8List bytes, String fileName) async {
    try {
      return await _uploadToCloudinary(bytes, fileName,
          folder: 'business_logos', resourceType: 'image');
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
    String folder = 'or_documents',
    String resourceType = 'raw',
  }) async {
    const cloudName = 'dfwe9loex';
    const uploadPreset = 'smartcard';
    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');
    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;
    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes,
          filename: fileName),
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

  // =========================================================
  // CREATE POST
  // =========================================================
  static Future<BackendResult> createPost({
    required String content,
    String? imageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      final validation = validatePostContent(content);
      if (validation != null) {
        return BackendResult(success: false, message: validation);
      }
      final profile = await fetchUserProfile();
      final name = profile?['name'] ?? 'User';
      final logoUrl = profile?['logoUrl'];
      await _firestore.collection('posts').add({
        'uid': user.uid,
        'authorName': name,
        'authorLogoUrl': logoUrl,
        'content': content.trim(),
        'imageUrl': imageUrl,
        'likesCount': 0,
        'likedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return BackendResult(success: true);
    } catch (e) {
      return BackendResult(success: false, message: e.toString());
    }
  }

  // =========================================================
  // FEED STREAM
  // =========================================================
  static Stream<List<Post>> feedStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
      final followDoc =
          await _firestore.collection('follows').doc(uid).get();
      final following =
          List<String>.from(followDoc.data()?['following'] ?? []);
      final allowed = {...following, uid};
      final posts = <Post>[];
      for (final doc in snapshot.docs) {
        final d = doc.data();
        if (!allowed.contains(d['uid'])) continue;
        final commentsSnap = await doc.reference
            .collection('comments')
            .orderBy('createdAt')
            .get();
        final comments = commentsSnap.docs.map((c) {
          final cd = c.data();
          return PostComment(
            id: c.id,
            uid: cd['uid'],
            authorName: cd['authorName'],
            content: cd['content'],
            createdAt:
                (cd['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
          );
        }).toList();
        Post? originalPost;
        if (d['isRepost'] == true && d['originalPostId'] != null) {
          originalPost = Post(
            id: d['originalPostId'],
            uid: d['originalUid'] ?? '',
            authorName: d['originalAuthorName'] ?? '',
            authorLogoUrl: d['originalAuthorLogoUrl'],
            content: d['originalContent'] ?? '',
            imageUrl: d['originalImageUrl'],
            likesCount: 0,
            likedByMe: false,
            createdAt:
                (d['originalCreatedAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
            comments: [],
          );
        }
        posts.add(Post(
          id: doc.id,
          uid: d['uid'],
          authorName: d['authorName'] ?? '',
          authorLogoUrl: d['authorLogoUrl'],
          content: d['content'] ?? '',
          imageUrl: d['imageUrl'],
          likesCount: d['likesCount'] ?? 0,
          likedByMe:
              (d['likedBy'] as List?)?.contains(uid) ?? false,
          createdAt:
              (d['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
          comments: comments,
          isRepost: d['isRepost'] == true,
          originalPost: originalPost,
        ));
      }
      return posts;
    });
  }

  // =========================================================
  // TOGGLE LIKE
  // =========================================================
  static Future<void> toggleLike(
      String postId, bool currentlyLiked) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _firestore.collection('posts').doc(postId);
    if (currentlyLiked) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([uid]),
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([uid]),
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  // =========================================================
  // ADD COMMENT
  // =========================================================
  static Future<BackendResult> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');
      if (BackendService.containsProfanity(content)) {
        return BackendResult(
            success: false,
            message: 'Comment contains inappropriate language.');
      }
      final profile = await fetchUserProfile();
      final name = profile?['name'] ?? 'User';
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'uid': uid,
        'authorName': name,
        'content': content.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return BackendResult(success: true);
    } catch (e) {
      return BackendResult(success: false, message: e.toString());
    }
  }

  // =========================================================
// PROFANITY FILTER
// =========================================================
static const List<String> _bannedWords = [
  'fuck', 'shit', 'asshole', 'bitch', 'bastard', 'damn', 'crap',
  'piss', 'cock', 'dick', 'pussy', 'cunt', 'whore', 'slut', 'faggot',
  'nigger', 'nigga', 'retard', 'putangina', 'gago', 'tangina', 'bobo',
  'tanga', 'ulol', 'punyeta', 'tarantado', 'leche', 'puta', 'bwisit',
  'pakyu', 'hudas', 'inutil', 'siraulo',
];

static bool containsProfanity(String text) {
  final lower = text.toLowerCase();
  for (final word in _bannedWords) {
    // Match whole word with optional leet-speak (simple check)
    final pattern = RegExp(
      r'(^|[\s,\.!?])' + RegExp.escape(word) + r'($|[\s,\.!?])',
    );
    if (pattern.hasMatch(lower) || lower.contains(word)) return true;
  }
  return false;
}

static String? validatePostContent(String content) {
  if (content.trim().isEmpty) return 'Post cannot be empty.';
  if (containsProfanity(content)) {
    return 'Your post contains inappropriate language. Please revise it.';
  }
  return null;
}

// =========================================================
// DELETE POST
// =========================================================
static Future<BackendResult> deletePost(String postId) async {
  try {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (!doc.exists) return BackendResult(success: false, message: 'Post not found');
    if (doc.data()?['uid'] != user.uid) {
      return BackendResult(success: false, message: 'Unauthorized');
    }
    // Delete all comments first
    final comments = await _firestore
        .collection('posts').doc(postId).collection('comments').get();
    final batch = _firestore.batch();
    for (final c in comments.docs) batch.delete(c.reference);
    batch.delete(_firestore.collection('posts').doc(postId));
    await batch.commit();
    return BackendResult(success: true);
  } catch (e) {
    return BackendResult(success: false, message: e.toString());
  }
}

// =========================================================
// EDIT POST
// =========================================================
static Future<BackendResult> editPost({
  required String postId,
  required String newContent,
}) async {
  try {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final validation = validatePostContent(newContent);
    if (validation != null) return BackendResult(success: false, message: validation);
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (!doc.exists) return BackendResult(success: false, message: 'Post not found');
    if (doc.data()?['uid'] != user.uid) {
      return BackendResult(success: false, message: 'Unauthorized');
    }
    await _firestore.collection('posts').doc(postId).update({
      'content': newContent.trim(),
      'editedAt': FieldValue.serverTimestamp(),
    });
    return BackendResult(success: true);
  } catch (e) {
    return BackendResult(success: false, message: e.toString());
  }
}

// =========================================================
// DELETE COMMENT
// =========================================================
static Future<BackendResult> deleteComment({
  required String postId,
  required String commentId,
}) async {
  try {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final doc = await _firestore
        .collection('posts').doc(postId)
        .collection('comments').doc(commentId).get();
    if (!doc.exists) return BackendResult(success: false, message: 'Comment not found');
    if (doc.data()?['uid'] != user.uid) {
      return BackendResult(success: false, message: 'Unauthorized');
    }
    await _firestore
        .collection('posts').doc(postId)
        .collection('comments').doc(commentId).delete();
    return BackendResult(success: true);
  } catch (e) {
    return BackendResult(success: false, message: e.toString());
  }
}

// =========================================================
// EDIT COMMENT
// =========================================================
static Future<BackendResult> editComment({
  required String postId,
  required String commentId,
  required String newContent,
}) async {
  try {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    if (containsProfanity(newContent)) {
      return BackendResult(
          success: false,
          message: 'Comment contains inappropriate language.');
    }
    final doc = await _firestore
        .collection('posts').doc(postId)
        .collection('comments').doc(commentId).get();
    if (!doc.exists) return BackendResult(success: false, message: 'Comment not found');
    if (doc.data()?['uid'] != user.uid) {
      return BackendResult(success: false, message: 'Unauthorized');
    }
    await _firestore
        .collection('posts').doc(postId)
        .collection('comments').doc(commentId).update({
      'content': newContent.trim(),
      'editedAt': FieldValue.serverTimestamp(),
    });
    return BackendResult(success: true);
  } catch (e) {
    return BackendResult(success: false, message: e.toString());
  }
}

  // =========================================================
  // FOLLOW / UNFOLLOW
  // =========================================================
  static Future<void> followUser(String targetUid) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('follows').doc(uid).set({
      'following': FieldValue.arrayUnion([targetUid]),
    }, SetOptions(merge: true));
  }

  static Future<void> unfollowUser(String targetUid) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('follows').doc(uid).set({
      'following': FieldValue.arrayRemove([targetUid]),
    }, SetOptions(merge: true));
  }

  // =========================================================
  // IS FOLLOWING CHECK
  // =========================================================
  static Future<bool> isFollowing(String targetUid) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final doc =
          await _firestore.collection('follows').doc(uid).get();
      final following =
          List<String>.from(doc.data()?['following'] ?? []);
      return following.contains(targetUid);
    } catch (e) {
      return false;
    }
  }

  // =========================================================
  // UPLOAD POST IMAGE
  // =========================================================
  static Future<String?> uploadPostImage(
      Uint8List bytes, String fileName) async {
    try {
      return await _uploadToCloudinary(bytes, fileName,
          folder: 'post_images', resourceType: 'image');
    } catch (e) {
      return null;
    }
  }

  // =========================================================
  // FETCH POST LIKERS
  // =========================================================
  static Future<List<Map<String, dynamic>>> fetchPostLikers(
      String postId) async {
    try {
      final doc =
          await _firestore.collection('posts').doc(postId).get();
      if (!doc.exists) return [];
      final likedBy =
          List<String>.from(doc.data()?['likedBy'] ?? []);
      if (likedBy.isEmpty) return [];
      final List<Map<String, dynamic>> likers = [];
      for (final uid in likedBy) {
        final userDoc =
            await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          likers.add({...userDoc.data()!, 'uid': uid});
        }
      }
      return likers;
    } catch (e) {
      return [];
    }
  }

  // =========================================================
  // REPOST
  // =========================================================
  static Future<BackendResult> repostPost({
    required Post originalPost,
    String caption = '',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      final profile = await fetchUserProfile();
      final name = profile?['name'] ?? 'User';
      final logoUrl = profile?['logoUrl'];
      await _firestore.collection('posts').add({
        'uid': user.uid,
        'authorName': name,
        'authorLogoUrl': logoUrl,
        'content': caption,
        'imageUrl': null,
        'likesCount': 0,
        'likedBy': [],
        'isRepost': true,
        'originalPostId': originalPost.id,
        'originalUid': originalPost.uid,
        'originalAuthorName': originalPost.authorName,
        'originalAuthorLogoUrl': originalPost.authorLogoUrl,
        'originalContent': originalPost.content,
        'originalImageUrl': originalPost.imageUrl,
        'originalCreatedAt':
            Timestamp.fromDate(originalPost.createdAt),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return BackendResult(success: true);
    } catch (e) {
      return BackendResult(success: false, message: e.toString());
    }
  }

  // =========================================================
  // ── MESSAGING ─────────────────────────────────────────────
  // =========================================================

  /// Returns the current user's uid. Throws if not logged in.
  static String get currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');
    return uid;
  }

  /// Checks whether two users are mutually following each other.
  static Future<bool> areMutual(String uid1, String uid2) async {
    final doc1 =
        await _firestore.collection('follows').doc(uid1).get();
    final doc2 =
        await _firestore.collection('follows').doc(uid2).get();
    final f1 =
        List<String>.from(doc1.data()?['following'] ?? []);
    final f2 =
        List<String>.from(doc2.data()?['following'] ?? []);
    return f1.contains(uid2) && f2.contains(uid1);
  }

  /// Stream of all conversations for the current user.
  static Stream<List<Conversation>> conversationsStream() {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return _firestore
      .collection('conversations')
      .where('participants', arrayContains: uid)
      .snapshots()
      .map((snap) {
        final convs = snap.docs.map((doc) {
          final d = doc.data();
          return Conversation(
            id: doc.id,
            participants: List<String>.from(d['participants'] ?? []),
            participantNames: Map<String, String>.from(
                (d['participantNames'] as Map? ?? {}).map(
                    (k, v) => MapEntry(k.toString(), v.toString()))),
            participantLogos: Map<String, String?>.from(
                (d['participantLogos'] as Map? ?? {}).map(
                    (k, v) => MapEntry(k.toString(), v as String?))),
            isMutual: d['isMutual'] == true,
            lastMessage: d['lastMessage'] as String? ?? '',
            lastMessageTime: (d['lastMessageTime'] as Timestamp?)?.toDate(),
            lastSenderId: d['lastSenderId'] as String? ?? '',
            unreadCount: (d['unreadCount_$uid'] as int?) ?? 0,
          );
        }).toList();  // ← semicolon here, NOT closing paren
        convs.sort((a, b) {
          final aTime = a.lastMessageTime;
          final bTime = b.lastMessageTime;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        return convs;
      });
}

    

  /// Stream of messages inside a conversation.
  static Stream<List<ChatMessage>> messagesStream(String convId) {
    return _firestore
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              ChatMessageType type;
              switch (d['type']) {
                case 'image':
                  type = ChatMessageType.image;
                  break;
                case 'file':
                  type = ChatMessageType.file;
                  break;
                default:
                  type = ChatMessageType.text;
              }
              return ChatMessage(
                id: doc.id,
                senderId: d['senderId'] as String? ?? '',
                text: d['text'] as String? ?? '',
                type: type,
                attachmentUrl: d['attachmentUrl'] as String?,
                attachmentName:
                    d['attachmentName'] as String?,
                timestamp:
                    (d['timestamp'] as Timestamp?)?.toDate(),
                readBy:
                    List<String>.from(d['readBy'] ?? []),
                deleted: d['deleted'] == true,
                forwardedFrom:
                    d['forwardedFrom'] as String?,
              );
            }).toList());
            
  }

  /// Find or create a conversation between the current user and [otherId].
  static Future<String> findOrCreateConversation(
      String otherId) async {
    final myUid = currentUid;
    final snap = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: myUid)
        .get();
    for (final doc in snap.docs) {
      final parts =
          List<String>.from(doc.data()['participants'] ?? []);
      if (parts.contains(otherId)) return doc.id;
    }
    final myDoc =
        await _firestore.collection('users').doc(myUid).get();
    final otherDoc =
        await _firestore.collection('users').doc(otherId).get();
    final myName =
        myDoc.data()?['name'] as String? ?? 'Me';
    final otherName =
        otherDoc.data()?['name'] as String? ?? 'User';
    final myLogo =
        myDoc.data()?['logoUrl'] as String?;
    final otherLogo =
        otherDoc.data()?['logoUrl'] as String?;
    final mutual = await areMutual(myUid, otherId);
    final ref =
        await _firestore.collection('conversations').add({
      'participants': [myUid, otherId],
      'participantNames': {
        myUid: myName,
        otherId: otherName
      },
      'participantLogos': {
        myUid: myLogo,
        otherId: otherLogo
      },
      'isMutual': mutual,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': '',
      'unreadCount_$myUid': 0,
      'unreadCount_$otherId': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Send a text message.
  static Future<void> sendTextMessage(
      String convId, String text) async {
    await _sendMessage(convId: convId, text: text, type: 'text');
  }

  /// Send an image message — uploads bytes to Cloudinary (web + mobile safe).
  static Future<void> sendImageMessage(
      String convId, Uint8List bytes, String fileName) async {
    final uploadName =
        'chat_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final url = await _uploadToCloudinary(
      bytes,
      uploadName,
      folder: 'chat_images',
      resourceType: 'image',
    );
    await _sendMessage(
      convId: convId,
      text: '',
      type: 'image',
      attachmentUrl: url,
      attachmentName: fileName,
    );
  }

  /// Send a file message — uploads bytes to Cloudinary (web + mobile safe).
  static Future<void> sendFileMessage(
      String convId, Uint8List bytes, String fileName) async {
    final uploadName =
        'chat_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final url = await _uploadToCloudinary(
      bytes,
      uploadName,
      folder: 'chat_files',
      resourceType: 'raw',
    );
    await _sendMessage(
      convId: convId,
      text: '',
      type: 'file',
      attachmentUrl: url,
      attachmentName: fileName,
    );
  }

  /// Forward a message to another conversation.
  static Future<void> forwardMessage({
    required String targetConvId,
    required ChatMessage message,
    required String originalSenderName,
  }) async {
    await _sendMessage(
      convId: targetConvId,
      text: message.text,
      type: _typeString(message.type),
      attachmentUrl: message.attachmentUrl,
      attachmentName: message.attachmentName,
      forwardedFrom: originalSenderName,
    );
  }

  /// Soft-delete a message (sender only — enforced in UI).
  static Future<void> deleteMessage(
      String convId, String msgId) async {
    await _firestore
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .doc(msgId)
        .update({
      'deleted': true,
      'text': 'This message was deleted'
    });
  }

  /// Mark all messages in [convId] as read and reset the unread counter.
  static Future<void> markConversationRead(String convId) async {
    final uid = currentUid;
    await _firestore
        .collection('conversations')
        .doc(convId)
        .update({'unreadCount_$uid': 0});
    // Fetch all messages and filter client-side — avoids needing
    // a composite index for isNotEqualTo on web.
    final msgs = await _firestore
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .get();
    final batch = _firestore.batch();
    for (final m in msgs.docs) {
      final data = m.data();
      if (data['senderId'] == uid) continue;
      final readBy =
          List<String>.from(data['readBy'] ?? []);
      if (!readBy.contains(uid)) {
        batch.update(m.reference,
            {'readBy': FieldValue.arrayUnion([uid])});
      }
    }
    await batch.commit();
  }

  /// Search approved users by name.
  static Future<List<Map<String, dynamic>>> searchUsers(
      String query) async {
    final uid = currentUid;
    if (query.trim().isEmpty) return [];
    final snap = await _firestore
        .collection('users')
        .where('approved', isEqualTo: true)
        .get();
    final q = query.toLowerCase();
    final filtered = snap.docs
        .where((d) => d.id != uid)
        .where((d) =>
            (d.data()['name'] as String? ?? '')
                .toLowerCase()
                .contains(q))
        .map((d) => {...d.data(), 'uid': d.id})
        .toList();
    final myFollowDoc =
        await _firestore.collection('follows').doc(uid).get();
    final myFollowing =
        List<String>.from(myFollowDoc.data()?['following'] ?? []);
    for (final u in filtered) {
      final theirDoc = await _firestore
          .collection('follows')
          .doc(u['uid'])
          .get();
      final theirFollowing =
          List<String>.from(theirDoc.data()?['following'] ?? []);
      u['isMutual'] = myFollowing.contains(u['uid']) &&
          theirFollowing.contains(uid);
    }
    return filtered;
  }

  /// Fetch all conversations the current user participates in.
  static Future<List<Conversation>> fetchAllConversations() async {
    final uid = currentUid;
    final snap = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return Conversation(
        id: doc.id,
        participants:
            List<String>.from(d['participants'] ?? []),
        participantNames: Map<String, String>.from(
            (d['participantNames'] as Map? ?? {}).map(
                (k, v) =>
                    MapEntry(k.toString(), v.toString()))),
        participantLogos: Map<String, String?>.from(
            (d['participantLogos'] as Map? ?? {}).map(
                (k, v) =>
                    MapEntry(k.toString(), v as String?))),
        isMutual: d['isMutual'] == true,
        lastMessage: d['lastMessage'] as String? ?? '',
        lastMessageTime:
            (d['lastMessageTime'] as Timestamp?)?.toDate(),
        lastSenderId: d['lastSenderId'] as String? ?? '',
        unreadCount: (d['unreadCount_$uid'] as int?) ?? 0,
      );
    }).toList();
  }

  // ── Private helpers ──────────────────────────────────────

  static String _typeString(ChatMessageType t) {
    switch (t) {
      case ChatMessageType.image:
        return 'image';
      case ChatMessageType.file:
        return 'file';
      default:
        return 'text';
    }
  }

  static Future<void> _sendMessage({
    required String convId,
    required String text,
    required String type,
    String? attachmentUrl,
    String? attachmentName,
    String? forwardedFrom,
  }) async {
    final uid = currentUid;
    final convDoc = await _firestore
        .collection('conversations')
        .doc(convId)
        .get();
    final participants =
        List<String>.from(convDoc.data()?['participants'] ?? []);
    final otherId = participants.firstWhere(
        (id) => id != uid,
        orElse: () => '');
    await _firestore
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .add({
      'senderId': uid,
      'text': text,
      'type': type,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [uid],
      'deleted': false,
      'forwardedFrom': forwardedFrom,
    });
    final preview = type == 'text'
        ? text
        : type == 'image'
            ? '📷 Image'
            : '📎 $attachmentName';
    await _firestore
        .collection('conversations')
        .doc(convId)
        .update({
      'lastMessage': preview,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': uid,
      if (otherId.isNotEmpty)
        'unreadCount_$otherId': FieldValue.increment(1),
    });
  }
}