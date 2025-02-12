import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF58f0d7),
          title: Text('Nurse Joy'),
        ),
        body: Center(
          child: Text('Loading...'),
        ),
      ),
    );
  }
}