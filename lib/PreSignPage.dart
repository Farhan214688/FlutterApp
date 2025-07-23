import 'package:firstt_project/CustomerSign.dart';
import 'package:firstt_project/SignUpPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class PreSignPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RAPIT'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              SizedBox(
                height: 30,
              ),

              Center(
                child: Text('I want to use RAPIT app as a ?', style: TextStyle(
                  fontSize: 25,

                ),),
              ),
              SizedBox(
                height: 50,
              ),
              Container(
                height: 150,
                width: 200,
                decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      width: 2,
                    )
                ),
                child: TextButton(
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerSign()),
                    );
                  }, 
                  child: Text(
                    'Customer', 
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              SizedBox(
                height: 50,
              ),
              Container(
                height: 150,
                width: 200,
                decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      width: 2,
                    )
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignUpPage()
                      ),
                    );
                  },
                  child: Text(
                    'Professional',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

}