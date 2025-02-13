import 'package:flutter/material.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF58f0d7),
        leading: buildCircleImage('assets/img/nursejoy.jpg', 1.5),
        title: const Text('Username'),
      ),
      body: Center(
        child: Text('Chat List'),
      ),
    );
  }
}

  // Function to create image widget with the cropped image
  Widget buildCircleImage(String imagePath, double scale) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: ClipOval(
        child: Transform.scale(
          scale: scale, // Adjust the scale to zoom in
          alignment: Alignment.topCenter,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover, // Ensure the image covers the entire area
          ),
        ),
      ),
    );
  }
