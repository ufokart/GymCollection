import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:gymaccounted/Modal/plan_dm.dart';
import 'package:gymaccounted/Networking/plans_api.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gotrue/src/types/user.dart' as gotrueUser;
class UserApiService {
  final SupabaseClient supabaseClient;

  UserApiService(this.supabaseClient);

  Future<void> getData() async {
    try {
      final response = await supabaseClient.from('AppUserPreference').select().single();
      final user      = await gymUser.User.getUser();
      final gymId     = user?.id ?? "";
      final userName  = user?.name ?? "";
      final userEmail = user?.email ?? "";
      final planLimit =  response['plans_limit'];
      final memberLimit = response['members_limit'];
      final razorPayKey = response['razor_pay_key'];
      gymUser.User data =
      gymUser.User(id: gymId, name: userName, email: userEmail,membersLimit: memberLimit, plansLimit: planLimit,razorPayKey: razorPayKey);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(data.toJson()));
    } catch (e) {
      //return {'success': false, 'message': 'Error: $e'};
    }
  }
}