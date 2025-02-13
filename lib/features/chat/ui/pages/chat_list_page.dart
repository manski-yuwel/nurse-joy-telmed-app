import 'package:flutter/material.dart';

class ChatListPage extends StatelessWidget {
const ChatListPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat List'),
      ),
      body: Center(
        child: Text('Chat List')
      )
    );
  }
}