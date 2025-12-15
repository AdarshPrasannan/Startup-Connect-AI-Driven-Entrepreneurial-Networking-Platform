import 'package:flutter/material.dart';
import 'package:startup_corner/screens/dashboard/investor/investor_idea_view.dart';
import 'package:startup_corner/screens/dashboard/investor/investor_profile_screen.dart';
import 'package:startup_corner/screens/dashboard/investor/meeting_screen.dart';
import 'package:startup_corner/screens/dashboard/investor/investor_chat_list.dart';


class InvestorBottomNavBar extends StatefulWidget {
  const InvestorBottomNavBar({super.key});

  @override
  _InvestorBottomNavBarState createState() => _InvestorBottomNavBarState();
}

class _InvestorBottomNavBarState extends State<InvestorBottomNavBar> {
  int _selectedIndex = 0;


  final List<Widget> _screens = [
    InvestorTopIdeasScreen(),     
    ChatListScreen(),           
    InvestorMeetingScreen(),
    InvestorProfileScreen() 
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
        backgroundColor: Colors.orange,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Ideas',
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}