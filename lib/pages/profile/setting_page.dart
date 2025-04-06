import 'package:do_an_test/pages/login_register/login_page.dart';
import 'package:do_an_test/pages/profile/update_information.dart';
import 'package:do_an_test/common/widget/navigation_animation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_test/services/user_service.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Khởi tạo trực tiếp các service cần dùng
    final userService = UserService();
    final auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 128, 98, 1),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _buildSectionHeader('Account Settings'),
            _buildSettingItem(
              context: context,
              title: 'Update account',
              icon: Icons.person_outline,
              onTap: () {
                navigateWithSlide(context, const UpdateAccountScreen());
              },
            ),
            const Divider(height: 1),
            _buildSettingItem(
              context: context,
              title: 'Delete account',
              icon: Icons.delete_outline,
              isDestructive: true,
              onTap: () => _showDeleteConfirmation(context, userService, auth),
            ),
            const SizedBox(height: 32),
            // _buildSectionHeader('App Settings'),
            // _buildSettingItem(
            //   context: context,
            //   title: 'Notifications',
            //   icon: Icons.notifications_outlined,
            //   onTap: () {
            //     // Handle notifications
            //   },
            // ),
            // const Divider(height: 1),
            // _buildSettingItem(
            //   context: context,
            //   title: 'Language',
            //   icon: Icons.language_outlined,
            //   onTap: () {
            //     // Handle language
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontSize: 16,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    UserService userService,
    FirebaseAuth auth,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                try {
                  final user = auth.currentUser;
                  if (user != null) {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );

                    // Delete user data from Firestore
                    await userService.deleteUser(user.uid);

                    // Delete user from Firebase Authentication
                    await user.delete();

                    // Sign out
                    await auth.signOut();

                    // Close loading indicator and delete confirmation dialog
                    Navigator.pop(context);
                    Navigator.pop(context);

                    // Navigate to login/welcome screen
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  // Close loading indicator if shown
                  Navigator.pop(context);
                  Navigator.pop(context);

                  // Show error dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Error'),
                        content:
                            Text('Failed to delete account: ${e.toString()}'),
                        actions: [
                          TextButton(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
