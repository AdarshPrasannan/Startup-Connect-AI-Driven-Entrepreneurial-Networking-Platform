import 'package:flutter/material.dart';
import 'package:startup_corner/api/auth_api.dart';
import 'package:startup_corner/screens/signin/signin_screen.dart';

class AccountRejectedScreen extends StatelessWidget {
  const AccountRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Rejection Icon
                _buildRejectionIcon(),
                const SizedBox(height: 32.0),
                // Title
                Text(
                  'Account Creation Rejected',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent[700],
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                // Description
                Text(
                  'We’re sorry, but your account creation request has been rejected. '
                  'Please review the details or contact support for assistance.',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40.0),
                // Info Card
                _buildInfoCard(),
                const SizedBox(height: 32.0),
                // Try Again Button
                ElevatedButton(
                  onPressed: () {
                    AuthAPI().googleSignout();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SigninScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 16.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5.0,
                  ),
                  child: const Text(
                    'Back to Sign In',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRejectionIcon() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Icon(
            Icons.cancel_rounded,
            size: 100.0,
            color: Colors.redAccent[700],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent[700],
                  size: 24.0,
                ),
                const SizedBox(width: 12.0),
                Text(
                  'Why Was It Rejected?',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              'Your application may not meet our eligibility criteria, or there could be an issue with the provided information. '
              'Contact support at support@startupcorner.com for more details.',
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}