import 'package:flutter/material.dart';

class ChatListPage extends StatelessWidget {
const ChatListPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF58f0d7),
        leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 20, // Adjust the radius as needed
              backgroundImage: NetworkImage('https://example.com/path/to/profile_picture.jpg'), // Replace with your image URL
            ),
          ),
        title: const Text('Username'),
      ),
      body: Center(
        child: Text('Chat List')
      )
    );
  }
}