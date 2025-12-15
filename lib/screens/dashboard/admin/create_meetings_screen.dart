import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:startup_corner/models/admin_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  _CreateMeetingScreenState createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  DateTime? _selectedDateTime;
  final TextEditingController _linkController = TextEditingController();
  List<String> _selectedParticipants = [];
  List<Map<String, dynamic>> _allUsers = [];
  Admin? _currentAdmin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminAndUsers();
  }

  Future<void> _launchGoogleMeet() async {
    const url = 'https://meet.google.com/new';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch Google Meet')),
      );
    }
  }

  Future<void> _fetchAdminAndUsers() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No authenticated user found');
      }
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(firebaseUser.uid)
          .get();

      if (!adminDoc.exists || adminDoc.data()?['role'] != 'admin') {
        throw Exception('User is not an admin or document not found');
      }

      setState(() {
        _currentAdmin = Admin.fromJson(adminDoc.data()!);
      });

      final customers = await FirebaseFirestore.instance
          .collection('customers')
          .where('role', isEqualTo: 'customer')
          .get();
      final mentors = await FirebaseFirestore.instance
          .collection('mentors')
          .where('role', isEqualTo: 'mentor')
          .get();
      final investors = await FirebaseFirestore.instance
          .collection('investors')
          .where('role', isEqualTo: 'investor')
          .get();

      setState(() {
        _allUsers = [
          ...customers.docs.map((doc) => {
                'id': doc.id,
                'name': doc['name'],
                'role': 'customer',
                'collection': 'customers'
              }),
          ...mentors.docs.map((doc) => {
                'id': doc.id,
                'name': doc['name'],
                'role': 'mentor',
                'collection': 'mentors'
              }),
          ...investors.docs.map((doc) => {
                'id': doc.id,
                'name': doc['name'],
                'role': 'investor',
                'collection': 'investors'
              }),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createMeeting() async {
    if (_currentAdmin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin data not loaded')),
      );
      return;
    }
    if (_selectedDateTime == null || _selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select date/time and participants')),
      );
      return;
    }
    if (_linkController.text.isEmpty ||
        !_linkController.text.startsWith('meet.google.com/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a valid Google Meet link')),
      );
      return;
    }

    try {
      final meeting = Meeting(
        link: _linkController.text,
        dateTime: _selectedDateTime!,
        participants: _selectedParticipants,
      );

      final meetingRef = await FirebaseFirestore.instance
          .collection('meetings')
          .add(meeting.toJson());
      final meetingId = meetingRef.id;

      final updatedAdminMeetings = [..._currentAdmin!.meetings, meeting];
      await FirebaseFirestore.instance
          .collection('admins')
          .doc(_currentAdmin!.id)
          .update({
        'meetings': updatedAdminMeetings.map((m) => m.toJson()).toList(),
      });

      for (String participantId in _selectedParticipants) {
        final user = _allUsers.firstWhere((u) => u['id'] == participantId);
        final collectionName = user['collection'];

        final userDoc = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(participantId)
            .get();

        List<String> currentMeetings =
            List<String>.from(userDoc.data()?['meetings'] ?? []);
        currentMeetings.add(meetingId);

        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(participantId)
            .update({'meetings': currentMeetings});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating meeting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Meeting'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _linkController,
                                decoration: const InputDecoration(
                                  labelText: 'Google Meet Link',
                                  border: OutlineInputBorder(),
                                  hintText: 'Paste your Google Meet link here',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _launchGoogleMeet,
                              child: const Text('Create Link'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _pickDateTime,
                          child: Text(_selectedDateTime == null
                              ? 'Select Date & Time'
                              : 'Meeting at: ${_selectedDateTime!.toString()}'),
                        ),
                        const SizedBox(height: 16),
                        const Text('Select Participants:',
                            style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = _allUsers[index];
                        return CheckboxListTile(
                          title: Text('${user['name']} (${user['role']})'),
                          value: _selectedParticipants.contains(user['id']),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedParticipants.add(user['id']);
                              } else {
                                _selectedParticipants.remove(user['id']);
                              }
                            });
                          },
                        );
                      },
                      childCount: _allUsers.isEmpty ? 1 : _allUsers.length,
                    ),
                  ),
                  if (_allUsers.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(child: Text('No users available')),
                    ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _createMeeting,
                          child: const Text('Create Meeting'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
