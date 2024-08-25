import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase/supabase.dart';
import 'package:gymaccounted/Modal/membership_plan_dm.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;

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
  }) async {
    try {
      final response = await supabaseClient.from('Memberships').insert({
        'gym_id': gymId,
        'member_id': memberId,
        'plan_id': planId,
        'joining_date': joiningDate,
        'status': status,
        'renew_plan': renew,
        'expired_date': expiredDate
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
  }) async {
    try {
      final response = await supabaseClient.from('Memberships').update({
        'joining_date': joiningDate,
        'plan_id': planId,
        'expired_date':expiredDate,
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

  Future<Map<String, dynamic>> renewMembership({
    required String memberId,
  }) async {
    try {
      final user = await gymUser.User.getUser();
      final gymId = user?.id ?? "";

      final response = await supabaseClient.from('Memberships').update({
        'renew_plan': 1,
        'status': 1,
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
