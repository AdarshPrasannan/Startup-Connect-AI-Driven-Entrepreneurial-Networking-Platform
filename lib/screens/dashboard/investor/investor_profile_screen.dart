import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:startup_corner/api/auth_api.dart';
import 'package:startup_corner/models/investor_model.dart'; // Updated import

class InvestorProfileScreen extends StatefulWidget {
  const InvestorProfileScreen({super.key});

  @override
  State<InvestorProfileScreen> createState() => _InvestorProfileScreenState();
}

class _InvestorProfileScreenState extends State<InvestorProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final AuthAPI _authAPI = AuthAPI();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController
      _investmentBudgetController; // Changed from phone to investmentBudget
  Investor? _userData; // Changed type to Investor

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _emailController = TextEditingController();
    _investmentBudgetController =
        TextEditingController(); // Initialize investmentBudget controller
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        final userData = await _authAPI.readCurrentUser();
        setState(() {
          _userData = userData as Investor?; // Cast to Investor
          _nameController.text = _userData?.name ?? '';
          _bioController.text = _userData?.bio ?? '';
          _emailController.text = user?.email ?? '';
          _investmentBudgetController.text =
              _userData?.investmentBudget.toString() ?? '0.0';
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
            .collection('investors') // Changed collection to 'investors'
            .doc(user!.uid)
            .update({
          'name': _nameController.text,
          'bio': _bioController.text,
          'investmentBudget':
              double.tryParse(_investmentBudgetController.text) ?? 0.0,
        });

        setState(() {
          _userData = Investor(
            id: user!.uid,
            name: _nameController.text,
            bio: _bioController.text,
            email: _emailController.text,
            profilePicture: _userData?.profilePicture ?? '',
            investmentBudget:
                double.tryParse(_investmentBudgetController.text) ?? 0.0,
            meetings: _userData?.meetings ?? [],
            verified: _userData?.verified ?? 'approved'
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
    _investmentBudgetController
        .dispose(); // Dispose investmentBudget controller
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
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Icon(Icons.person, size: 60, color: Colors.orange)
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
            // Investment Budget Field (Editable)
            TextField(
              controller: _investmentBudgetController,
              keyboardType: TextInputType.number, // Set keyboard to number type
              decoration: InputDecoration(
                labelText: 'Investment Budget (\$)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                  icon: Icons.attach_money,
                  title: 'Budget',
                  count: (_userData?.investmentBudget ?? 0.0)
                      .toInt(), // Display as int for simplicity
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Update Button
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
        color: Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
          Text(
            '$count',
            style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
