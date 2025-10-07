import 'package:flutter/material.dart';


class OnboardingPage2 extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/dhara.png',height: 30,),
        SizedBox(height: 20,),
        Text(
          "AI Assistant Dhara",
          style: TextStyle(fontSize: 22,fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10,),
        Text(
          "Talk in malayam to get daily tasks , feedback & tips.",
          style: TextStyle(fontSize: 16,color: Colors.grey),
          textAlign: TextAlign.center,
        )


      ],
    );
  }
}