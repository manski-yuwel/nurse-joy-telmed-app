import 'package:flutter/material.dart';
import '../widgets/base_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({ super.key });

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingPage> {

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/signin'); // Move to Sign In
    });
  }

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
                Text("Please wait...",
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: 10),
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(100.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.white,
                    border: Border.all(width: 0, color: Colors.white),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: CircularProgressIndicator(color: Colors.red),
                )
              ]
            )
          )
        ]
      )
    );
  }
}

