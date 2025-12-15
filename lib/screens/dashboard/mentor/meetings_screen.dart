import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:startup_corner/models/customer_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import

class MentorsMeetingScreen extends StatefulWidget {
  const MentorsMeetingScreen({super.key});

  @override
  State<MentorsMeetingScreen> createState() => _MentorsMeetingScreenState();
}

class _MentorsMeetingScreenState extends State<MentorsMeetingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid ?? "";
  }

  Future<Map<String, dynamic>?> _fetchMeetingDetails(String meetingId) async {
    try {
      final meetingDoc =
          await _firestore.collection('meetings').doc(meetingId).get();
      if (meetingDoc.exists) {
        return meetingDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching meeting details: $e');
      return null;
    }
  }

  Future<Map<String, String>> _fetchParticipantDetails(
      String participantId) async {
    try {
      var doc =
          await _firestore.collection('customers').doc(participantId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': participantId,
          'name': data['name'] ?? 'Unknown',
          'role': 'Customer'
        };
      }

      doc = await _firestore.collection('mentors').doc(participantId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': participantId,
          'name': data['name'] ?? 'Unknown',
          'role': 'Mentor'
        };
      }

      doc = await _firestore.collection('investors').doc(participantId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': participantId,
          'name': data['name'] ?? 'Unknown',
          'role': 'Investor'
        };
      }

      return {'id': participantId, 'name': 'Unknown', 'role': 'Unknown'};
    } catch (e) {
      debugPrint('Error fetching participant details: $e');
      return {'id': participantId, 'name': 'Unknown', 'role': 'Unknown'};
    }
  }


  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse('https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "My Meetings", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('mentors').doc(_userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text("No meetings found"));
          }

          final customerData = snapshot.data!.data() as Map<String, dynamic>;
          final Customer customer = Customer.fromJson(customerData);
          final List<String> meetingIds = customer.meetings;

          return FutureBuilder<List<Map<String, dynamic>?>>(
            future:
                Future.wait(meetingIds.map((id) => _fetchMeetingDetails(id))),
            builder: (context, meetingSnapshot) {
              if (meetingSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!meetingSnapshot.hasData || meetingSnapshot.data!.isEmpty) {
                return const Center(child: Text("No meetings available"));
              }

              final meetings =
                  meetingSnapshot.data!.where((m) => m != null).toList();
              List<Map<String, dynamic>> upcomingMeetings = [];
              List<Map<String, dynamic>> pastMeetings = [];

              for (var meeting in meetings) {
                final meetingDate = DateTime.parse(meeting!['dateTime']);
                if (meetingDate.isAfter(currentDate)) {
                  upcomingMeetings.add(meeting);
                } else {
                  pastMeetings.add(meeting);
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upcoming Meetings Section
                    Text(
                      "Upcoming Meetings",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (upcomingMeetings.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text("No upcoming meetings"),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: upcomingMeetings.length,
                        itemBuilder: (context, index) {
                          final meeting = upcomingMeetings[index];
                          final meetingDate =
                              DateTime.parse(meeting['dateTime']);
                          final formattedDate =
                              DateFormat('MMM dd, yyyy - HH:mm')
                                  .format(meetingDate);

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => _launchURL(meeting['link']),
                                    child: Text(
                                      "Meeting Link: ${meeting['link']}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 5),
                                  FutureBuilder<List<Map<String, String>>>(
                                    future: Future.wait(
                                      (meeting['participants'] as List<dynamic>)
                                          .map((id) => _fetchParticipantDetails(
                                              id as String)),
                                    ),
                                    builder: (context, participantSnapshot) {
                                      if (participantSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Text(
                                            "Loading participants...");
                                      }
                                      if (!participantSnapshot.hasData) {
                                        return const Text(
                                            "No participants found");
                                      }
                                      final participants =
                                          participantSnapshot.data!;
                                      final participantText = participants
                                          .map((p) =>
                                              "${p['name']} (${p['id'] == _userId ? 'you' : p['role']})")
                                          .join(', ');
                                      return Text(
                                        "Participants: $participantText",
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),

                    // Past Meetings Section
                    Text(
                      "Past Meetings",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (pastMeetings.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text("No past meetings"),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pastMeetings.length,
                        itemBuilder: (context, index) {
                          final meeting = pastMeetings[index];
                          final meetingDate =
                              DateTime.parse(meeting['dateTime']);
                          final formattedDate =
                              DateFormat('MMM dd, yyyy - HH:mm')
                                  .format(meetingDate);

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => _launchURL(meeting['link']),
                                    child: Text(
                                      "Meeting Link: ${meeting['link']}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 5),
                                  FutureBuilder<List<Map<String, String>>>(
                                    future: Future.wait(
                                      (meeting['participants'] as List<dynamic>)
                                          .map((id) => _fetchParticipantDetails(
                                              id as String)),
                                    ),
                                    builder: (context, participantSnapshot) {
                                      if (participantSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Text(
                                            "Loading participants...");
                                      }
                                      if (!participantSnapshot.hasData) {
                                        return const Text(
                                            "No participants found");
                                      }
                                      final participants =
                                          participantSnapshot.data!;
                                      final participantText = participants
                                          .map((p) =>
                                              "${p['name']} (${p['id'] == _userId ? 'you' : p['role']})")
                                          .join(', ');
                                      return Text(
                                        "Participants: $participantText",
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
