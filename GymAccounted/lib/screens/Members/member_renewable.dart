import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gymaccounted/Modal/plan_dm.dart'; // Import Plan model
import 'package:gymaccounted/Networking/plans_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/screens/Plans/add_plans.dart';
import 'package:gymaccounted/Modal/members_dm.dart';
import 'package:gymaccounted/Networking/members_api.dart';
import 'package:gymaccounted/Networking/membership_api.dart';
import 'package:gymaccounted/Networking/transaction_api.dart';

class MemberRenewable extends StatefulWidget {
  final Member member; // Make member non-optional

  const MemberRenewable({Key? key, required this.member}) : super(key: key);

  @override
  _MemberRenewableState createState() => _MemberRenewableState();
}

class _MemberRenewableState extends State<MemberRenewable> {
  DateTime? _selectedJoiningDate;
  String _selectedPlanId = '';
  String _selectedPaymentType = '';
  late PlanService _planService;
  late MembershipService _membershipService;
  late TransactionService _transactionService;
  late MemberService _memberService;
  final TextEditingController _discountAmountController = TextEditingController();

  List<Plan> _plans = [];
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  DateTime parseDateString(String dateStr) {
    final dateFormat = DateFormat('dd-MMMM-yyyy'); // Adjust if needed
    return dateFormat.parse(dateStr);
  }
  @override
  void initState() {
    super.initState();
    _membershipService = MembershipService(Supabase.instance.client);
    _transactionService = TransactionService(Supabase.instance.client);
    _memberService = MemberService(Supabase.instance.client);
    _planService = PlanService(Supabase.instance.client);
    if (widget.member != null) {
      final member = widget.member;
      _discountAmountController.text = member.discountedAmount ?? '';
      _selectedPaymentType = member.amountType ?? '';
      _selectedPlanId =
          member.planId.toString() ?? ''; // Initialize selected plan ID
      try {
        _selectedJoiningDate = parseDateString(member.expiredAt);

      } catch (e) {
        _selectedJoiningDate =
            DateTime.now(); // Fallback to current date if parsing fails
      }
    }
    _fetchPlans();
  }

  void _renewMembership() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Renewal'),
          content: Text(
              'Are you sure you want to renew the membership for ${widget.member.name}?'),
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
                  final selectedPlan = _plans.firstWhere(
                        (plan) => plan.id == int.parse(_selectedPlanId),
                    orElse: () => Plan(
                      id: 0,
                      planName: 'planName',
                      planLimit: 0,
                      planPrice: 'planPrice',
                      gymId: 'gymId', // Default if not found
                    ),
                  );


                  DateFormat dateFormat = DateFormat('yyyy-MM-dd');
                  String formattedJoiningDate = dateFormat.format(_selectedJoiningDate!);

                  final joiningDate = _selectedJoiningDate ?? DateTime.now();
                  final plansLimit = selectedPlan.planLimit.toInt();
                  final futureDate = DateTime(joiningDate.year, joiningDate.month + plansLimit, joiningDate.day);
                  final expiredDate = DateFormat('dd-MMMM-yyyy').format(futureDate);

                  final response = await _membershipService.renewMembership(
                      joiningDate: formattedJoiningDate,
                      discountedAmount: _discountAmountController.text,
                      expiredDate: expiredDate,
                      planId: _selectedPlanId,
                      memberId: widget.member.id.toString());
                  if (response['success'] == false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Membership renewal failed for ${widget.member.name}!')),
                    );
                    return;
                  } else {
                    final planAmount = _discountAmountController.text.isEmpty || _discountAmountController.text == '0' ? selectedPlan.planPrice : _discountAmountController.text;
                    final transactionResponse =
                    await _transactionService.insertTransaction(
                      gymId: widget.member.gymId,
                      planId: widget.member.planId,
                      amount: planAmount,
                      amountType: widget.member.amountType,
                      memberId: widget.member.id,
                      date: widget.member.joiningDate,
                      planName: selectedPlan.planName,
                      planLimit: selectedPlan.planLimit.toString(),
                      memberName: widget.member.name,
                      memberPhone: widget.member.phoneNo,
                      days: ""
                    );
                    if (transactionResponse['success'] == false) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Error inserting transaction: ${transactionResponse['message']}')),
                      );
                      return;
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Membership renewed for ${widget.member.name}!')),
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

  Future<void> _fetchPlans() async {
    try {
      final plans = await _planService.getPlans();
      setState(() {
        _plans = plans;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching plans: $error')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedJoiningDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedJoiningDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Handle form submission
      _renewMembership();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RENEW MEMBER',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Select Renew Date Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Renew Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _selectDate(context),
                          child: Text(
                            _selectedJoiningDate == null
                                ? 'Select Date'
                                : DateFormat('dd-MMMM-yyyy')
                                .format(_selectedJoiningDate!),
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Plan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedPlanId.isEmpty ? null : _selectedPlanId,
                                hint: Text('Select Plan'),
                                items: _plans.map((Plan plan) {
                                  return DropdownMenuItem<String>(
                                    value: plan.id.toString(),
                                    child: Text(plan.planName),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedPlanId = newValue!;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Plan is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AddPlans()),
                                ).then((_) {
                                  setState(() {
                                    _fetchPlans();
                                  });
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _discountAmountController,
                      decoration: InputDecoration(
                        labelText: 'Discount Amount',
                        prefixIcon: Icon(Icons.price_check),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Payment Type Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Wrap(
                          children: [
                            ChoiceChip(
                              label: Text('Cash'),
                              selected: _selectedPaymentType == 'Cash',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedPaymentType = selected ? 'Cash' : '';
                                });
                              },
                            ),
                            SizedBox(width: 10),
                            ChoiceChip(
                              label: Text('Online'),
                              selected: _selectedPaymentType == 'Online',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedPaymentType =
                                  selected ? 'Online' : '';
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
