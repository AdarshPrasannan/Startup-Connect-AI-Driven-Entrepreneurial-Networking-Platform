import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:startup_corner/api/auth_api.dart';
import 'package:startup_corner/models/customer_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final AuthAPI _authAPI = AuthAPI();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController; // Added phone controller
  Customer? _userData;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController(); // Initialize phone controller
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        final userData = await _authAPI.readCurrentUser();
        setState(() {
          _userData = userData as Customer?;
          _nameController.text = _userData?.name ?? '';
          _bioController.text = _userData?.bio ?? '';
          _emailController.text = user?.email ?? '';
          _phoneController.text =
              _userData?.phoneNumber ?? ''; // Load phone number
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
            .collection('customers')
            .doc(user!.uid)
            .update({
          'name': _nameController.text,
          'bio': _bioController.text,
          'phoneNumber':
              _phoneController.text, // Update phone number in Firestore
        });

        setState(() {
          _userData = Customer(
            id: user!.uid,
            name: _nameController.text,
            bio: _bioController.text,
            email: _emailController.text,
            profilePicture: '',
            projects: _userData?.projects ?? [],
            ideas: _userData?.ideas ?? [],
            meetings: _userData?.meetings ?? [],
            thoughts: _userData?.thoughts ?? [],
            phoneNumber: _phoneController.text, 
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

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose(); // Dispose phone controller
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
            // Profile Picture
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue[800]!, width: 2),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.blue[800],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            // Name Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 16),
            // Phone Number Field (Editable)
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone, // Set keyboard to phone type
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Bio Field
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                  icon: Icons.work,
                  title: 'Projects',
                  count: _userData?.projects.length ?? 0,
                ),
                _buildStatCard(
                  icon: Icons.lightbulb,
                  title: 'Ideas',
                  count: _userData?.ideas.length ?? 0,
                ),
                _buildStatCard(
                  icon: Icons.chat_bubble,
                  title: 'Thoughts',
                  count: _userData?.thoughts.length ?? 0,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Update Button
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Update Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[800], size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
