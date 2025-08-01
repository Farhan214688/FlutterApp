import 'package:firstt_project/StartingPage2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StartingPage extends StatelessWidget {
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

                    Text('Welcome ', style: TextStyle(
                      fontSize:25,
                      fontWeight: FontWeight.bold,

                    ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Container(
                          child: Image.asset('Assets/Images/Logo1.png'),
                          height: 135,
                          width: 135,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),

                    Text('RAPIT', style: TextStyle
                      (
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      //color: Colors.white,
                    ),),
                    Text('Repair and Maintenance Services', style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    )),
                    Text('for Home', style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),),
                    Row(
                      children: [
                        SizedBox(
                          width: 40,
                        ),
                        Center(
                          child: Container(
                            width: 280,
                            height: 280,



                            child: Image.asset('Assets/Images/Start1.png'),
                          ),
                        ),

                      ],
                    ),
                    Text('Get your work done from home', style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),



                    SizedBox(
                      height: 20,
                    ),

                    Container(
                      width: 250,
                      child: ElevatedButton(onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StartingPage2()),
                        );

                      },child: Text('Next', style: TextStyle(
                        fontSize: 18,
                        color: Colors.greenAccent,

                      ),),
                      ),
                    )
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