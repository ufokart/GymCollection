import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:gymaccounted/Modal/plan_dm.dart';
import 'package:gymaccounted/Networking/plans_api.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;

class PlanService {
  final SupabaseClient supabaseClient;
  PlanService(this.supabaseClient);

  Future<Map<String, dynamic>> insertPlan({
    required String name,
    required String price,
    required int limit,
    required String gymId,
  }) async {
    try {
      final response = await supabaseClient.from('Plans').insert({
        'plan_name': name,
        'plan_price': price,
        'plan_limit': limit,
        'gym_id': gymId
      });
      // Debug print to inspect the response
      print('Response: $response');
      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<List<Plan>> getPlans() async {
    final user = await gymUser.User.getUser();
    final gymId = user?.id ?? "";
    final response =
        await supabaseClient.from('Plans').select().eq('gym_id', gymId);
    final data = response as List<dynamic>;
    return data.map((json) => Plan.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> updatePlan(int id, Plan plan) async {
    final response = await supabaseClient
        .from('Plans')
        .update({
          'plan_name': plan.planName,
          'plan_price': plan.planPrice,
          'plan_limit': plan.planLimit
        })
        .eq('id', id)
        .select();
    if (response == null)
      return {'success': false, 'data': response};
    else
      return {'success': true, 'data': response};
  }

  Future<Map<String, dynamic>> deletePlan(int id) async {
    try {
      final response = await supabaseClient.from('Plans').delete().eq('id', id).select();

      if (response == null) {
        // Handle error from Supabase
        return {'success': false, 'message': response};
      }

      // Check if the delete operation was successful
      if (response != null) {
        return {'success': true, 'message': 'Plan deleted successfully.'};
      } else {
        return {'success': false, 'message': 'No plan found with the given ID.'};
      }
    } catch (e) {
      // Handle any other errors
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
