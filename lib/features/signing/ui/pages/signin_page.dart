import 'package:flutter/material.dart';
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
          SizedBox(height: 10),
          Center(
              child: Column(children: [
            Text("Sign-In", style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 10),
            Container(
              // Sign-In Form Container
              alignment: Alignment.center,
              padding: EdgeInsets.all(20.0),
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
                    prefixIcon: Icon(Icons.mail, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    prefixIcon: Icon(Icons.lock, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {}, // TODO: Forgot password logic
                    child: Text(
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
                          SnackBar(
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
                          // Navigate to home or dashboard
                          Navigator.pushNamed(context, '/home');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Invalid email or password."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text("An error occurred. Please try again."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Icon(Icons.login, color: Colors.white),
                  ),
                ),
                SizedBox(height: 16),
                Divider(color: Colors.grey, thickness: 1),
                SizedBox(height: 12),
                buildSocialButton(
                  onPressed: () {}, // TODO: Implement Google sign-in logic
                  text: "Sign in with Google",
                  icon: Icons.g_translate,
                  color: Colors.white,
                  textColor: Colors.black,
                ),
                SizedBox(height: 12),
                buildSocialButton(
                  onPressed: () {}, // TODO: Implement Facebook sign-in logic
                  text: "Sign in with Facebook",
                  icon: Icons.facebook,
                  color: Colors.blue,
                  textColor: Colors.white,
                ),
              ]),
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/register'),
              child: Text(
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
}
