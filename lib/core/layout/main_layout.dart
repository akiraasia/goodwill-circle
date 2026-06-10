import 'package:flutter/material.dart';
import 'package:goodwill_circle/features/profile/profile_screen.dart';
import 'package:goodwill_circle/features/requests/requests_screen.dart';
import 'package:goodwill_circle/features/campaigns/campaigns_screen.dart';
import 'package:goodwill_circle/features/agenda/agenda_screen.dart';
import 'package:goodwill_circle/features/confessions/confessions_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const RequestsScreen(),
    const CampaignsScreen(),
    const AgendaScreen(),
    const ConfessionsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Campaigns',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Confess',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
