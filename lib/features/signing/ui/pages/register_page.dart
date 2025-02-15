import 'package:flutter/material.dart';
import '../widgets/base_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({ super.key });

  @override
  Widget build(BuildContext context){
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
                Container( // Sign-In Form Container
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
                      buildTextField( // Email field
                        hintText: "Email Address",
                        icon: Icons.mail
                      ),

                      Align( // Forgot password
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {}, // TODO: send verification code logic
                          child: Text(
                            "Send verification code",
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                            )
                          )
                        )
                      ),


                      SizedBox(height: 20),
                      buildTextField( // Password field
                        hintText: "Password",
                        icon: Icons.lock,
                        isPassword: true,
                      ),

                      SizedBox(height: 30),
                      buildTextField( // Verification Code field
                        hintText: "Verification Code",
                        icon: Icons.check,
                        isPassword: true,
                      ),

                      SizedBox(height: 12),
                      Align( // Login/Proceed button
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/homescreen'), // TODO: Implement sign-up logic
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12)
                          ),
                          child: Icon(Icons.login, color: Colors.white),
                        )
                      ),


                      SizedBox(height: 12),
                      Divider(color: Colors.grey, thickness: 1),
                      SizedBox(height: 12),

                      buildSocialButton( // Google Sign-up
                        onPressed: () {}, // TODO: Implement Google sign-up logic
                        text: "Sign up with Google",
                        icon: Icons.g_translate, // TODO: Replace with Google icon at assets/img
                        color: Colors.white,
                        textColor: Colors.black,
                      ),
                      SizedBox(height: 12),
                      buildSocialButton( // Facebook Sign-up
                        onPressed: () {}, // TODO: Implement Facebook sign-up logic
                        text: "Sign up with Facebook",
                        icon: Icons.facebook,
                        color: Colors.blue,
                        textColor: Colors.white
                      ),
                    ]
                  ),
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
                    )
                  )
                )
              ]
            )
          )
        ]
      )
    );
  }
}