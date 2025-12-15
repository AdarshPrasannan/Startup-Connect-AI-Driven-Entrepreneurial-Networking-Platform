import 'package:flutter/material.dart';
import 'package:startup_corner/screens/dashboard/admin/ideas_view_screen.dart';
import './admin_chatlist_screen.dart';
import './create_meetings_screen.dart';
import './user_verification_screen.dart'; // Import the new screen

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({super.key});

  @override
  _BottomNavigationScreenState createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    IdeaViewScreen(),
    ChatListScreen(),
    CreateMeetingScreen(),
    UserVerificationScreen(), // Added User Verification tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Added to ensure fixed background color
        backgroundColor: Colors.redAccent, // Red background
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Ideas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Meetings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined),
            label: 'Verification',
          ), // Added Verification tab
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}