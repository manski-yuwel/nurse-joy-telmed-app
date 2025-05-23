import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/base_page.dart';
import '../../../../auth/provider/auth_service.dart';
import 'package:provider/provider.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  _SigninPageState createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return BasePage(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
          const SizedBox(height: 10),
          Center(
              child: Column(children: [
            Text("Sign-In", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Container(
              // Sign-In Form Container
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: Colors.white,
                border: Border.all(width: 0, color: Colors.white),
                borderRadius: BorderRadius.circular(35),
              ),
              child: Column(children: [
                TextField(
                  controller: _emailController,
                  obscureText: false,
                  decoration: InputDecoration(
                    hintText: "Email Address",
                    prefixIcon: const Icon(Icons.mail, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {}, // TODO: Forgot password logic
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () async {
                      String email = _emailController.text.trim();
                      String password = _passwordController.text.trim();

                      // Validate inputs
                      if (email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Please enter both email and password."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        final res = await auth.signIn(email, password);
                        if (res == 'Success') {
                          // Navigate to home using go_router
                          if (context.mounted) {
                            context.go('/home');
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Invalid email or password."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("An error occurred. Please try again."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Icon(Icons.login, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey, thickness: 1),
                const SizedBox(height: 12),
                buildSocialButton(
                  onPressed: () {}, // TODO: Implement Google sign-in logic
                  text: "Sign in with Google",
                  icon: Icons.g_translate,
                  color: Colors.white,
                  textColor: Colors.black,
                ),
                const SizedBox(height: 12),
                buildSocialButton(
                  onPressed: () {}, // TODO: Implement Facebook sign-in logic
                  text: "Sign in with Facebook",
                  icon: Icons.facebook,
                  color: Colors.blue,
                  textColor: Colors.white,
                ),
              ]),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.go('/register'),
              child: const Text(
                "Don't have an account? Register here.",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          ]))
        ]));
  }

  Widget buildSocialButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        minimumSize: const Size(double.infinity, 0),
      ),
      icon: Icon(icon),
      label: Text(text),
    );
  }
}
