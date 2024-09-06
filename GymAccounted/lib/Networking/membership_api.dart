import 'dart:async';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart';
import 'package:gymaccounted/Modal/membership_plan_dm.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MembershipService {
  final SupabaseClient supabaseClient;
  MembershipService(this.supabaseClient);

  static Future<void> updateMembershipStatus() async {
    final supabase = Supabase.instance.client;
    final user = await gymUser.User.getUser();
    final gymId = user?.id ?? "";

    // Check if gymId is empty
    if (gymId.isEmpty) {
      print('Error: gymId is null or empty');
      return;
    }

    // Fetch all memberships for the given gym_id
    final membershipsResponse =
        await supabase.from('Memberships').select().eq('gym_id', gymId);

    if (membershipsResponse == null) {
      print('Error fetching memberships: ${membershipsResponse}');
      return;
    }

    final memberships = membershipsResponse as List<dynamic>;

    // Fetch all plans for the given gym_id
    final plansResponse =
        await supabase.from('Plans').select().eq('gym_id', gymId);

    if (plansResponse == null) {
      print('Error fetching plans: ${plansResponse}');
      return;
    }

    final plans = plansResponse as List<dynamic>;

    // Update memberships
    for (final membership in memberships) {
      final plan = plans.firstWhere((p) => p['id'] == membership['plan_id']);
      final joiningDate = DateTime.parse(membership['joining_date']);
      final currentDate = DateTime.now();
      int planLimitMonths = plan['plan_limit'];

      if (currentDate.difference(joiningDate).inDays > (planLimitMonths * 30)) {
        // Update the status to 0
        final updateResponse = await supabase
            .from('Memberships')
            .update({'status': 0})
            .eq('id', membership['id'])
            .eq('gym_id', gymId);

        if (updateResponse == null) {
          print('Error updating membership status: ${updateResponse}');
        }
      }
    }
  }

  Future<Map<String, dynamic>> insetMembership({
    required String gymId,
    required int memberId,
    required int planId,
    required String joiningDate,
    required int status,
    required bool renew,
    required String expiredDate,
    required String discountedAmount
  }) async {
    try {
      final response = await supabaseClient.from('Memberships').insert({
        'gym_id': gymId,
        'member_id': memberId,
        'plan_id': planId,
        'joining_date': joiningDate,
        'status': status,
        'renew_plan': renew,
        'expired_date': expiredDate,
        'discounted_amount':discountedAmount
      }).select();
      // Debug print to inspect the response
      print('Response: $response');

      if (response.isEmpty) {
        return {'success': false, 'message': 'No data returned'};
      }
      return {'success': true, 'data': response};
    } catch (e) {
      print('Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateMembership({
    required String joiningDate,
    required int planId,
    required String expiredDate,
    required String memberId,
    required String discountedAmount


}) async {
    try {
      final response = await supabaseClient.from('Memberships').update({
        'joining_date': joiningDate,
        'plan_id': planId,
        'expired_date':expiredDate,
        'discounted_amount':discountedAmount
      }).eq('member_id', memberId).select();

      if (response != null) {
        return {'success': true, 'message': 'Membership updated successfully.'};
      } else {
        return {'success': false, 'message': 'Failed to update membership: ${response}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateMembershipTnxId({
    required int tnxId,
    required int memberId,
  }) async {
    try {
      final response = await supabaseClient.from('Memberships').update({
        'TnxId': tnxId.toString(),
      }).eq('member_id', memberId).select();

      if (response != null) {
        return {'success': true, 'data': response};
      } else {
        return {'success': false, 'message': 'Failed to update membership tnxId: ${response}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }


// Function to parse and compare dates
  DateTime parseDateString(String dateStr) {
    final dateFormat = DateFormat('dd-MMMM-yyyy'); // Adjust if needed
    return dateFormat.parse(dateStr);
  }

  Future<void> updateDueMemberships() async {
    final supabase = Supabase.instance.client;
    final user = await gymUser.User.getUser();
    final gymId = user?.id ?? "";

    try {
      // Fetch records where gym_id matches
      final response = await supabase
          .from('Memberships')
          .select('*')
          .eq('gym_id', gymId)
          .select();

      if (response == null) {
        print('Error fetching records');
        return;
      }

      final records = response as List<dynamic>;
      // Get the current date
      final now = DateTime.now();
      // Filter records in Dart and update renew_plan
      final renewPlanUpdates = records.where((record) {
        final joiningDateStr = record['created_at'] as String;
        final joiningDate = DateTime.parse(joiningDateStr);
        return joiningDate.isBefore(now);

      }).map((record) => record['id']).toList();

      if (renewPlanUpdates.isNotEmpty) {
        final updateRenewPlanResponse = await supabase
            .from('Memberships')
            .update({'status': 1})
            .eq('gym_id', gymId)
            .eq('status', 2)
            .filter('id', 'in', renewPlanUpdates)
            .select();

        if (updateRenewPlanResponse == null) {
          print('Error updating renew_plan:');
        } else {
          print('Successfully updated renew_plan.');
        }
      }

      // Filter records and update status
      final statusUpdateIds = records.where((record) {
        final expiredDateStr = record['expired_date'] as String;
        final expiredDate = parseDateString(expiredDateStr);
        return expiredDate.isBefore(now);
      }).map((record) => record['id']).toList();

      if (statusUpdateIds.isNotEmpty) {
        final updateStatusResponse = await supabase
            .from('Memberships')
            .update({'status': 0})
            .eq('gym_id', gymId)
            .filter('id', 'in', statusUpdateIds)
            .select();

        if (updateStatusResponse == null) {
          print('Error updating status:');
        } else {
          print('Successfully updated status.');
        }
      }
    } catch (e) {
      print('Unexpected error: $e');
    }
  }


  Future<Map<String, dynamic>> renewMembership({
    required String memberId,
    required String joiningDate,
    required String expiredDate,
    required String planId,
    required String discountedAmount,
  }) async {
    try {
      final user = await gymUser.User.getUser();
      final gymId = user?.id ?? "";

      final response = await supabaseClient.from('Memberships').update({
        'plan_id': planId,
        'joining_date': joiningDate,
        'expired_date': expiredDate,
        'discounted_amount':discountedAmount,
        'status': 2,
        'created_at': DateTime.now().toIso8601String()
      }).eq('member_id', memberId).eq('gym_id', gymId).select();

      if (response != null) {
        return {'success': true, 'message': 'Membership updated successfully.'};
      } else {
        return {'success': false, 'message': 'Failed to update membership: ${response}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }


  Future<void> deleteMembership(String id) async {
    final response =
        await supabaseClient.from('Memberships').delete().eq('id', id);
  }
}
