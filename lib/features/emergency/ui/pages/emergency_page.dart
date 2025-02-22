import 'package:flutter/material.dart';
import '../../../../main.dart';


class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  //Colors
  static const color1 = Color(0xffB3261E);
  static const color2 = Color(0xffFF7C7C);
  static const color3 = Color(0xffFFE1E2);
  static const color4 = Color(0xffA02040);




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color1,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back)
        ),
        title: Text(
          'Emergency Mode',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(1, 1),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [

            // AI Assistant Card
            displayCard(
              color: color2,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xffB3261E),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 43,
                        height: 43,
                        child: buildCircleImage('assets/img/nursejoy.jpg', 0, 1.5),
                      ),
                      SizedBox(width: 20),
                      Text(
                        'How can I help?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: color3,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.mic, color: color4),
                      SizedBox(width: 8),

                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: '...',
                            hintStyle: TextStyle(color: color1),
                          ),
                        )
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: color4),
                        onPressed: () {} //TODO: Add send functionality,
                      ),
                    ]
                  )
                ),
              ]
            ),

            // Map Card
            displayCard(
              color: color2,
              children: [
                Text(
                  'Nearest Hospital',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold
                  )
                ),
                Text(
                  'Insert Map Here' //TODO: Add map stuff
                )
              ]
            )
          ],
        ),
      ),
    );
  }
}

Widget displayCard({required List<Widget> children, required Color color}) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15)
    ),
    color: color,
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children
            )
          )
        ]
      )
    )
  );
}