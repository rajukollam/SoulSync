import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      showMessage("Please enter your email");
      return;
    }

    if (password.isEmpty) {
      showMessage("Please enter your password");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _authService.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      showMessage("Welcome back ❤️");

      // AuthGate will automatically navigate
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      showMessage(getErrorMessage(e.toString()));
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email.';
    }

    if (error.contains('wrong-password')) {
      return 'Incorrect password.';
    }

    if (error.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }

    if (error.contains('invalid-email')) {
      return 'Please enter a valid email.';
    }

    if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }

    return error;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                const Icon(
                  Icons.favorite_rounded,
                  size: 80,
                  color: Colors.pink,
                ),

                const SizedBox(height: 20),

                const Text(
                  "SoulSync",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Stay connected with the one you love ❤️",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                       builder: (context) => RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Create a new account",
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}