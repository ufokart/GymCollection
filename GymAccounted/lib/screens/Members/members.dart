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
  final ScrollController _scrollController = ScrollController();
  late MemberService memberService;
//  late Future<List<Member>> members;
  List<Member> _members = [];
  final TextEditingController _searchController = TextEditingController();

  int _page = 0;
  final int _limit = 20;
  bool _isLoading = false;
  bool _hasMore = true;

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
    _subscriptionApi = SubscriptionApi(Supabase.instance.client);

    _initializeUser().then((_) {
      _fetchMembers(); // ✅ fetch after user initialized
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchMembers();
      }
    });

    _fetchSubscription();
  }
  Future<void> _fetchMembers() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    final newMembers = await memberService.getMembers(
      page: _page,
      limit: _limit,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      status: _filterStatus != 'all' ? _filterStatus : null, // pass only if not "all"
    );
    setState(() {
      if (_page == 0) {
        _members = newMembers;
      } else {
        _members.addAll(newMembers);
      }

      if (newMembers.length < _limit) {
        _hasMore = false;
      } else {
        _page++; // ✅ increment page only if more records might exist
      }

      _isLoading = false;
    });
  }


  List<Member> _applyFilters() {
    return _members.where((member) {
      final matchesSearch =
      member.name.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = (_filterStatus == 'all') ||
          (_filterStatus == 'active' && member.status == 1) ||
          (_filterStatus == 'due' && member.status == 0) ||
          (_filterStatus == 'renewed' && member.status == 2);

      return matchesSearch && matchesStatus;
    }).toList();
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

  // Future<void> _deleteMember(Member member) async {
  //   await memberService.deleteMember(member.id);
  //   setState(() {
  //     members = memberService.getMembers(); // Refresh the member list
  //   });
  // }

  Future<void> _showMemberOptions(Member member) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Full height if needed
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Member'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MemberDetailScreen(member: member),
                    ),
                  ).then((_) {
                    setState(() {
                      _page = 0;
                      _members.clear();
                      _hasMore = true;
                      _fetchMembers(); // ✅ refresh members
                    });
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Member'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMembers(member: member),
                    ),
                  ).then((_) {
                    setState(() {
                      _page = 0;
                      _members.clear();
                      _hasMore = true;
                      _fetchMembers(); // ✅ refresh members
                    });
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Member'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMember(member.id);
                },
              ),
              if (member.status != 1) // Example: only show Renew if not active
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Renew Membership'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Add your renew membership navigation here
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
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this member?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                try {
                  await memberService.deleteMember(memberId); // Call your delete method

                  setState(() {
                    _members.removeWhere((m) => m.id == memberId); // ✅ Remove locally
                  });

                  // Optionally reload first page to stay in sync with DB
                  setState(() {
                    _page = 0;
                    _members.clear();
                    _hasMore = true;
                    _fetchMembers();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member deleted successfully')),
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

  MemoryImage? _decodeBase64(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    try {
      // if base64 has prefix like "data:image/png;base64,..."
      final cleaned = base64.contains(",") ? base64.split(",").last : base64;
      final bytes = base64Decode(cleaned);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint("⚠️ Base64 decode error: $e");
      return null;
    }
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
                    controller: _searchController, // 👈 add a controller
                    decoration: InputDecoration(
                      hintText: 'Search members...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search), // 👈 search button
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text.trim();
                      _page = 0;
                      _hasMore = true;
                      _members.clear();
                    });
                    _fetchMembers();
                  },
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
                    label: const Text('All'),
                    selected: _filterStatus == 'all',
                    onSelected: (bool selected) {
                      setState(() {
                        _filterStatus = 'all';
                        _page = 0;
                        _hasMore = true;
                        _members.clear();
                      });
                      _fetchMembers();
                    },
                  ),
                  FilterChip(
                    label: const Text('Active'),
                    selected: _filterStatus == 'active',
                    onSelected: (bool selected) {
                      setState(() {
                        _filterStatus = 'active';
                        _page = 0;
                        _hasMore = true;
                        _members.clear();
                      });
                      _fetchMembers();
                    },
                  ),
                  FilterChip(
                    label: const Text('Due'),
                    selected: _filterStatus == 'due',
                    onSelected: (bool selected) {
                      setState(() {
                        _filterStatus = 'due';
                        _page = 0;
                        _hasMore = true;
                        _members.clear();
                      });
                      _fetchMembers();
                    },
                  ),
                  FilterChip(
                    label: const Text('Renewed'),
                    selected: _filterStatus == 'renewed',
                    onSelected: (bool selected) {
                      setState(() {
                        _filterStatus = 'renewed';
                        _page = 0;
                        _hasMore = true;
                        _members.clear();
                      });
                      _fetchMembers();
                    },
                  ),
                ],
              ),
            ),
          Expanded(

            child: Builder(
              builder: (context) {
                if (!userInitialized || _isLoading && _members.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_members.isEmpty && !_isLoading) {
                  return const Center(child: Text("No members found"));
                }
                // final filteredMembers = _applyFilters();
                //
                // if (filteredMembers.isEmpty) {
                //   return const Center(child: Text("No members found"));
                // }

                return RefreshIndicator(
                onRefresh: () async {
    setState(() {
    _page = 0;
    _hasMore = true;
    _members.clear();
    });
    await _fetchMembers();
    },
    child: ListView.separated(
    controller: _scrollController,
    itemCount: _members.length + (_hasMore ? 1 : 0),
    itemBuilder: (context, index) {
    if (index == _members.length) {
    return const Padding(
    padding: EdgeInsets.all(10),
    child: Center(child: CircularProgressIndicator()),
    );
    }
    final member = _members[index];
    return Card(
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10.0),
    ),
    elevation: 5,
    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
    child: ListTile(
    leading: CircleAvatar(
    backgroundImage: _decodeBase64(member.image),
    ),
    title: Text(member.name),
    subtitle: Text(
    "Expired at: ${member.expiredAt}",
    style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    trailing: Container(
    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
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
        : "Due",
    style: const TextStyle(color: Colors.white),
    ),
    ),
    onTap: () {
    _showMemberOptions(member);
    },
    ),
    );
    },
    separatorBuilder: (context, index) => const Divider(),
    ),
    );


              },
            ),
          ),
        ],
      ),
      floatingActionButton: (!userInitialized || (!_subscription && user.membersLimit <= _members.length))
          ? const SizedBox.shrink()
          : FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMembers()),
          ).then((_) {
            // Reset and reload after adding a member
            setState(() {
              _page = 0;
              _members.clear();
              _hasMore = true;
              _fetchMembers();
            });
          });
        },
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),

    );
  }
}
