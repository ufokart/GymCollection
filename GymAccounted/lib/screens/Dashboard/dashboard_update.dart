import 'package:flutter/material.dart';
import 'package:gymaccounted/Networking/Apis.dart'; // Ensure GymService is implemented here
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/Modal/members_dm.dart';
import 'package:gymaccounted/Networking/members_api.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:gymaccounted/screens/Members/member_detail.dart';

class ExpiringMembersList extends StatefulWidget {
  final GymService gymService;

  const ExpiringMembersList({Key? key, required this.gymService}) : super(key: key);

  @override
  _ExpiringMembersListState createState() => _ExpiringMembersListState();
}

class _ExpiringMembersListState extends State<ExpiringMembersList> {
  late Future<List<Member>> expiringMembers;
  late MemberService memberService;

  @override
  void initState() {
    super.initState();
    memberService = MemberService(Supabase.instance.client);
    expiringMembers = fetchExpiringMembers();
  }

  Future<List<Member>> fetchExpiringMembers() async {
    try {
      List<Member> allMembers = await memberService.getMembers();
      DateTime now = DateTime.now();

      // Define the date format
      final dateFormatter = DateFormat('d-MMMM-yyyy');

      // Define time frames in days
      List<int> timeFrames = [1, 2, 3]; // 1 day, 2 days, 3 days

      // Filter members who expire within the defined time frames
      List<Member> expiringSoon = allMembers.where((member) {
        try {
          DateTime expireDate = dateFormatter.parse(member.expiredAt);

          // Check if the date is within the defined time frames
          return timeFrames.any((days) {
            final endDate = now.add(Duration(days: days));
            return expireDate.isAfter(now) && expireDate.isBefore(endDate);
          });
        } catch (e) {
          print('Invalid date format for member ${member.name}: ${member.expiredAt}');
          return false;
        }
      }).toList();

      return expiringSoon;
    } catch (e) {
      print('Error fetching expiring members: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Member>>(
      future: expiringMembers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox.shrink();
        } else {
          final members = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Members Expiring Soon',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    title: Text(member.name),
                    subtitle: Text(
                      'Expires on: ${member.expiredAt}',
                      style: TextStyle(color: Colors.red),
                    ),
                    leading: Icon(Icons.warning, color: Colors.red),
                    onTap: () {
                      _showMemberOptions(member);
                    },
                  );
                },
              ),
            ],
          );
        }
      },
    );
  }

  Future<void> _showMemberOptions(Member member) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberDetailScreen(member: member),
      ),
    );
  }
}
