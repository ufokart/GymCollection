import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gymaccounted/Networking/Apis.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/screens/Login/loginscreen.dart';
import 'package:gymaccounted/screens/adduser-screen.dart';
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      Duration(seconds: 3),
      () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.calculate_rounded,
              size: 200,
            ),
          ),
        ],
      ),
    );
  }
}
