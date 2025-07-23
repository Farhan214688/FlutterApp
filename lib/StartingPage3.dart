import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firstt_project/LoginPage.dart';
import 'package:firstt_project/DashBoard.dart';

class StartingPage3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: SafeArea(
        child: Container(
          color: Colors.white60,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(bottom: 50),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome ',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,

                      ),
                    ),
                    SizedBox(height: 20),
                    Image.asset('Assets/Images/Logo1.png', height: 135, width: 135),
                    SizedBox(height: 10),
                    Text('RAPIT',
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold)),
                    Text('Repair and Maintenance Services',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    Text('for Home', style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        SizedBox(width: 65),
                        Container(
                            width: 280,
                            height: 280,
                            child: Image.asset('Assets/Images/Start3.png')
                        ),
                      ],
                    ),
                    Text("Let's Get Started!",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Container(
                      width: 250,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Mark that user has completed onboarding
                          var sharedPref = await SharedPreferences.getInstance();
                          await sharedPref.setBool('isFirstTime', false);
                          
                          // Navigate to Dashboard instead of login page
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Dashboard()),
                          );
                        },
                        child: Text(
                          'Start',
                          style: TextStyle(fontSize: 18, color: Colors.greenAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}