import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/Modal/members_dm.dart';
import 'package:gymaccounted/Networking/members_api.dart';
import 'package:gymaccounted/Networking/membership_api.dart';
import 'package:gymaccounted/Networking/plans_api.dart';
import 'package:gymaccounted/Networking/transaction_api.dart';
import 'package:gymaccounted/Modal/plan_dm.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gymaccounted/Networking/subscription_api.dart';

class MemberDetailScreen extends StatefulWidget {
  final Member member; // Member instance passed to the screen

  const MemberDetailScreen({Key? key, required this.member}) : super(key: key);

  @override
  _MemberDetailScreenState createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  File? _image;
  List<Plan> _plans = [];
  String _planName = 'N/A';
  String _planLimit = 'N/A';
  String _planPrice = 'N/A';
  late PlanService _planService;
  late MembershipService _membershipService;
  late TransactionService _transactionService;




  void _renewMembership() {
    // Show confirmation alert dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Renewal'),
          content: Text('Are you sure you want to renew the membership for ${widget.member.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final response = await _membershipService.renewMembership(
                      memberId: widget.member.id.toString());
                  if (response['success'] == false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Membership renewal failed for ${widget.member.name}!')),
                    );
                    return;
                  } else {
                    final transactionResponse = await _transactionService.insertTransaction(
                      gymId: widget.member.gymId,
                      planId: widget.member.planId,
                      amount: _planPrice,
                      amountType: widget.member.amountType,
                      memberId: widget.member.id,
                      date: widget.member.joiningDate,
                      planName: _planName,
                      planLimit: _planLimit,
                      memberName: widget.member.name,
                      memberPhone: widget.member.phoneNo,
                    );
                    if (transactionResponse['success'] == false) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error inserting transaction: ${transactionResponse['message']}')),
                      );
                      return;
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Membership renewed for ${widget.member.name}!')),
                      );
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $e')),
                  );
                } finally {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pop(); // Pop member detail screen
                }
              },
              child: Text('Renew'),
            ),
          ],
        );
      },
    );
  }


  @override
  void initState() {
    super.initState();
    _planService = PlanService(Supabase.instance.client);
    _membershipService = MembershipService(Supabase.instance.client);
    _transactionService = TransactionService(Supabase.instance.client);


    _fetchPlans();
    if (widget.member.image.isNotEmpty) {
      convertBase64ToImageFile(widget.member.image).then((file) {
        if (file != null) {
          setState(() {
            _image = file;
          });
        }
      }).catchError((error) {
        print('Error converting Base64 to image file: $error');
      });
    }
  }

  Future<File?> convertBase64ToImageFile(String base64String) async {
    if (base64String.isEmpty) return null;

    final bytes = base64Decode(base64String);

    // Get the temporary directory
    final directory = await getTemporaryDirectory();
    final path = '${directory
        .path}/temp_image.png'; // Change extension as needed

    // Write bytes to a file
    final file = File(path);
    await file.writeAsBytes(bytes);

    return file;
  }

  Future<void> _fetchPlans() async {
    try {
      final plans = await _planService.getPlans();
      setState(() {
        _plans = plans;
        // Find the selected plan based on the member's planId
        final selectedPlan = _plans.firstWhere(
              (plan) => plan.id == widget.member.planId,
          orElse: () =>
              Plan(
                id: 0,
                planName: 'N/A',
                planLimit: 0,
                planPrice: '0.00',
                gymId: 'N/A', // Default if not found
              ),
        );
        _planLimit = selectedPlan.planLimit.toString();
        _planName = selectedPlan.planName;
        _planPrice = selectedPlan.planPrice;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching plans: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member; // Use the passed member

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'MEMBER DETAILS', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Member Image
            Center(
              child: ClipOval(
                child: _image == null
                    ? Icon(
                  Icons.account_circle_rounded,
                  size: 100.0,
                  color: Colors.black,
                )
                    : Image.file(
                  _image!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 16),
            // Member Details Section
            Text('Member Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Divider(thickness: 2),
            _buildDetailRow(
                'Name', member.name.isNotEmpty ? member.name : 'N/A'),
            _buildDetailRow(
                'Email', member.email.isNotEmpty ? member.email : 'N/A'),
            _buildDetailRow(
                'Address', member.address.isNotEmpty ? member.address : 'N/A'),
            _buildDetailRow(
                'Gender', member.gender.isNotEmpty ? member.gender : 'N/A'),
            _buildDetailRow(
                'Batch', member.batch.isNotEmpty ? member.batch : 'N/A'),
            _buildDetailRow('Joined Date',
                member.joiningDate.isNotEmpty ? member.joiningDate : 'N/A'),
            _buildDetailRow(
                'Phone No', member.phoneNo.isNotEmpty ? member.phoneNo : 'N/A'),
            _buildDetailRow(
                'Date of Birth', member.dob.isNotEmpty ? member.dob : 'N/A'),
            SizedBox(height: 16),
            // Plan Details Section
            Text('Plan Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Divider(thickness: 2),
            _buildDetailRow(
                'Plan Name', _planName.isNotEmpty ? _planName : 'N/A'),
            _buildDetailRow('Plan Limit (In Month)',
                _planLimit.isNotEmpty ? _planLimit : 'N/A'),
            _buildDetailRow(
                'Plan Price', _planPrice.isNotEmpty ? '\₹$_planPrice' : 'N/A'),
            Divider(thickness: 2),
            // Highlight Expire Date
            Text('Plan Expired Date', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
            Text(member.expiredAt.isNotEmpty ? member.expiredAt : 'N/A',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            // Renew Button
            if (member.status == 0) // Status 0 indicates due
              ElevatedButton(
                onPressed: _renewMembership,
                child: Text('Renew Membership'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: Text(value, textAlign: TextAlign.end,
                style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
