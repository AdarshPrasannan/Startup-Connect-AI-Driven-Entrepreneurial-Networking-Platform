import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:startup_corner/api/auth_api.dart';
import 'package:startup_corner/models/customer_model.dart';
import './chat_screen.dart';

class TopIdeasScreen extends StatefulWidget {
  const TopIdeasScreen({super.key});

  @override
  _TopIdeasScreenState createState() => _TopIdeasScreenState();
}

class _TopIdeasScreenState extends State<TopIdeasScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthAPI _authAPI = AuthAPI();
  List<IdeaWithCustomer> _approvedThoughts = [];
  late String _userId;
  final TextEditingController _thoughtController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid ?? "";
    _loadApprovedThoughts();
  }

  Future<void> _loadApprovedThoughts() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> customersSnapshot =
          await _firestore.collection('customers').get();

      List<IdeaWithCustomer> approvedThoughts = [];

      for (final doc in customersSnapshot.docs) {
        final Customer customer = Customer.fromJson(doc.data());
        final approvedThoughtsForCustomer = customer.thoughts
            .where((thought) => thought.status == 'approved')
            .map((thought) => IdeaWithCustomer(
                  idea: thought,
                  customerName: customer.name,
                  customerEmail: customer.email,
                  customerId: doc.id,
                ))
            .toList();
        approvedThoughts.addAll(approvedThoughtsForCustomer);
      }

      final now = Timestamp.now();
      final twentyFourHoursAgo = Timestamp.fromMillisecondsSinceEpoch(
          now.toDate().subtract(Duration(hours: 24)).millisecondsSinceEpoch);

      approvedThoughts.sort((a, b) {
        int votesA = a.idea.voteTimestamps
            .where((t) => t.compareTo(twentyFourHoursAgo) >= 0)
            .length;
        int votesB = b.idea.voteTimestamps
            .where((t) => t.compareTo(twentyFourHoursAgo) >= 0)
            .length;
        return votesB.compareTo(votesA);
      });

      setState(() {
        _approvedThoughts = approvedThoughts;
      });
    } catch (e) {
      debugPrint('Error loading approved thoughts: $e');
    }
  }

  Future<void> _voteThought(
      IdeaWithCustomer thoughtWithCustomer, String userId) async {
    try {
      final customerDoc = _firestore
          .collection('customers')
          .doc(thoughtWithCustomer.customerId);
      final customerSnapshot = await customerDoc.get();

      if (customerSnapshot.exists) {
        final Customer customer = Customer.fromJson(customerSnapshot.data()!);
        final thoughtIndex = customer.thoughts.indexWhere((customerThought) =>
            customerThought.description ==
                thoughtWithCustomer.idea.description &&
            customerThought.report == thoughtWithCustomer.idea.report);

        if (thoughtIndex != -1) {
          final Idea currentThought = customer.thoughts[thoughtIndex];

          // Check if user has already voted
          if (currentThought.voters.contains(userId)) {
            // Remove vote
            final updatedVoters = List<String>.from(currentThought.voters)
              ..remove(userId);
            final updatedTimestamps =
                List<Timestamp>.from(currentThought.voteTimestamps);
            // Remove the most recent timestamp from this user (assuming last vote was theirs)
            if (updatedTimestamps.isNotEmpty) {
              updatedTimestamps.removeLast();
            }

            customer.thoughts[thoughtIndex] = Idea(
              description: currentThought.description,
              report: currentThought.report,
              status: currentThought.status,
              vote: currentThought.vote - 1,
              voters: updatedVoters,
              voteTimestamps: updatedTimestamps,
            );

            debugPrint("User vote removed from this thought.");
          } else {
            customer.thoughts[thoughtIndex] = Idea(
              description: currentThought.description,
              report: currentThought.report,
              status: currentThought.status,
              vote: currentThought.vote + 1,
              voters: [...currentThought.voters, userId],
              voteTimestamps: [
                ...currentThought.voteTimestamps,
                Timestamp.now()
              ],
            );

            debugPrint("User vote added to this thought.");
          }

          await customerDoc.update(customer.toJson());
          _loadApprovedThoughts();
        }
      }
    } catch (e) {
      debugPrint('Error voting for thought: $e');
    }
  }

  Future<void> _postThought() async {
    if (_thoughtController.text.trim().isEmpty) return;
    try {
      final customerDoc = _firestore.collection('customers').doc(_userId);
      final customerSnapshot = await customerDoc.get();

      if (!customerSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Customer not found. Please register first.")),
        );
        return;
      }

      final customer = Customer.fromJson(customerSnapshot.data()!);

      final newThought = Idea(
        description: _thoughtController.text.trim(),
        report: "",
        status: "approved",
        vote: 0,
        voters: [],
        voteTimestamps: [],
      );

      customer.thoughts.add(newThought);
      await customerDoc.set(customer.toJson());
      _thoughtController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Thought posted!")),
      );
      _loadApprovedThoughts();
    } catch (e) {
      debugPrint('Error posting thought: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to post thought: $e")),
      );
    }
  }

  Future<void> _startChatWithUser(String otherUserId) async {
    if (_userId == otherUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Its an idea posted by you.")),
      );
      return;
    }

    try {
      String? chatRoomId =
          await _authAPI.createChatRoom([_userId, otherUserId]);
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _thoughtController,
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _postThought,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                        ),
                        child:
                            Text("Post", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _approvedThoughts.isEmpty
                ? Center(child: Text('No thoughts yet!.'))
                : ListView.builder(
                    itemCount: _approvedThoughts.length,
                    itemBuilder: (context, index) {
                      final thoughtWithCustomer = _approvedThoughts[index];
                      final thought = thoughtWithCustomer.idea;
                      bool isTopThought = index == 0;

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
                                    thoughtWithCustomer.customerId),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.blue[800],
                                      child: Text(
                                        thoughtWithCustomer.customerName[0],
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          thoughtWithCustomer.customerName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          thoughtWithCustomer.customerEmail,
                                          style: TextStyle(
                                              color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    if (isTopThought) ...[
                                      SizedBox(width: 10),
                                      Chip(
                                        label: Text("Top Thought"),
                                        backgroundColor: Colors.yellow[200],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(thought.description),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.thumb_up,
                                          color:
                                              thought.voters.contains(_userId)
                                                  ? Colors.blue[800]
                                                  : Colors.grey,
                                        ),
                                        onPressed: () => _voteThought(
                                            thoughtWithCustomer, _userId),
                                      ),
                                      Text("${thought.vote} Likes"),
                                    ],
                                  ),
                                  Text(
                                    "${DateTime.now().difference(thought.voteTimestamps.isNotEmpty ? thought.voteTimestamps.last.toDate() : DateTime.now()).inHours}h ago",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
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
