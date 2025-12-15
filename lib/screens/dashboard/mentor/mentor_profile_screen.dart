import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:startup_corner/api/auth_api.dart';
import 'package:startup_corner/models/mentor_model.dart';

class MentorProfileScreen extends StatefulWidget {
  const MentorProfileScreen({super.key});

  @override
  State<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final AuthAPI _authAPI = AuthAPI();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  Mentor? _userData;
  List<String> _selectedExpertise = [];

  final List<String> _expertiseOptions = [
    'AI',
    'Business',
    'Marketing',
    'Finance',
    'Technology',
    'Health',
    'Education'
    'Project Management',
    'Marketing',
    'Finance',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        final userData = await _authAPI.readCurrentUser();
        setState(() {
          _userData = userData as Mentor?;
          _nameController.text = _userData?.name ?? '';
          _bioController.text = _userData?.bio ?? '';
          _emailController.text = user?.email ?? '';
          _selectedExpertise = _userData?.expertise ?? [];
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('mentors')
            .doc(user!.uid)
            .update({
          'name': _nameController.text,
          'bio': _bioController.text,
          'expertise': _selectedExpertise,
        });

        setState(() {
          _userData = Mentor(
            id: user!.uid,
            name: _nameController.text,
            bio: _bioController.text,
            email: _emailController.text,
            profilePicture: _userData?.profilePicture ?? '',
            expertise: _selectedExpertise,
            meetings: _userData?.meetings ?? [],
            verified: _userData?.verified ?? 'approved',
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  void _showMultiSelectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return MultiSelectDialog(
          options: _expertiseOptions,
          selectedOptions: _selectedExpertise,
          maxSelections: 5,
          onConfirm: (List<String> selected) {
            setState(() {
              _selectedExpertise = selected;
            });
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Icon(Icons.person, size: 60, color: Colors.green)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            // Name Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Email Field (Disabled)
            TextField(
              controller: _emailController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 16),
            // Expertise Multi-Select Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton(
                  onPressed: _showMultiSelectDialog,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedExpertise.isEmpty
                            ? 'Select Expertise (up to 5)'
                            : _selectedExpertise.join(', '),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.green),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bio Field
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  icon: Icons.people,
                  title: 'Meetings',
                  count: _userData?.meetings.length ?? 0,
                ),
                _buildStatCard(
                  icon: Icons.school,
                  title: 'Expertise',
                  count: _selectedExpertise
                      .length, // Updated to use selected expertise
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Update Button
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Update Profile',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.lightGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
                fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            '$count',
            style: const TextStyle(
                fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Custom Multi-Select Dialog Widget
class MultiSelectDialog extends StatefulWidget {
  final List<String> options;
  final List<String> selectedOptions;
  final int maxSelections;
  final Function(List<String>) onConfirm;

  const MultiSelectDialog({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.maxSelections,
    required this.onConfirm,
  });

  @override
  _MultiSelectDialogState createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedOptions);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Expertise (Max 5)'),
      content: SingleChildScrollView(
        child: Column(
          children: widget.options.map((option) {
            return CheckboxListTile(
              title: Text(option),
              value: _tempSelected.contains(option),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true &&
                      _tempSelected.length < widget.maxSelections) {
                    _tempSelected.add(option);
                  } else if (value == false) {
                    _tempSelected.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onConfirm(_tempSelected);
            Navigator.pop(context);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
