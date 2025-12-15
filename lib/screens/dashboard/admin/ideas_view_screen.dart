import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:startup_corner/models/customer_model.dart';

class IdeaViewScreen extends StatefulWidget {
  const IdeaViewScreen({super.key});

  @override
  _IdeaViewScreenState createState() => _IdeaViewScreenState();
}

class _IdeaViewScreenState extends State<IdeaViewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Idea> _pendingIdeas = [];
  List<bool> _expanded = []; // Track expanded state for each idea

  @override
  void initState() {
    super.initState();
    _loadPendingIdeas();
  }

  Future<void> _loadPendingIdeas() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> customersSnapshot =
          await _firestore.collection('customers').get();

      List<Idea> allPendingIdeas = [];

      for (final doc in customersSnapshot.docs) {
        final Customer customer = Customer.fromJson(doc.data());
        final pendingIdeas =
            customer.ideas.where((idea) => idea.status == 'pending').toList();
        allPendingIdeas.addAll(pendingIdeas);
      }

      setState(() {
        _pendingIdeas = allPendingIdeas;
        _expanded = List.generate(_pendingIdeas.length, (index) => false); // Initialize expanded states
      });
    } catch (e) {
      print('Error loading pending ideas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pendingIdeas.isEmpty
          ? Center(child: Text('No pending ideas.'))
          : ListView.builder(
              itemCount: _pendingIdeas.length,
              itemBuilder: (context, index) {
                final idea = _pendingIdeas[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ExpansionTile(
                    title: Text('Idea: ${idea.description}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Report: ${idea.report}'),
                            SizedBox(height: 8),
                            Text('Status: ${idea.status}'),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check),
                                  onPressed: () {
                                    _updateIdeaStatus(idea, 'approved');
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    _updateIdeaStatus(idea, 'rejected');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _updateIdeaStatus(Idea idea, String newStatus) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> customersSnapshot =
          await _firestore.collection('customers').get();

      for (final doc in customersSnapshot.docs) {
        final Customer customer = Customer.fromJson(doc.data());
        final ideaIndex = customer.ideas.indexWhere((customerIdea) =>
            customerIdea.description == idea.description &&
            customerIdea.report == idea.report);

        if (ideaIndex != -1) {
          customer.ideas[ideaIndex] = Idea(
            description: idea.description,
            report: idea.report,
            status: newStatus,
            vote: idea.vote,
            voters: idea.voters
          );

          await _firestore.collection('customers').doc(doc.id).update(customer.toJson());
          _loadPendingIdeas(); // Refresh the list
          return; // Exit after updating
        }
      }

      print('Idea not found for update.');
    } catch (e) {
      print('Error updating idea status: $e');
      // Handle error, e.g., show a snackbar
    }
  }
}