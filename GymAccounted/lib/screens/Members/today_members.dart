import 'package:flutter/material.dart';
import 'add_members.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/Modal/members_dm.dart';
import 'package:gymaccounted/Networking/members_api.dart';
import 'package:gymaccounted/screens/Members/member_detail.dart';
import 'dart:convert';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:gymaccounted/Networking/subscription_api.dart';

class TodayMembers extends StatefulWidget {
  final List<Map<String, dynamic>> todayMembers;
  final String memberType;// Member instance passed to the screen
  const TodayMembers({Key? key, required this.memberType,required this.todayMembers}) : super(key: key);

  @override
  _TodayMembersState createState() => _TodayMembersState();
}

class _TodayMembersState extends State<TodayMembers> {
  late MemberService memberService;
  late Future<List<Member>> members;
  String _searchQuery = '';
  bool userInitialized = false;
  late gymUser.User user;
  late SubscriptionApi _subscriptionApi;
  bool _subscription = false;
  late List<int> ids;
  late String memberType;

  @override
  void initState() {
    super.initState();
    memberService = MemberService(Supabase.instance.client);
    ids = getTodayMemberIds(widget.todayMembers);
     members = ids.isEmpty ? Future.value([]) : memberService.getMembersById(ids);
     memberType = widget.memberType;
    _subscriptionApi = SubscriptionApi(Supabase.instance.client);
    _fetchSubscription();
    _initializeUser();
  }

  List<int> getTodayMemberIds(List<Map<String, dynamic>> todayMembers) {
    // Extract the ids by mapping over the list
    return todayMembers.map((member) => member['member_id'] as int).toList();
  }
  Future<void> _initializeUser() async {
    user = (await gymUser.User.getUser()) ?? gymUser.User(id: '', name: '', email: '', membersLimit: 0, plansLimit: 0, razorPayKey: '');
    setState(() {
      userInitialized = true;
    });
  }

  Future<void> _fetchSubscription() async {
    try {
      final response = await _subscriptionApi.getActiveSubscription();
      setState(() {
        if (response["success"] == true) {
          _subscription = true;
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching plans: $error')),
      );
    }
  }

  Future<void> _deleteMember(Member member) async {
    await memberService.deleteMember(member.id);
    setState(() {
      members = memberService.getMembersById(ids);
    });
  }

  Future<void> _showMemberOptions(Member member) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.visibility),
                title: Text('View Member'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MemberDetailScreen(member: member),
                    ),
                  ).then((_) {
                    setState(() {
                      members = memberService.getMembersById(ids);
                    });
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Member'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMembers(member: member),
                    ),
                  ).then((_) {
                    setState(() {
                      members = memberService.getMembersById(ids);
                    });
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.update),
                title: Text('Delete Member'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMember(member.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteMember(int memberId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this member?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await memberService.deleteMember(memberId);
                  setState(() {
                    members = memberService.getMembersById(ids);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Member deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting member: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Image imageFromBase64String(String base64String) {
    final bytes = base64Decode(base64String);
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: Text(
          memberType,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search members...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Member>>(
              future: members,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No members found'));
                }

                var filteredMembers = snapshot.data!
                    .where((member) => member.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

                if (filteredMembers.isEmpty) {
                  return Center(child: Text('No members found'));
                }
                return ListView.separated(
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    return Container(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 5,
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: member.image != null
                                ? imageFromBase64String(member.image!).image
                                : null,
                          ),
                          title: Text(member.name),
                          subtitle: Text("Expired at: ${member.expiredAt}",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                            decoration: BoxDecoration(
                              color: member.status == 2
                                  ? Colors.deepPurple
                                  : member.status == 1
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              member.status == 2 ? "Renewed" : member.status == 1 ? "Active" : "Due",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          onTap: () {
                            _showMemberOptions(member);
                          },
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => Divider(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
