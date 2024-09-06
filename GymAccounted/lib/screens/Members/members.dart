import 'package:flutter/material.dart';
import 'add_members.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/Modal/members_dm.dart';
import 'package:gymaccounted/Networking/members_api.dart';
import 'package:gymaccounted/screens/Members/member_detail.dart';
import 'dart:convert';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:gymaccounted/Networking/subscription_api.dart';
class Members extends StatefulWidget {
  final String memberType; // Member instance passed to the screen
  const Members({Key? key, required this.memberType}) : super(key: key);

  @override
  _MembersState createState() => _MembersState();
}

class _MembersState extends State<Members> {
  late MemberService memberService;
  late Future<List<Member>> members;
  String _searchQuery = '';
  String _filterStatus = 'all';
  bool _showFilters = true;
  late gymUser.User user;
  bool userInitialized = false; // Tra
  late SubscriptionApi _subscriptionApi;
  bool _subscription = false;
  @override
  void initState() {
    super.initState();
    _filterStatus = widget.memberType;
    memberService = MemberService(Supabase.instance.client);
    members = memberService.getMembers();
    _subscriptionApi = SubscriptionApi(Supabase.instance.client);
    _fetchSubscription();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    user = (await gymUser.User.getUser()) ?? gymUser.User(id: '', name: '', email: '', membersLimit: 0, plansLimit: 0,razorPayKey: '');
    setState(() {
      userInitialized = true; // User data is now initialized
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
      members = memberService.getMembers(); // Refresh the member list
    });
  }

  Future<void> _showMemberOptions(Member member) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the bottom sheet to take full height if needed
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(bottom: 16.0), // Add padding at the bottom
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
                      members = memberService.getMembers(); // Refresh the member list
                    });
                  });
                  // Navigate to view member screen
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
                      members = memberService.getMembers(); // Refresh the member list
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
              // Show Renew Membership option only if status is not active (assuming status 0 means inactive)
              // if (member.status != 1) // Change this condition based on your status logic
              //   ListTile(
              //     leading: Icon(Icons.refresh),
              //     title: Text('Renew Membership'),
              //     onTap: () {
              //       Navigator.pop(context);
              //       // Navigate to renew membership screen
              //     },
              //   ),
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
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                try {
                  await memberService.deleteMember(memberId); // Call your delete method
                  setState(() {
                    members = memberService.getMembers(); // Refresh the member list after deletion
                  });
                  // Optionally, show a success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Member deleted successfully')),
                  );
                } catch (e) {
                  // Handle any errors that occur during deletion
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
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilterChip(
                    label: Text('All'),
                    selected: _filterStatus == 'all',
                    onSelected: (bool selected) {
                      setState(() {
                        _filterStatus = 'all';
                      });
                    },
                  ),
                  FilterChip(
                    label: Text('Active'),
                    selected: _filterStatus == 'active',
                    onSelected: (bool selected) {
                      setState(() {
                        _filterStatus = 'active';
                      });
                    },
                  ),
                  FilterChip(
                    label: Text('Due'),
                    selected: _filterStatus == 'due',
                    onSelected: (bool selected) {
                      setState(() {
                        _filterStatus = 'due';
                      });
                    },
                  ),
                  FilterChip(
                    label: Text('Renewed'),
                    selected: _filterStatus == 'renewed',
                    onSelected: (bool selected) {
                      setState(() {
                        _filterStatus = 'renewed';
                      });
                    },
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
                    .where((member) =>
                        member.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) &&
                        (_filterStatus == 'all' ||
                            (_filterStatus == 'active' && member.status == 1) ||
                            (_filterStatus == 'due' && member.status == 0) ||
                            (_filterStatus == 'renewed' &&
                                member.status == 2)))
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
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: member.image != null
                                ? imageFromBase64String(member.image!).image
                                : null, // Use default if Base64 is null
                          ),
                          title: Text(member.name),
                          subtitle: Text("Expired at: ${member.expiredAt}",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 2, horizontal: 8),
                            decoration: BoxDecoration(
                              color: member.status == 2
                                  ? Colors.deepPurple
                                  : member.status == 1
                                      ? Colors.green
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              member.status == 2
                                  ? "Renewed"
                                  : member.status == 1
                                      ? "Active"
                                      : "Due", // Changed to show member status
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
      floatingActionButton: FutureBuilder<List<Member>>(
        future: members,
        builder: (context, snapshot) {
          if (!userInitialized || !snapshot.hasData) {
            return SizedBox.shrink(); // Return an empty widget if user data or plans are not yet available
          }

          final membersList = snapshot.data!;
          return (_subscription == true || user.membersLimit > membersList.length)
              ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddMembers()),
              ).then((_) {
                setState(() {
                  members = memberService.getMembers(); // Refresh the member list
                });
              });
            },
            tooltip: 'Add',
            child: Icon(Icons.add),
          )
              : SizedBox.shrink(); // Return an empty widget if the button should not be displayed
        },
      ),
    );
  }
}
