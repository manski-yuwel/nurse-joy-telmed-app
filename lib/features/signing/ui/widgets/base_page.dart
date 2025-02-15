import 'package:flutter/material.dart';

class BasePage extends StatelessWidget {
  final Widget child;
  final String imagePath;

  const BasePage({
    super.key,
    required this.child,
    this.imagePath = 'assets/img/nursejoy.jpg',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF58f0d7),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top half: Image
              Text('N U R S E  J O Y', style: Theme.of(context).textTheme.titleLarge),
              Container(width: 240, height: 240,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.fill,
                  ),
                  border: Border.all(width: 0),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: Offset(0, 5),
                    )
                  ]
                )
              ),
              // Bottom half: displays the passed child
              Padding(
                padding: EdgeInsets.all(16.0),
                child: child,
              )
            ]
          )
        )
      ))
    );
  }
}

// Custom Text Field Builder
Widget buildTextField({
  required String hintText,
  required IconData icon,
  bool isPassword = false
}) {
  return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.blue),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          )
      )
  );
}

// Custom Social Button Builder
Widget buildSocialButton({
  required String text,
  required IconData icon,
  required Color color,
  required Color textColor,
  required VoidCallback onPressed
}) {
  return ElevatedButton.icon(
    onPressed: onPressed, // TODO: Add social login functionality
    icon: Icon(icon, color: textColor),
    label: Text(text, style: TextStyle(color: textColor)),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      minimumSize: Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
  );
}