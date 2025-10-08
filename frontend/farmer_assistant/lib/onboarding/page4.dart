import 'package:flutter/material.dart';


class OnboardingPage4 extends StatelessWidget{

  @override
  Widget build(BuildContext context){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/reward.png',height:30),
        SizedBox(height:20),
        Text(
          "Reward & Schemes",
          style: TextStyle(fontSize: 22,fontFamily: 'Roboto', fontWeight: FontWeight.bold,color:Colors.green),
          textAlign: TextAlign.center
        ),
        SizedBox(height: 10,),
        Text(
          "Get Benefits and Earn Points",
          style: TextStyle(fontSize: 10, color:Colors.grey),
          textAlign: TextAlign.center,
        )

      ],
    );
  }
}