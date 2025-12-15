import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:startup_corner/models/admin_model.dart';
import 'package:startup_corner/models/customer_model.dart';
import 'package:startup_corner/models/investor_model.dart';
import 'package:startup_corner/models/mentor_model.dart';
import 'package:startup_corner/models/message_model.dart';
import 'package:startup_corner/models/user_model.dart';

class AuthAPI {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _startup = FirebaseFirestore.instance;

  CollectionReference get customers => _startup.collection('customers');
  CollectionReference get admin => _startup.collection('admins');
  CollectionReference get investors => _startup.collection('investors');
  CollectionReference get mentors => _startup.collection('mentors');
  CollectionReference get chatRooms => _startup.collection('chat_rooms');

  final GoogleAuthProvider _googleAuthProvider = GoogleAuthProvider();

  Future<UserCredential?> googleSignin() async {
    try {
      final userCredential =
          await _auth.signInWithProvider(_googleAuthProvider);
      return userCredential;
    } catch (e) {
      debugPrint('$e');
      return null;
    }
  }

  void googleSignout() {
    try {
      _auth.signOut();
      debugPrint('Signed out');
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<User?> getCurrentUserInstance() async {
    try {
      final user = _auth.currentUser;
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> readCurrentUser() async {
    final user = _auth.currentUser;
    final uid = user?.uid;
    if (uid == null) {
      debugPrint('No UID found');
      return null;
    }
    try {
      List<CollectionReference> collections = [
        customers,
        mentors,
        investors,
        admin
      ];

      for (var collection in collections) {
        final querySnapshot =
            await collection.where('id', isEqualTo: uid).get();
        if (querySnapshot.docs.isNotEmpty) {
          final userData =
              querySnapshot.docs.first.data() as Map<String, dynamic>;

          switch (userData['role']) {
            case 'customer':
              return Customer.fromJson(userData) as UserModel;
            case 'mentor':
              return Mentor.fromJson(userData) as UserModel;
            case 'investor':
              return Investor.fromJson(userData) as UserModel;
            case 'admin':
              return Admin.fromJson(userData) as UserModel;
            default:
              debugPrint('Unknown role');
              return null;
          }
        }
      }
      debugPrint('User with $uid not found in any collection');
      return null;
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }

  Future<bool> createUser(UserModel user, String? role) async {
    DocumentReference docRef;

    switch (role) {
      case 'Mentor':
        docRef = mentors.doc(user.id);
        break;
      case 'Investor':
        docRef = investors.doc(user.id);
        break;
      case 'Admin':
        docRef = admin.doc(user.id);
        break;
      default:
        docRef = customers.doc(user.id);
        break;
    }

    try {
      await docRef.set(user.toJson());
      debugPrint('✅ User successfully created: ${user.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating user: $e');
      return false;
    }
  }

  Future<UserModel?> readUserByUid(String uid) async {
  if (uid.isEmpty) {
    debugPrint('No UID provided');
    return null;
  }
  
  try {
    List<CollectionReference> collections = [customers, mentors, investors, admin];

    for (var collection in collections) {
      final querySnapshot = await collection.where('id', isEqualTo: uid).get();
      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;

        switch (userData['role']) {
          case 'customer':
            return Customer.fromJson(userData) as UserModel;
          case 'mentor':
            return Mentor.fromJson(userData) as UserModel;
          case 'investor':
            return Investor.fromJson(userData) as UserModel;
          case 'admin':
            return Admin.fromJson(userData) as UserModel;
          default:
            debugPrint('Unknown role');
            return null;
        }
      }
    }
    
    debugPrint('User with UID $uid not found in any collection');
    return null;
  } catch (e) {
    debugPrint('Error fetching user: $e');
    return null;
  }
}


  Future<String?> createChatRoom(List<String> participantIds) async {
    try {
      // Sort participant IDs to ensure consistent chat room IDs
      participantIds.sort();
      String chatRoomId =
          participantIds.join('_'); // e.g., "admin_123_customer_456"

      // Check if chat room already exists
      DocumentSnapshot chatRoomDoc = await chatRooms.doc(chatRoomId).get();
      if (!chatRoomDoc.exists) {
        await chatRooms.doc(chatRoomId).set({
          'participants': participantIds,
          'lastMessage': '',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return chatRoomId;
    } catch (e) {
      debugPrint('Error creating chat room: $e');
      return null;
    }
  }

  Future<bool> sendMessage(
      String chatRoomId, String senderId, String content) async {
    try {
      CollectionReference messages =
          chatRooms.doc(chatRoomId).collection('messages');
      String messageId = messages.doc().id; // Generate a unique message ID

      await messages.doc(messageId).set({
        'messageId': messageId,
        'senderId': senderId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update last message in chat room
      await chatRooms.doc(chatRoomId).update({
        'lastMessage': content,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('Message sent successfully');
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  // Get real-time stream of messages for a chat room
  Stream<List<Message>> getMessages(String chatRoomId) {
    return chatRooms
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getUserChatRooms(String userId) {
    return chatRooms
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }
}
