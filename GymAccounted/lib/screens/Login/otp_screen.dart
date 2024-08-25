import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:gymaccounted/Networking/Apis.dart';
import 'package:gymaccounted/screens/home_screen.dart';
import 'package:gymaccounted/screens/adduser-screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  OtpScreen({required this.phoneNumber, required this.verificationId});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  TextEditingController _otpController = TextEditingController();
  int _secondsRemaining = 60;
  bool _enableResend = false;
  Timer? _timer;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late GymService _gymService;
  bool _isLoading = false;
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _gymService = GymService(Supabase.instance.client);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _enableResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _resendOtp() {
    setState(() {
      _secondsRemaining = 60;
      _enableResend = false;
    });
    _startTimer();
    _verifyPhoneNumber();
  }

  Future<void> _verifyPhoneNumber() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed. Please try again.')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
    });
    String otp = _otpController.text;
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: otp,
    );

    try {
      await _auth.signInWithCredential(credential);
      final user = _auth.currentUser;
      if (user != null) {
        // Get the user ID
        // Get user details
        String userId = user.uid;
        String userName = user.displayName ?? "";
        String userEmail = user.email ?? "";
        // Create a User object
        gymUser.User data = gymUser.User(id: userId, name: userName, email: userEmail, membersLimit: 0, plansLimit: 0,razorPayKey: '');
        // Save user details to shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data.toJson()));
        // Handle successful sign-in here
        // For example, navigate to a new page or show a success message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Signed in successfully!'),
        ));
        _fetchGymData();
      } else {
        // Handle the case where the user cancels the sign-in process
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sign in canceled.'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGymData() async {
    final response = await _gymService.getGym();
    setState(() {
      if (response == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddUserScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SIGN IN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            RichText(
              text: TextSpan(
                text: 'Enter the OTP sent to ',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                children: <TextSpan>[
                  TextSpan(
                    text: widget.phoneNumber,
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _otpController,
              onChanged: (value) {},
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(5),
                fieldHeight: 50,
                fieldWidth: 40,
                activeFillColor: Colors.white,
                selectedFillColor: Colors.grey[200],
                inactiveFillColor: Colors.grey[300],
              ),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: _enableResend ? _resendOtp : null,
              child: Text(
                _enableResend
                    ? 'Didn\'t receive the OTP? Resend OTP'
                    : 'Resend OTP in $_secondsRemaining seconds',
                style: TextStyle(
                  color: _enableResend ? Colors.indigo : Colors.grey,
                  fontWeight: _enableResend ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                onPressed: _verifyOtp,
                child: Text(
                  'Submit',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
