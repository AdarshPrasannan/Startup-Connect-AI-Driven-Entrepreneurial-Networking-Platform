import 'package:flutter/material.dart';
import 'package:startup_corner/screens/dashboard/mentor/idea_screen_mentor.dart';
import 'package:startup_corner/screens/dashboard/mentor/meetings_screen.dart';
import 'package:startup_corner/screens/dashboard/mentor/mentor_chatlist_screen.dart';
import 'package:startup_corner/screens/dashboard/mentor/mentor_profile_screen.dart';

class MentorBottomNavBarScreen extends StatefulWidget {
  const MentorBottomNavBarScreen({super.key});

  @override
  State<MentorBottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<MentorBottomNavBarScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TopIdeasScreenMentor(),
     ChatListScreen(), // Added const where possible
    const MentorsMeetingScreen(),
    const MentorProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Explicitly set to fixed
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.green, // This will now work consistently
        selectedItemColor: Colors.black38,
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'View Ideas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Meetings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}