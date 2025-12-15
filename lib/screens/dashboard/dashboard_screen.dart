import 'package:flutter/material.dart';
import 'package:startup_corner/api/auth_api.dart';
import 'package:startup_corner/models/user_model.dart';
import 'package:startup_corner/screens/dashboard/admin/admin_dashboard.dart';
import 'package:startup_corner/screens/dashboard/customer/meetings_screen.dart';
import 'package:startup_corner/screens/dashboard/investor/bottom_navigation_bar.dart';
import 'package:startup_corner/screens/dashboard/mentor/bottom_navigationbar.dart';
import 'package:startup_corner/screens/registration/registration_screen.dart';
import 'package:startup_corner/screens/signin/signin_screen.dart';
import 'package:startup_corner/screens/dashboard/customer/customer_dashboard.dart';
import 'package:startup_corner/screens/verified/account_rejected_screen.dart';
import 'package:startup_corner/screens/verified/unverified_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool verification = true;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _checkIsVerified();
  }

  void _checkIsVerified() async {
    try {
      final alreadyReg = await AuthAPI().readCurrentUser();
      if (alreadyReg == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RegistrationScreen()),
        );
      } else {
        if (alreadyReg.role != 'admin' && alreadyReg.verified == 'pending') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const VerificationPendingScreen()),
          );
        }
        if (alreadyReg.role != 'admin' && alreadyReg.verified == 'rejected') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const AccountRejectedScreen()),
          );
        }
        setState(() {
          _user = alreadyReg;
        });
      }
    } catch (e) {
      debugPrint('Verification failed!, $e');
    } finally {
      setState(() {
        verification = false;
      });
    }
  }

  Future<void> _signOut() async {
    AuthAPI().googleSignout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SigninScreen()),
    );
  }

  void _navigateToMeetings() {
    if (_user?.role == 'customer') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MeetingScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Meetings are only available for customers")),
      );
    }
  }

  Color _getAppBarColor() {
    switch (_user?.role) {
      case 'customer':
        return Colors.blueAccent;
      case 'admin':
        return Colors.redAccent;
      case 'mentor':
        return Colors.green;
      case 'investor':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Startup Connect',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _user != null ? _getAppBarColor() : Colors.grey,
        actions: [
          // Show Meetings button only if user exists and role is customer
          if (_user != null && _user!.role == 'customer')
            IconButton(
              icon: const Icon(
                Icons.event,
                color: Colors.white,
              ),
              onPressed: _navigateToMeetings,
              tooltip: 'Meetings',
            ),
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: verification
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    if (_user == null) {
      return const Center(child: Text('User data not loaded.'));
    }

    if (_user!.role == 'customer') {
      return const CustomerDashboard();
    } else if (_user!.role == 'admin') {
      return BottomNavigationScreen();
    } else if (_user!.role == 'mentor') {
      return MentorBottomNavBarScreen();
    } else if (_user!.role == 'investor') {
      return InvestorBottomNavBar();
    } else {
      return const Center(child: Text('Unknown user role.'));
    }
  }
}
