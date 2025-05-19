import 'package:flutter/material.dart';
import '../widgets/base_page.dart';
import '../../../../auth/provider/auth_service.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _verificationCodeController.dispose();
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
            child: Column(
              children: [
                Text("Sign-Up", style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 10),
                Container(
                  // Sign-Up Form Container
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.white,
                    border: Border.all(width: 0, color: Colors.white),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: Column(
                    children: [
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Send verification code logic
                            String email = _emailController.text.trim();
                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Please enter your email."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          },
                          child: Text(
                            "Send verification code",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
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
                      SizedBox(height: 30),
                      TextField(
                        controller: _verificationCodeController,
                        obscureText: false,
                        decoration: InputDecoration(
                          hintText: "Verification Code",
                          prefixIcon: Icon(Icons.check, color: Colors.blue),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            String email = _emailController.text.trim();
                            String password = _passwordController.text.trim();
                            String code =
                                _verificationCodeController.text.trim();

                            // Input Validation
                            if (email.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Please fill all fields."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            try {
                              final res =
                                  await auth.signUp(email, password);
                              if (res == 'Success') {
                                // Navigate to home or dashboard
                                Navigator.pushNamed(context, '/home');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text("Registration failed. Try again."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "An error occurred. Please try again."),
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
                      SizedBox(height: 12),
                      Divider(color: Colors.grey, thickness: 1),
                      SizedBox(height: 12),
                      buildSocialButton(
                        onPressed:
                            () {}, // TODO: Implement Google sign-up logic
                        text: "Sign up with Google",
                        icon: Icons.g_translate,
                        color: Colors.white,
                        textColor: Colors.black,
                      ),
                      SizedBox(height: 12),
                      buildSocialButton(
                        onPressed:
                            () {}, // TODO: Implement Facebook sign-up logic
                        text: "Sign up with Facebook",
                        icon: Icons.facebook,
                        color: Colors.blue,
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/signin'),
                  child: Text(
                    "Already have an account? Sign in here.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
