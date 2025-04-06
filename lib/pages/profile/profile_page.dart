import 'package:do_an_test/pages/login_register/login_page.dart';
import 'package:do_an_test/pages/profile/setting_page.dart';
import 'package:do_an_test/services/user_service.dart';
import 'package:do_an_test/common/widget/navigation_animation.dart';
import 'package:do_an_test/pages/profile/compoment/total_card.dart';
import 'package:do_an_test/pages/profile/compoment/total_process_line.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  final _auth = auth.FirebaseAuth.instance;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _userLearned;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);

    try {
      // Only fetch user data if user is logged in
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _userData = await _userService.getUser(currentUser.uid);
        _userLearned = await _userService.getUserLearned(currentUser.uid);
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Optionally show error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch user data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 400;
    final double horizontalPadding = isSmallScreen ? 12 : 16;
    final double avatarRadius = isSmallScreen ? 60 : 75;
    final double fontSizeName = isSmallScreen ? 20 : 24;
    final double fontSizeLevel = isSmallScreen ? 16 : 20;
    final double fontSizeTitle = isSmallScreen ? 22 : 26;
    final double fontSizeProgress = isSmallScreen ? 20 : 24;
    final EdgeInsets contentPadding =
        EdgeInsets.symmetric(horizontal: horizontalPadding);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 128, 98, 1),
        title: Padding(
          padding: EdgeInsets.only(left: horizontalPadding),
          child: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onSelected: (String result) {
              switch (result) {
                case 'Settings':
                  // Navigate to settings page
                  navigateWithSlide(context, const SettingPage());
                  break;
                case 'Logout':
                  // Perform logout
                  _auth.signOut();
                  // Navigate to login page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem<String>(
                value: 'Logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundImage:
                              const AssetImage('assets/images/avatar.webp'),
                        ),
                      ),
                      Text(
                        _userData?['name'] ?? 'John Doe',
                        style: TextStyle(
                          fontSize: fontSizeName,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromRGBO(46, 64, 83, 1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userData?['level'] ?? 'Beginner',
                        style: TextStyle(
                          fontSize: fontSizeLevel,
                          fontWeight: FontWeight.w500,
                          color: const Color.fromRGBO(46, 64, 83, 0.5),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Divider(
                      height: 2,
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                  Padding(
                    padding: contentPadding,
                    child: Column(
                      children: [
                        TotalCard(
                          color: const Color.fromRGBO(255, 221, 85, 1),
                          title: "Vocabulary",
                          total: _userLearned?['vocabulary']?.length ?? 0,
                        ),
                        const SizedBox(height: 16),
                        TotalCard(
                          color: const Color.fromRGBO(74, 144, 226, 1),
                          title: "Grammar",
                          total: _userLearned?['grammar']?.length ?? 0,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Divider(
                      height: 2,
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                  Padding(
                    padding: contentPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromRGBO(46, 64, 83, 1),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
                          child: TotalProcessLine(
                            currentStep: 0,
                            progress: 0.0,
                            labels: [
                              'Beginner',
                              'Intermediate',
                              'Advanced',
                              'Expert'
                            ],
                          ),
                        ),
                        Center(
                          child: Text(
                            "${0.0 * 100}% completed",
                            style: TextStyle(
                              fontSize: fontSizeProgress,
                              fontWeight: FontWeight.w600,
                              color: const Color.fromRGBO(46, 64, 83, 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
