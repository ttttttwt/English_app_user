import 'package:do_an_test/pages/main_page.dart';
import 'package:do_an_test/pages/login_register/register_page.dart';
import 'package:do_an_test/common/widget/navigation_animation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_test/services/user_service.dart';
import 'package:do_an_test/common/constant/const_class.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final UserService _userService = UserService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      // Sign in user with email and password
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      final String userId = userCredential.user?.uid ?? '';
      final userData = await _userService.getUser(userId);

      if (userData != null) {
        // Navigate to MainPage and clear the stack
        navigateWithSlide(
          context,
          const MainPage(),
          clearStack: true,
        );
      } else {
        throw Exception('User data not found');
      }
    } catch (e) {
      if (!mounted) return;

      // Show error message based on error type
      String errorMessage = _getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateInputs() {
    final emailError = AuthErrorHandler.validateEmail(_emailController.text);
    final passwordError = AuthErrorHandler.validatePassword(_passwordController.text);

    if (emailError != null || passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError ?? passwordError ?? ''),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return AuthErrorHandler.getFirebaseAuthErrorMessage(error);
    }
    return 'Login failed: $error';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AuthUI.defaultPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Hero(
                  tag: 'app_logo',
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green[700],
                    child: const Icon(Icons.eco, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 20),
                // App Name
                Hero(
                  tag: 'app_name',
                  child: Text(
                    "PlantEnglish",
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: AuthUI.getInputDecoration(
                    hint: "Enter Email",
                    prefixIcon: Icons.email,
                  ),
                ),
                const SizedBox(height: 16),
                // Password Field
                TextField(
                  controller: _passwordController,
                  decoration: AuthUI.getInputDecoration(
                    hint: "Enter Password",
                    prefixIcon: Icons.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                ),
                const SizedBox(height: 32),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: AuthUI.defaultButtonStyle(Colors.blue[700]!),
                    onPressed: _isLoading ? null : () => _login(context),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // Register Link
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          navigateWithSlide(
                            context,
                            const RegisterPage(),
                          );
                        },
                  child: const Text(
                    "Don't have an account? Register here",
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
