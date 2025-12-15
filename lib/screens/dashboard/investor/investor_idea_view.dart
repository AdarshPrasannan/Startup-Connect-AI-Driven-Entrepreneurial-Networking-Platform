import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:startup_corner/api/auth_api.dart';
import 'package:startup_corner/models/customer_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:startup_corner/screens/dashboard/investor/investor_chat_screen.dart';

class InvestorTopIdeasScreen extends StatefulWidget {
  const InvestorTopIdeasScreen({super.key});

  @override
  _InvestorTopIdeasScreenState createState() => _InvestorTopIdeasScreenState();
}

class _InvestorTopIdeasScreenState extends State<InvestorTopIdeasScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<IdeaWithCustomer> _approvedIdeas = [];
  late String _userId;
  final _authAPI = AuthAPI();

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid ?? "";
    _loadApprovedIdeas();
  }

  Future<void> _loadApprovedIdeas() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> customersSnapshot =
          await _firestore.collection('customers').get();

      List<IdeaWithCustomer> approvedIdeas = [];

      for (final doc in customersSnapshot.docs) {
        final Customer customer = Customer.fromJson(doc.data());
        final approvedIdeasForCustomer = customer.ideas
            .where((idea) => idea.status == 'approved')
            .map((idea) => IdeaWithCustomer(
                  idea: idea,
                  customerName: customer.name,
                  customerEmail: customer.email,
                  customerId: doc.id,
                ))
            .toList();
        approvedIdeas.addAll(approvedIdeasForCustomer);
      }
      setState(() {
        _approvedIdeas = approvedIdeas;
      });
    } catch (e) {
      debugPrint('Error loading approved ideas: $e');
    }
  }

  Future<void> _startChatWithUser(String otherUserId) async {
    if (_userId == otherUserId) {
      return;
    }

    try {
      String? chatRoomId = await _authAPI.createChatRoom([_userId, otherUserId]);
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
    } catch (e) {
      debugPrint('Error starting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _approvedIdeas.isEmpty
                ? Center(child: Text('No ideas yet!.'))
                : ListView.builder(
                    itemCount: _approvedIdeas.length,
                    itemBuilder: (context, index) {
                      final ideaWithCustomer = _approvedIdeas[index];
                      final idea = ideaWithCustomer.idea;

                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _startChatWithUser(
                                    ideaWithCustomer.customerId),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.orange,
                                      child: Text(
                                        ideaWithCustomer.customerName[0],
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ideaWithCustomer.customerName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          ideaWithCustomer.customerEmail,
                                          style: TextStyle(
                                              color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),                            
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(idea.description),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class IdeaWithCustomer {
  final Idea idea;
  final String customerName;
  final String customerEmail;
  final String customerId;

  IdeaWithCustomer({
    required this.idea,
    required this.customerName,
    required this.customerEmail,
    required this.customerId,
  });
}