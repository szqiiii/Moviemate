// screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'discover_tab.dart';
import 'search_tab.dart';
import 'diary_tab.dart';
import 'profile_tab.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    DiscoverTab(),
    SearchTab(),
    DiaryTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E27),
      appBar: _currentIndex == 0 ? AppBar(
        backgroundColor: Color(0xFF0A0E27),
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.movie_filter, color: Color(0xFFE535AB), size: 28),
            SizedBox(width: 8),
            Text(
              'Movie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Mate',
              style: TextStyle(
                color: Color(0xFFE535AB),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                setState(() => _currentIndex = 3);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFE535AB), Color(0xFF9D4EDD)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFE535AB).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 20,
                  child: Text(
                    'H',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ) : null,
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
      ),
    );
  }
}