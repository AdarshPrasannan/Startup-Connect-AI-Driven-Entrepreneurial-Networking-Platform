import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:startup_corner/models/customer_model.dart';

class IdeasScreen extends StatelessWidget {
  const IdeasScreen({super.key});

  Future<List<Idea>> fetchUserIdeas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .get();

    if (!doc.exists) return [];

    Customer customer = Customer.fromJson(doc.data() as Map<String, dynamic>);
    return customer.ideas.reversed.toList(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Ideas")),
      body: FutureBuilder<List<Idea>>(
        future: fetchUserIdeas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No ideas uploaded yet."));
          }

          List<Idea> sortedIdeas = snapshot.data!;

          return ListView.builder(
            itemCount: sortedIdeas.length,
            itemBuilder: (context, index) {
              final idea = sortedIdeas[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ExpansionTile(
                  title: Text(
                    idea.description.length > 50
                        ? "${idea.description.substring(0, 50)}..." // Show preview
                        : idea.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    "Status: ${idea.status}",
                    style: TextStyle(
                        color: idea.status == "approved"
                            ? Colors.green
                            : idea.status == "pending"
                                ? Colors.orange
                                : Colors.red),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        idea.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 10),
                      child: Text(
                        "Report: ${idea.report}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
