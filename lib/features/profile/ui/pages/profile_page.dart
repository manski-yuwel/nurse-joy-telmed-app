import 'package:flutter/material.dart';


class ProfilePage extends StatelessWidget {
const ProfilePage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF58f0d7),
        title: const Text('Profile Page'),
      ),
      body: Center(
        child: Text('Profile')
      )
    );
  }
}