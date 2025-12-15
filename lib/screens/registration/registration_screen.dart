import 'package:flutter/material.dart';
import 'package:startup_corner/api/auth_api.dart';
import 'package:startup_corner/models/customer_model.dart';
import 'package:startup_corner/models/investor_model.dart';
import 'package:startup_corner/models/mentor_model.dart';
import 'package:startup_corner/models/user_model.dart';
import 'package:startup_corner/screens/dashboard/dashboard_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool isLoading = false;
  String? selectedRole;
  final List<String> roles = ['Customer', 'Mentor', 'Investor'];
  final List<String> expertiseOptions = [
    'AI',
    'Business',
    'Marketing',
    'Finance',
    'Technology',
    'Health',
    'Education'
  ];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController investmentBudgetController =
      TextEditingController();
  final TextEditingController phoneController =
      TextEditingController(); // Added phone controller
  final List<String> selectedExpertise = [];

  void toggleExpertise(String expertise) {
    setState(() {
      if (selectedExpertise.contains(expertise)) {
        selectedExpertise.remove(expertise);
      } else if (selectedExpertise.length < 5) {
        selectedExpertise.add(expertise);
      }
    });
  }

  Future<void> handleRegistration() async {
    if (isLoading) return;

    if (selectedRole == null) {
      showSnackBar('Please select a role!', Colors.red);
      return;
    }

    // Basic validation for all roles
    if (nameController.text.isEmpty || bioController.text.isEmpty) {
      showSnackBar('Name and Bio are required!', Colors.red);
      return;
    }

    // Additional validation for Customer
    if (selectedRole == 'Customer' && phoneController.text.isEmpty) {
      showSnackBar('Phone number is required for customers!', Colors.red);
      return;
    }

    // Additional validation for Mentor and Investor
    if (selectedRole == 'Mentor' && selectedExpertise.isEmpty) {
      showSnackBar('Please select at least one expertise!', Colors.red);
      return;
    }

    if (selectedRole == 'Investor' && investmentBudgetController.text.isEmpty) {
      showSnackBar('Investment budget is required for investors!', Colors.red);
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final authAPI = AuthAPI();
      final userInstance = await authAPI.getCurrentUserInstance();
      final email = userInstance!.email;
      final String profilePicture = '';

      UserModel user;
      switch (selectedRole) {
        case 'Mentor':
          user = Mentor(
            id: userInstance.uid,
            name: nameController.text,
            email: email ?? '',
            profilePicture: profilePicture,
            bio: bioController.text,
            expertise: selectedExpertise,
            meetings: [],
            verified: 'pending'
          );
          break;
        case 'Investor':
          user = Investor(
            id: userInstance.uid,
            name: nameController.text,
            email: email ?? '',
            profilePicture: profilePicture,
            bio: bioController.text,
            investmentBudget:
                double.tryParse(investmentBudgetController.text) ?? 0.0,
            meetings: [],
            verified: 'pending'
          );
          break;
        default: // Customer
          user = Customer(
            id: userInstance.uid,
            name: nameController.text,
            email: email ?? '',
            profilePicture: profilePicture,
            bio: bioController.text,
            projects: [],
            ideas: [],
            meetings: [],
            thoughts: [],
            phoneNumber:
                phoneController.text, 
            verified: 'pending'
          );
          break;
      }

      final result = await authAPI.createUser(user, selectedRole);
      if (result) {
        showSnackBar('User registered successfully!', Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        showSnackBar('User registration failed!', Colors.red);
      }
    } catch (e) {
      debugPrint('Error during registration: $e');
      showSnackBar('User registration failed!', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: roles
                  .map((role) =>
                      DropdownMenuItem(value: role, child: Text(role)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                  selectedExpertise.clear();
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            if (selectedRole == 'Customer') ...[
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone, // Numeric keyboard for phone
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (selectedRole == 'Mentor') ...[
              Wrap(
                spacing: 8.0,
                children: expertiseOptions.map((expertise) {
                  bool isSelected = selectedExpertise.contains(expertise);
                  return ChoiceChip(
                    label: Text(expertise),
                    selected: isSelected,
                    onSelected: (_) => toggleExpertise(expertise),
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            if (selectedRole == 'Investor') ...[
              TextField(
                controller: investmentBudgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Investment Budget',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Center(
              child: ElevatedButton(
                onPressed: handleRegistration,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
