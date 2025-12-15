import 'package:flutter/material.dart';
import 'package:startup_corner/api/auth_api.dart';
import 'package:startup_corner/screens/signin/signin_screen.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Icon
                _buildVerificationIcon(),
                const SizedBox(height: 32.0),
                // Title
                Text(
                  'Verification in Progress',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent[700],
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                // Description
                Text(
                  'Your account is currently under review. '
                  'This process may take a few hours. '
                  'We’ll notify you once it’s complete!',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40.0),
                // Progress Indicator
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.blueAccent[700]!),
                  strokeWidth: 5.0,
                ),
                const SizedBox(height: 40.0),
                // Info Card
                _buildInfoCard(),
                const SizedBox(height: 32.0),
                // Back to Sign In Button
                ElevatedButton(
                  onPressed: () {
                    AuthAPI().googleSignout();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SigninScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent[700],
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

  Widget _buildVerificationIcon() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Icon(
            Icons.verified_user_rounded,
            size: 100.0,
            color: Colors.blueAccent[700],
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
                  Icons.info_outline,
                  color: Colors.blueAccent[700],
                  size: 24.0,
                ),
                const SizedBox(width: 12.0),
                Text(
                  'What’s Happening?',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              'Our team is verifying your details to ensure a secure and trusted experience. '
              'You’ll gain full access once approved.',
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
