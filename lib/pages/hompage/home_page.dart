import 'package:do_an_test/services/lesson_service.dart';
import 'package:do_an_test/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:do_an_test/pages/hompage/compoment/level.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LessonService _lessonService = LessonService();
  final UserService _userService = UserService();
  final _auth = auth.FirebaseAuth.instance;

  List<DocumentSnapshot> _levels = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final futures = <Future>[
        _lessonService.getAllLevels(),
      ];

      // Only fetch user data if user is logged in
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        futures.add(_userService.getUser(currentUser.uid));
      }

      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _levels = results[0] as List<DocumentSnapshot>;
          if (results.length > 1) {
            _userData = results[1] as Map<String, dynamic>?;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMessage ?? 'An error occurred',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    // final totalStars = _calculateTotalStars();
    final userName = _userData?['name'] as String? ?? 'User';
    final userAvatar =
        _userData?['avatar'] as String? ?? 'assets/images/avatar.webp';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF008062),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: userAvatar.startsWith('assets/')
                      ? AssetImage(userAvatar) as ImageProvider
                      : NetworkImage(userAvatar),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Stars Earned',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(body: _buildErrorWidget());
    }

    return Scaffold(
      body: Column(
        children: [
          _buildProgressHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: _levels.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final level = _levels[index];
                  return Level(
                    levelId: level.id,
                    userId: _auth.currentUser?.uid,
                    order: level['order'] as int? ?? 0,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom scroll behavior to maintain iOS-style bouncing effect
class CustomScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}
