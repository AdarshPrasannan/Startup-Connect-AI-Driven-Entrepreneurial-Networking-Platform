import 'package:flutter/material.dart';
import 'package:startup_corner/api/auth_api.dart';
import 'package:startup_corner/models/customer_model.dart';
import 'package:startup_corner/models/mentor_model.dart';
import 'package:startup_corner/models/investor_model.dart';
import 'package:startup_corner/models/admin_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:startup_corner/models/user_model.dart';
import './investor_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  User? user;
  final AuthAPI authAPI = AuthAPI();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    final currentUser = await authAPI.getCurrentUserInstance();
    setState(() {
      user = currentUser;
    });
  }

  CollectionReference<Customer> get _customersRef =>
      authAPI.customers.withConverter<Customer>(
        fromFirestore: (snapshot, _) => Customer.fromJson(snapshot.data()!),
        toFirestore: (customer, _) => customer.toJson(),
      );

  CollectionReference<Mentor> get _mentorsRef =>
      authAPI.mentors.withConverter<Mentor>(
        fromFirestore: (snapshot, _) => Mentor.fromJson(snapshot.data()!),
        toFirestore: (mentor, _) => mentor.toJson(),
      );

  CollectionReference<Investor> get _investorsRef =>
      authAPI.investors.withConverter<Investor>(
        fromFirestore: (snapshot, _) => Investor.fromJson(snapshot.data()!),
        toFirestore: (investor, _) => investor.toJson(),
      );

  CollectionReference<Admin> get _adminsRef =>
      authAPI.admin.withConverter<Admin>(
        fromFirestore: (snapshot, _) => Admin.fromJson(snapshot.data()!),
        toFirestore: (admin, _) => admin.toJson(),
      );

  Stream<List<dynamic>> _getAllUsers() {
    final customerStream = _customersRef
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    final mentorStream = _mentorsRef
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    final investorStream = _investorsRef
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    final adminStream = _adminsRef
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

    return CombineLatestStream.list([
      customerStream,
      mentorStream,
      investorStream,
      adminStream,
    ]).map((List<List<dynamic>> lists) {
      return [...lists[0], ...lists[1], ...lists[2], ...lists[3]]
          .where((user) => user.id != this.user?.uid)
          .toList();
    });
  }

  Future<void> _startChatWithUser(String userId, BuildContext context) async {
    if (user != null && user!.uid != userId) {
      String? chatRoomId = await authAPI.createChatRoom([user!.uid, userId]);
      if (chatRoomId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoomId: chatRoomId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat')),
        );
      }
    }
  }

  void _showUserSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.orange,
          title: Text(
            'Select a User to Chat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<List<dynamic>>(
              stream: _getAllUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!;
                if (users.isEmpty) {
                  return Center(child: Text('No users found'));
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData = users[index];
                    final userId = userData.id;
                    final userName = userData.name;
                    final userRole = userData.role;
                    return ListTile(
                      title: Text(
                        userName,
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '$userRole',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _startChatWithUser(userId, context);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Chats')),
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        backgroundColor: Colors.white,
        elevation: 1,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: authAPI.getUserChatRooms(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No chats yet'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _showUserSelectionDialog(context),
                    child: Text('Start a New Chat'),
                  ),
                ],
              ),
            );
          }

          final chatRooms = snapshot.data!;
          return ListView.separated(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final chatRoomId = chatRoom['participants'].join('_');
              final otherUserId =
                  chatRoom['participants'].firstWhere((id) => id != user!.uid);

              return FutureBuilder<UserModel?>(
                future: authAPI.readUserByUid(otherUserId),
                builder: (context, userSnapshot) {
                  Widget title;
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    title = Text(
                      'Loading...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    );
                  } else if (userSnapshot.hasError || !userSnapshot.hasData) {
                    title = Text(
                      'Unknown User',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    );
                  } else {
                    final participantData = userSnapshot.data!;
                    title = Text(
                      participantData.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    );
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.grey[600]),
                    ),
                    title: title,
                    subtitle: Text(
                      chatRoom['lastMessage'] ?? 'No messages yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatScreen(chatRoomId: chatRoomId),
                        ),
                      );
                    },
                  );
                },
              );
            },
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[300],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserSelectionDialog(context),
        child: Icon(
          Icons.message,
          color: Colors.white,
        ),
        tooltip: 'Start a new chat',
        backgroundColor: Colors.orange,
      ),
    );
  }
}
