import 'package:flutter/material.dart';


class OnboardingPage1 extends StatelessWidget{

  @override
  Widget build(BuildContext context){
    return  Column(
      mainAxisAlignment: MainAxisAlignment.center,  
      children: [
        Image.asset('assets/images/ico.jpg',height: 250),
        SizedBox(height: 20),
        Text(
          "Personalized Farming Roadmap",
          style: TextStyle(fontSize: 22,fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          "Guidance tailored to your land and crop.",
          style: TextStyle(fontSize: 16,color: Colors.grey),
          textAlign: TextAlign.center,
        ),

      ],
    );
  }
}