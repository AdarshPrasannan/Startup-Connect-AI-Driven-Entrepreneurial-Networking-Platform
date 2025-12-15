import 'package:flutter/material.dart';
import 'package:startup_corner/screens/dashboard/customer/chatting_screen.dart';
import 'package:startup_corner/screens/dashboard/customer/feed_screen.dart';
import 'package:startup_corner/screens/dashboard/customer/idea_screen.dart';
import 'package:startup_corner/screens/dashboard/customer/top_ideascreen.dart';
import 'package:startup_corner/screens/dashboard/customer/profile_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;

  // List of pages for navigation, including ProfileScreen
  final List<Widget> _pages = [
    const SuccessScorePredictionScreen(),
    const FeedScreen(),
    ChatListScreen(),
    const TopIdeasScreen(),
    const ProfileScreen(), // Added ProfileScreen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blueAccent,
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: "Idea",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: "Gigs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chatting",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_circle_outlined),
            label: "Top Ideas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile", // Added Profile tab
          ),
        ],
      ),
    );
  }
}
