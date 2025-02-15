import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SizedBox(height: 20),

            // Feeling Sick Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.green[700],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "Feeling Sick?",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Center(
                            child: Text(
                              "Tell us your illness, symptoms, or what you’re feeling, and we’ll get you a doctor fast.",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Recent Prescriptions Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.green[500],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [

                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Recent Prescriptions",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      leading: CircleAvatar(
                        child: const Text("JD"),
                      ),
                      title: Text("Monthly Diet",
                        style: TextStyle (
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20
                        )
                      ),
                      subtitle: Text("Jane Doe",
                        style: TextStyle(
                          color: Colors.white70,

                        )
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        // TODO: Navigate to Prescription Details
                      },
                    ),
                    Divider(
                      color: Colors.white,
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        child: const Text("JC"),
                      ),
                      title: Text("Daily Heart Maintenance",
                          style: TextStyle (
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20
                          )
                      ),
                      subtitle: Text("Dr. Jake Cruz",
                          style: TextStyle(
                            color: Colors.white70,
                          )
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white,),
                      onTap: () {
                        // TODO: Navigate to Prescription Details
                      },
                    ),
                    Divider(
                      color: Colors.white,
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        child: const Text("M"),
                      ),
                      title: Text("Cold Prescription",
                          style: TextStyle (
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20
                          )
                      ),
                      subtitle: Text("Dr. Morrie",
                          style: TextStyle(
                            color: Colors.white70,
                          )
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        // TODO: Navigate to Prescription Details
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.green[400],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [

                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Activity",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      leading: Icon(Icons.message, color: Colors.white, size: 32),
                      title: Text("Dr. Garreth messaged you",
                            style: TextStyle (
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18
                            )
                        ),

                      subtitle: Text("Jan 29: 02:04",
                          style: TextStyle(
                            color: Colors.white70,

                          )
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        // TODO: Navigate to Prescription Details
                      },
                    ),
                    Divider(
                      color: Colors.white,
                    ),
                    ListTile(
                      leading: Icon(Icons.star, color: Colors.white, size: 32),
                      title: Text("New Prescription",
                          style: TextStyle (
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20
                          )
                      ),
                      subtitle: Text("Feb 14: 04:03",
                          style: TextStyle(
                            color: Colors.white70,
                          )
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        // TODO: Navigate to Prescription Details
                      },
                    ),
                    Divider(
                      color: Colors.white,
                    ),
                    ListTile(
                      leading: Icon(Icons.alarm, color: Colors.white, size: 32),
                      title: Text("Medication Intake Reminder",
                          style: TextStyle (
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20
                          )
                      ),
                      subtitle: Text("Feb 16: 12:13",
                          style: TextStyle(
                            color: Colors.white70,
                          )
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        // TODO: Navigate to Prescription Details
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
