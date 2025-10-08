import 'package:flutter/material.dart';


class OnboardingPage3 extends StatelessWidget{
  
  @override
  Widget build(BuildContext context){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/alert.png',height: 30),
        SizedBox(height: 20),
        Text(
          "Alert & Insights",
          style: TextStyle(fontSize: 22 , fontWeight: FontWeight.bold, color:Colors.grey),
          textAlign: TextAlign.center,
        ),
        SizedBox(height:10),
        Text(
          "Weather,pests & Market Tips",
          style : TextStyle(fontSize:10,color: const Color.fromARGB(255, 133, 86, 86)),
          textAlign: TextAlign.center,
        )
      ]
    );
  }
}