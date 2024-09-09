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
  final TextEditingController _discountAmountController =
      TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  int _selectedPeriod = 0;
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
      _selectedPeriod = member.membershipPeriod;
      _daysController.text = member.days.toString();

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
                  String formattedJoiningDate =
                      dateFormat.format(_selectedJoiningDate!);

                  final joiningDate = _selectedJoiningDate ?? DateTime.now();
                  final plansLimit = selectedPlan.planLimit.toInt();
                  final futureDate = _selectedPeriod == 1  ? joiningDate.add(Duration(days: int.parse(_daysController.text))) : DateTime(
                      joiningDate.year, joiningDate.month + plansLimit, joiningDate.day);
                  final expiredDate =
                      DateFormat('dd-MMMM-yyyy').format(futureDate);

                  final response = await _membershipService.renewMembership(
                      joiningDate: formattedJoiningDate,
                      discountedAmount: _discountAmountController.text,
                      expiredDate: expiredDate,
                      planId: _selectedPlanId,
                      memberId: widget.member.id.toString(),
                      membershipPeriod: _selectedPeriod.toString(),
                      days: _daysController.text);
                  if (response['success'] == false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Membership renewal failed for ${widget.member.name}!')),
                    );
                    return;
                  } else {
                    final planAmount = _discountAmountController.text.isEmpty ||
                            _discountAmountController.text == '0'
                        ? selectedPlan.planPrice
                        : _discountAmountController.text;
                    final transactionResponse =
                        await _transactionService.insertTransaction(
                            gymId: widget.member.gymId,
                            planId: widget.member.planId,
                            amount: planAmount,
                            amountType: widget.member.amountType,
                            memberId: widget.member.id,
                            date: widget.member.joiningDate,
                            planName: _selectedPeriod == 0 ? selectedPlan.planName : "",
                            planLimit:  _selectedPeriod == 0 ? selectedPlan.planLimit.toString() : "",
                            memberName: widget.member.name,
                            memberPhone: widget.member.phoneNo,
                            days: _daysController.text);
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
  String getSelectedPlanName() {
    final selectedPlan = _plans.firstWhere(
          (plan) => plan.id.toString() == _selectedPlanId,
      orElse: () => Plan(
          id: 0,
          planName: 'No Plan Selected',
          gymId: "0",
          planLimit: 0,
          planPrice: "0"), // Return a default Plan if none is found
    );
    return _selectedPlanId == ''
        ? 'No Plan Selected'
        : '₹ ${selectedPlan.planPrice}'; // Return the plan name or a default message
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
                    SizedBox(height: 20),
                    _buildChoiceChipSection(
                      title: 'Plan Period',
                      options: ['Month', 'Days'],
                      selectedOption: _selectedPeriod == 1 ? 'Days' : 'Month',
                      onSelected: (selected) {
                        setState(() {
                          _selectedPeriod = selected == 'Days' ? 1 : 0;
                        });
                      },
                    ),
                    SizedBox(height: 20),
                    Visibility(
                      visible: _selectedPeriod == 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdownSection(
                            title: 'Select Plan',
                            items: _plans.map((Plan plan) {
                              return DropdownMenuItem<String>(
                                value: plan.id.toString(),
                                child: Text(plan.planName),
                              );
                            }).toList(),
                            selectedValue: _selectedPlanId.isEmpty ? null : _selectedPlanId,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedPlanId = newValue!;
                              });
                            },
                            onAddPressed: () {
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
                          SizedBox(height: 10),
                          _buildPlanAmountSection(),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: _selectedPeriod == 1,
                      child: TextFormField(
                        controller: _daysController,
                        decoration: InputDecoration(
                          labelText: 'Number of Days',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>  _selectedPeriod == 1 &&
                            (value == null || value.isEmpty)
                            ? 'Number of days is required'
                            : null,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildTextFormField(
                      controller: _discountAmountController,
                      label:
                          _selectedPeriod == 1 ? 'Amount' : 'Discount Amount',
                      icon: Icons.price_check,
                      keyboardType: TextInputType.number,
                      validator: (value) => _selectedPeriod == 1 &&
                              (value == null || value.isEmpty)
                          ? 'Amount is required'
                          : null,
                    ),
                    SizedBox(height: 10),
                    _buildChoiceChipSection(
                      title: 'Payment Type',
                      options: ['Cash', 'Online'],
                      selectedOption: _selectedPaymentType,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPaymentType = selected;
                        });
                      },
                    ),
                    SizedBox(height: 20),
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
  Widget _buildPlanAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan Amount',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 10),
        Text(
          getSelectedPlanName(),
          style: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}


Widget _buildTextFormField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(),
    ),
    validator: validator,
  );
}
Widget _buildChoiceChipSection({
  required String title,
  required List<String> options,
  required String selectedOption,
  required void Function(String selected) onSelected,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      SizedBox(height: 10),
      Wrap(
        spacing: 10,
        children: options.map((option) {
          return ChoiceChip(
            label: Text(option),
            selected: selectedOption == option,
            onSelected: (selected) {
              onSelected(selected ? option : '');
            },
          );
        }).toList(),
      ),
    ],
  );
}
Widget _buildDropdownSection({
  required String title,
  required List<DropdownMenuItem<String>> items,
  required String? selectedValue,
  required void Function(String?) onChanged,
  required VoidCallback onAddPressed,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
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
              value: selectedValue,
              hint: Text('Select Plan'),
              items: items,
              onChanged: onChanged,
              validator: (value) =>
              value == null || value.isEmpty ? 'Plan is required' : null,
            ),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: onAddPressed,
          ),
        ],
      ),
    ],
  );
}



