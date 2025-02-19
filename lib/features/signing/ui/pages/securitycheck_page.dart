import 'package:flutter/material.dart';
import '../widgets/base_page.dart';

class SecuritycheckPage extends StatelessWidget {
  const SecuritycheckPage({ super.key });

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
                Text("Security Check", style: Theme.of(context).textTheme.titleLarge),
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
                      Align(
                          alignment: Alignment.centerLeft,
                        child:Text(
                          "We want to make sure it's you.\nEnter the verification code sent to\nd...@gmail.com", // TODO: Implement dynamic email obfuscation and display
                        )
                      ),
                      SizedBox(height: 20),

                      buildTextField( // Email field
                          hintText: "Verification Code",
                          icon: Icons.mail
                      ),
                      TextButton(
                        onPressed: () {}, // TODO: send verification code logic
                        child: Text(
                          "Code Not Received? Click to resend",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          )
                        )
                      ),

                      SizedBox(height: 20),
                      Align( // Login/Proceed button
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/home'), // TODO: Implement sign-up logic
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