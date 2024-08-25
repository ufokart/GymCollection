import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gymaccounted/screens/Dashboard/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/Networking/Apis.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:gotrue/src/types/user.dart' as gotrueUser;
import 'package:gymaccounted/screens/home_screen.dart';
import 'package:gymaccounted/screens/Login/PhoneAuthScreen.dart';
import 'package:gymaccounted/screens/adduser-screen.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  gymUser.User? _user; // Use the User class from gymaccounted package
  late GymService _gymService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gymService = GymService(Supabase.instance.client);
    _loadUserData();
  }
  Future<void> _loadUserData() async {
    try {
      final gymUser.User? user = await getUser();
      if (mounted) {
        setState(() {
          _user = user;
          if (_user != null) {
            _fetchGymData();
          }
        });
      }
    } catch (e) {
      // Handle errors here, e.g., log them or show a message to the user
      print('Failed to load user data: $e');
    }
  }

  Future<gymUser.User?> getUser() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('user');

      if (userJson != null) {
        final Map<String, dynamic> userMap = jsonDecode(userJson);
        return gymUser.User.fromJson(userMap);

      }
    } catch (e) {
      // Handle errors here, e.g., log them or show a message to the user
      print('Failed to get user from SharedPreferences: $e');
      return null;
    }
  }

  Future<void> _fetchGymData() async {
    setState(() {
      _isLoading = true;
    });
    final response = await _gymService.getGym();
    setState(() {
      _isLoading = false;
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

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      GoogleSignInAccount? user = await _googleSignIn.signIn();
      if (user != null) {
        // Get the user ID
        // Get user details
        String userId = user.id;
        String userName = user.displayName ?? '';
        String userEmail = user.email;
        // Create a User object
        gymUser.User data =
        gymUser.User(id: userId, name: userName, email: userEmail,plansLimit: 0,membersLimit: 0,razorPayKey: '');
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
    } catch (error) {
      print('Error signing in: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error signing in. Please try again.'),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Image.asset(
          //   'assets/gym_background.jpg', // Add a suitable background image in your assets folder
          //   fit: BoxFit.cover,
          // ),
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
            child: _isLoading
                ? CircularProgressIndicator()
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'GYM COLLECTION',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(5.0, 5.0),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50.0),
                Icon(
                  Icons.fitness_center,
                  size: 200,
                  color: Colors.white.withOpacity(0.8),
                ),
                SizedBox(height: 80.0),
                // ElevatedButton(
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.redAccent,
                //     // Background color
                //     foregroundColor: Colors.white,
                //     // Text and icon color
                //     shadowColor: Colors.black,
                //     elevation: 10.0,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(30.0),
                //     ),
                //     padding:
                //     EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
                //     textStyle:
                //     TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                //   ),
                //   onPressed: _handleSignIn,
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: <Widget>[
                //       Icon(Icons.login, color: Colors.white),
                //       SizedBox(width: 10.0),
                //       Text('Sign in with Google'),
                //     ],
                //   ),
                // ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    // Background color
                    foregroundColor: Colors.white,
                    // Text and icon color
                    shadowColor: Colors.black,
                    elevation: 10.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding:
                    EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
                    textStyle:
                    TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => PhoneAuthScreen()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.phone, color: Colors.white),
                      SizedBox(width: 10.0),
                      Text('Sign in with Phone'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
