import 'package:do_an_test/pages/hompage/home_page.dart';
import 'package:do_an_test/pages/practice/exercise/pages/practice_page.dart';
import 'package:do_an_test/pages/profile/profile_page.dart';
import 'package:do_an_test/pages/reviewpage/review_page.dart';
import 'package:do_an_test/pages/chat/compoment/chat_fab.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ReviewPage(),
    const PracticePage(),
    const ProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: const ChatFAB(),
      bottomNavigationBar: SafeArea(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF008062),
          selectedItemColor: Colors.white,
          unselectedItemColor: const Color(0xFF2E4053),
          iconSize: 30,
          unselectedFontSize: 0,
          selectedFontSize: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Review',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'Practise',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
