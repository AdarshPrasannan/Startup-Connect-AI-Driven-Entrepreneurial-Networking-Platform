import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserVerificationScreen extends StatefulWidget {
  const UserVerificationScreen({super.key});

  @override
  State<UserVerificationScreen> createState() => _UserVerificationScreenState();
}

class _UserVerificationScreenState extends State<UserVerificationScreen> {
  late Stream<List<Map<String, dynamic>>> _pendingUsersStream;

  @override
  void initState() {
    super.initState();
    _pendingUsersStream = _getPendingUsersStream();
  }

  Stream<List<Map<String, dynamic>>> _getPendingUsersStream() async* {
    final firestore = FirebaseFirestore.instance;
    final collections = [
      firestore.collection('customers'),
      firestore.collection('mentors'),
      firestore.collection('investors'),
    ];

    while (true) {
      List<Map<String, dynamic>> pendingUsers = [];

      for (var collection in collections) {
        final querySnapshot =
            await collection.where('verified', isEqualTo: 'pending').get();
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          pendingUsers.add({
            'name': data['name'] ?? 'Unknown',
            'email': data['email'] ?? 'No email',
            'role': data['role'] ?? 'Unknown',
            'id': data['id'] ?? doc.id,
            'bio': data['bio'] ?? 'No bio provided',
            if (data['role'] == 'customer')
              'phoneNumber': data['phoneNumber'] ?? 'No phone',
            if (data['role'] == 'mentor')
              'expertise':
                  (data['expertise'] as List<dynamic>?)?.cast<String>() ?? [],
            if (data['role'] == 'investor')
              'investmentBudget': data['investmentBudget']?.toDouble() ?? 0.0,
          });
        }
      }

      yield pendingUsers;
      await Future.delayed(const Duration(
          milliseconds: 500)); //Optional, for less frequent updates
    }
  }

  Future<void> approveUser(String userId, String role) async {
    final firestore = FirebaseFirestore.instance;
    String collectionName;
    switch (role) {
      case 'customer':
        collectionName = 'customers';
        break;
      case 'mentor':
        collectionName = 'mentors';
        break;
      case 'investor':
        collectionName = 'investors';
        break;
      default:
        return;
    }
    await firestore.collection(collectionName).doc(userId).update({
      'verified': 'approved',
    });
  }

  Future<void> rejectUser(String userId, String role) async {
    final firestore = FirebaseFirestore.instance;
    String collectionName;
    switch (role) {
      case 'customer':
        collectionName = 'customers';
        break;
      case 'mentor':
        collectionName = 'mentors';
        break;
      case 'investor':
        collectionName = 'investors';
        break;
      default:
        return;
    }
    await firestore.collection(collectionName).doc(userId).update({
      'verified': 'rejected',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[100],
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _pendingUsersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(fontSize: 18.0, color: Colors.red),
                ),
              );
            }
            final pendingUsers = snapshot.data ?? [];
            if (pendingUsers.isEmpty) {
              return const Center(
                child: Text(
                  'No users pending verification',
                  style: TextStyle(fontSize: 18.0, color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: pendingUsers.length,
              itemBuilder: (context, index) {
                final user = pendingUsers[index];
                return Card(
                  elevation: 3.0,
                  margin: const EdgeInsets.only(bottom: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'],
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Email: ${user['email']}',
                          style: TextStyle(
                              fontSize: 14.0, color: Colors.grey[700]),
                        ),
                        Text(
                          'Role: ${user['role']}',
                          style: TextStyle(
                              fontSize: 14.0, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Bio: ${user['bio']}',
                          style: TextStyle(
                              fontSize: 14.0, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8.0),
                        if (user['role'] == 'customer')
                          Text(
                            'Phone: ${user['phoneNumber']}',
                            style: TextStyle(
                                fontSize: 14.0, color: Colors.grey[700]),
                          ),
                        if (user['role'] == 'mentor')
                          Text(
                            'Expertise: ${(user['expertise'] as List<String>).join(', ')}',
                            style: TextStyle(
                                fontSize: 14.0, color: Colors.grey[700]),
                          ),
                        if (user['role'] == 'investor')
                          Text(
                            'Budget: \$${user['investmentBudget'].toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 14.0, color: Colors.grey[700]),
                          ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await approveUser(user['id'], user['role']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('${user['name']} approved!')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: const Text('Approve'),
                            ),
                            const SizedBox(width: 8.0),
                            OutlinedButton(
                              onPressed: () async {
                                await rejectUser(user['id'], user['role']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('${user['name']} rejected!')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
