import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:gotrue/src/types/user.dart' as gotrueUser;
class User {
  final String id;
  final String name;
  final String email;
  final int membersLimit;
  final int plansLimit;
  final String razorPayKey;
  User({required this.id, required this.name, required this.email, required this.membersLimit, required this.plansLimit, required this.razorPayKey});
  // Convert a User object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'membersLimit': membersLimit,
      'plansLimit': plansLimit,
      'razorPayKey': razorPayKey
    };
  }
  // Convert a Map object into a User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      membersLimit: json['membersLimit'],
      plansLimit: json['plansLimit'],
        razorPayKey: json['razorPayKey'],
    );
  }

 static Future<gymUser.User?> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString('user');

    if (userJson != null) {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      return gymUser.User.fromJson(userMap);
    }
    return null;
  }

  static Future<void> clearUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }
}

