import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:gymaccounted/Networking/Apis.dart';
import 'package:gymaccounted/Modal/members_dm.dart';
import 'package:gymaccounted/Modal/plan_dm.dart'; // Import Plan model
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:gymaccounted/Modal/membership_plan_dm.dart';
import 'package:gymaccounted/Networking/members_api.dart';
import 'package:gymaccounted/Networking/plans_api.dart';
import 'package:gymaccounted/Networking/membership_api.dart';
import 'package:gymaccounted/Networking/transaction_api.dart';
import 'package:gymaccounted/Networking/subscription_api.dart';
import 'package:gymaccounted/screens/Plans/add_plans.dart';

class AddMembers extends StatefulWidget {
  final Member? member; // Accept Member object

  const AddMembers({Key? key, this.member}) : super(key: key);

  @override
  _AddMembersState createState() => _AddMembersState();
}

class _AddMembersState extends State<AddMembers> {
  File? _image;
  DateTime? _selectedJoiningDate;
  DateTime? _selectedDob;
  bool _showPlanDetails = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _discountAmountController =
      TextEditingController();
  final TextEditingController _daysController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  String _selectedGender = '';
  int _selectedPeriod = 0;
  String _selectedBatch = '';
  String _selectedPlanId = ''; // Updated variable for selected plan ID
  String _selectedPaymentType = '';
  List<Plan> _plans = []; // Variable to hold the list of plans
  String _imageBase64 = '';
  late GymService _gymService;
  late PlanService _planService;
  late MembershipService _membershipService;
  late TransactionService _transactionService;
  late MemberService _memberService;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _gymService = GymService(Supabase.instance.client);
    _planService = PlanService(Supabase.instance.client);
    _membershipService = MembershipService(Supabase.instance.client);
    _transactionService = TransactionService(Supabase.instance.client);
    _memberService = MemberService(Supabase.instance.client);
    // Initialize fields if member data is provided
    if (widget.member != null) {
      final member = widget.member!;
      _daysController.text = member.days.toString();
      _nameController.text = member.name;
      _emailController.text = member.email;
      _addressController.text = member.address ?? '';
      _phoneController.text = member.phoneNo ?? '';
      _discountAmountController.text = member.discountedAmount ?? '0';
      _selectedGender = member.gender ?? '';
      _selectedBatch = member.batch ?? '';
      _selectedPeriod = member.membershipPeriod;
      _selectedPaymentType = member.amountType ?? '';
      _selectedPlanId =
          member.planId.toString() ?? ''; // Initialize selected plan ID
      try {
        _selectedJoiningDate = DateTime.tryParse(
            member.joiningDate?.toString() ?? DateTime.now().toString());
      } catch (e) {
        _selectedJoiningDate =
            DateTime.now(); // Fallback to current date if parsing fails
      }
      try {
        _selectedDob = DateTime.tryParse(
            member.dob?.toString() ?? DateTime.now().toString());
      } catch (e) {
        _selectedDob =
            DateTime.now(); // Fallback to current date if parsing fails
      }
      _imageBase64 = member.image ?? '';

      if (_imageBase64.isNotEmpty) {
        convertBase64ToImageFile(_imageBase64).then((file) {
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
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    gymUser.User? user = await gymUser.User.getUser();
    String? id = user?.id ?? "";
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

  Future<File?> convertBase64ToImageFile(String base64String) async {
    if (base64String.isEmpty) return null;

    final bytes = base64Decode(base64String);

    // Get the temporary directory
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/temp_image.png'; // Change extension as needed

    // Write bytes to a file
    final file = File(path);
    await file.writeAsBytes(bytes);

    return file;
  }

  Future<void> convertImageToBase64(File? imageFile) async {
    if (imageFile == null) {
      print('No file selected');
      return;
    }
    final bytes = await imageFile.readAsBytes();
    setState(() {
      _imageBase64 = base64Encode(bytes);
    });
  }

  Future<void> _selectDate(BuildContext context, {bool isDob = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDob
          ? (_selectedDob ?? DateTime.now())
          : (_selectedJoiningDate ?? DateTime.now()),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isDob) {
          _selectedDob = picked;
        } else {
          _selectedJoiningDate = picked;
        }
      });
    }
  }

  Future<bool> _checkMemberExists() async {
    try {
      // Call the service to get member details by name and phone number
      final result = await _memberService.getMemberByNameAndPhoneNo(
        name: _nameController.text,
        phone: _phoneController.text,
      );

      // If the member exists, show an error message and return true
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['message']}')),
        );
        return true; // Member exists
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
    return false; // Member does not exist
  }

  Future<void> _getImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Choose Image Source',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.blue),
              title: Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.image, color: Colors.blue),
              title: Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (source != null) {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        await convertImageToBase64(_image);
      } else {
        print('No image selected.');
      }
    }
  }

  void _showMemberExistsDialog(String existingMemberDetail) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Member Already Exists'),
          content: Text(
              'A member with the same $existingMemberDetail already exists. What would you like to do?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                setState(() {
                  _isLoading = false;
                });
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss the dialog
                setState(() {
                  _isLoading = true;
                });
                gymUser.User? user = await gymUser.User.getUser();
                String? id = user?.id ?? "";
                DateFormat dateFormat = DateFormat('yyyy-MM-dd');
                String formattedJoiningDate = dateFormat.format(_selectedJoiningDate!);
                String formattedDob =
                _selectedDob != null ? dateFormat.format(_selectedDob!) : "";
                // Insert new member
                final result = await _memberService.insertMember(
                  name: _nameController.text,
                  address: _addressController.text,
                  email: _emailController.text,
                  phone: _phoneController.text,
                  batch: _selectedBatch,
                  gender: _selectedGender,
                  joining_date: formattedJoiningDate,
                  dob: formattedDob,
                  gymId: id,
                  image: _imageBase64,
                  planId: int.parse(_selectedPlanId), // Pass the selected plan ID
                );

                if (result['success'] == false) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${result['message']}')),
                  );
                  setState(() {
                    _isLoading = false;
                  });
                } else {
                  // Handle membership and transaction
                  await _handleMembershipAndTransaction(result['data']);
                }
              },
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      if (_selectedGender.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gender is required.')),
        );
        setState(() {
          _isLoading = false; // Stop loading state
        });
        return; // Exit the method
      }

      if (_selectedBatch.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Batch is required.')),
        );
        setState(() {
          _isLoading = false; // Stop loading state
        });
        return; // Exit the method
      }

      if ((_daysController.text.isEmpty || _daysController.text == '0') && _selectedPeriod == 1)  {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Days is required.')),
        );
        setState(() {
          _isLoading = false; // Stop loading state
        });
        return; // Exit the method
      }

      if ((_discountAmountController.text.isEmpty || _discountAmountController.text == '0') && _selectedPeriod == 1)  {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Amount is required.')),
        );
        setState(() {
          _isLoading = false; // Stop loading state
        });
        return; // Exit the method
      }

      if (_selectedJoiningDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joining Date is required.')),
        );
        setState(() {
          _isLoading = false; // Stop loading state
        });
        return; // Exit the method
      }

      if (_selectedPaymentType.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Type is required.')),
        );
        setState(() {
          _isLoading = false; // Stop loading state
        });
        return; // Exit the method
      }

      

      try {
        gymUser.User? user = await gymUser.User.getUser();
        String? id = user?.id ?? "";
        DateFormat dateFormat = DateFormat('yyyy-MM-dd');
        String formattedJoiningDate = dateFormat.format(_selectedJoiningDate!);
        String formattedDob =
            _selectedDob != null ? dateFormat.format(_selectedDob!) : "";
        // Check if updating or inserting
        if (widget.member == null) {
          bool memberExists = await _checkMemberExists();
          if (memberExists) {
            String existingMemberDetail = "phone number or name";
            _showMemberExistsDialog(existingMemberDetail);
            setState(() {
              _isLoading = false; // Stop loading state
            });
          } else {
            final result = await _memberService.insertMember(
              name: _nameController.text,
              address: _addressController.text,
              email: _emailController.text,
              phone: _phoneController.text,
              batch: _selectedBatch,
              gender: _selectedGender,
              joining_date: formattedJoiningDate,
              dob: formattedDob,
              gymId: id,
              image: _imageBase64,
              planId: int.parse(_selectedPlanId), // Pass the selected plan ID
            );

            if (result['success'] == false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${result['message']}')),
              );
            } else {
              // Handle membership and transaction
              await _handleMembershipAndTransaction(result['data']);
            }
          }
        }
        else {
          // Update existing member
          final memberId = widget.member!.id;
          final result = await _memberService.updateMember(
            id: memberId,
            name: _nameController.text,
            address: _addressController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            batch: _selectedBatch,
            gender: _selectedGender,
            joiningDate: formattedJoiningDate,
            dob: formattedDob,
            gymId: id,
            image: _imageBase64,
            planId: int.parse(_selectedPlanId), // Pass the selected plan ID
          );

          if (result['success'] == false) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${result['message']}')),
            );
          } else {
            // Handle membership and transaction
            await _handleMembershipAndTransaction(result['data']);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields correctly.')),
      );
    }
  }

  Future<void> _handleMembershipAndTransaction(Member insertedMember) async {
    // Check if member ID is not null

    final selectedPlan = _plans.firstWhere(
      (plan) => plan.id == insertedMember.planId,
      orElse: () => Plan(
        id: 0,
        planName: 'planName',
        planLimit: 0,
        planPrice: 'planPrice',
        gymId: 'gymId', // Default if not found
      ),
    );
    final joiningDate = _selectedJoiningDate ?? DateTime.now();
    final plansLimit = selectedPlan.planLimit.toInt();
    final futureDate = _selectedPeriod == 1  ? joiningDate.add(Duration(days: int.parse(_daysController.text))) : DateTime(
        joiningDate.year, joiningDate.month + plansLimit, joiningDate.day);
    final expiredDate = DateFormat('dd-MMMM-yyyy').format(futureDate);

    if (widget.member != null) {
      // Update Membership
      final membershipResponse = await _membershipService.updateMembership(
          joiningDate: insertedMember.joiningDate.toString(),
          planId: insertedMember.planId,
          expiredDate: expiredDate,
          memberId: insertedMember.id.toString(),
          discountedAmount: _discountAmountController.text,
          membershipPeriod: _selectedPeriod.toString(),
          days: _daysController.text.isEmpty ? '0' : _daysController.text);

      if (membershipResponse['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error updating membership: ${membershipResponse['message']}')),
        );
        return; // Early exit if update fails
      }
      // Update Transaction
      //final planAmount = selectedPlan.planPrice;
      final planAmount = _discountAmountController.text.isEmpty
          ? selectedPlan.planPrice
          : _discountAmountController.text;

      final transactionResponse = await _transactionService.updateTransaction(
          planId: insertedMember.planId,
          amount: planAmount,
          memberId: insertedMember.id,
          amountType: _selectedPaymentType.toString(),
          date: insertedMember.joiningDate.toString(),
          planName: _selectedPeriod == 0 ? selectedPlan.planName : "",
          planLimit:  _selectedPeriod == 0 ? selectedPlan.planLimit.toString() : "",
          memberName: insertedMember.name,
          memberPhone: insertedMember.phoneNo,
          tnxId: widget.member?.trxId ?? '0',
          days: _daysController.text.isEmpty ? '0' : _daysController.text);

      if (transactionResponse['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error updating transaction: ${transactionResponse['message']}')),
        );
        return; // Early exit if update fails
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member updated successfully.')),
      );
    } else {
      // If member ID is null, insert new membership and transaction
      final insertResponse = await _membershipService.insetMembership(
          gymId: insertedMember.gymId,
          joiningDate: insertedMember.joiningDate.toString(),
          memberId: insertedMember.id,
          planId: insertedMember.planId,
          status: 1,
          renew: false,
          expiredDate: expiredDate,
          discountedAmount: _discountAmountController.text,
          membershipPeriod: _selectedPeriod.toString(),
          days: _daysController.text.isEmpty ? '0' : _daysController.text);

      if (insertResponse['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error inserting membership: ${insertResponse['message']}')),
        );
        return; // Early exit if insertion fails
      }

      // Extract the amount from the selected plan
      final selectedPlan = _plans.firstWhere(
        (plan) => plan.id == insertedMember.planId,
        orElse: () => Plan(
          id: 0,
          planName: 'planName',
          planLimit: 0,
          planPrice: 'planPrice',
          gymId: 'gymId', // Default if not found
        ),
      );

      final planAmount = _discountAmountController.text.isEmpty
          ? selectedPlan.planPrice
          : _discountAmountController.text;

      final transactionResponse = await _transactionService.insertTransaction(
        gymId: insertedMember.gymId,
        planId: insertedMember.planId,
        amount: planAmount,
        amountType: _selectedPaymentType.toString(),
        memberId: insertedMember.id,
        date: insertedMember.joiningDate.toString(),
        planName: _selectedPeriod == 0 ? selectedPlan.planName : "",
        planLimit:  _selectedPeriod == 0 ? selectedPlan.planLimit.toString() : "",
        memberName: insertedMember.name,
        memberPhone: insertedMember.phoneNo,
        days:  _daysController.text.isEmpty ? '0' : _daysController.text
      );

      if (transactionResponse['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error inserting transaction: ${transactionResponse['message']}')),
        );
        return; // Early exit if insertion fails
      }
      final updateMembershipTnxIdResponse =
          await _membershipService.updateMembershipTnxId(
        tnxId: transactionResponse['data'][0]['id'],
        memberId: insertedMember.id,
      );
      if (updateMembershipTnxIdResponse['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error inserting transaction: ${transactionResponse['message']}')),
        );
        return; // Early exit if insertion fails
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member saved successfully.')),
      );
    }

    // If everything is successful, pop the context
    Navigator.pop(context);
  }

  String? _validateEmail(String? value) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    // if (value == null || value.isEmpty) {
    //   return 'Email is required';
    // } else
    if (value != null && value.isNotEmpty && !emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phoneRegex = RegExp(r'^\+?1?\d{9,15}$');
    if (value == null || value.isEmpty) {
      return 'Phone is required';
    } else if (value.length < 10) {
      return 'Please enter a valid phone number';
    } else if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
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
            widget.member == null ? 'Add Member' : 'Edit Member',
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
              padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: GestureDetector(
                      onTap: _getImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            width: 2.0,
                          ),
                        ),
                        child: ClipOval(
                          child: _image == null
                              ? Icon(
                                  Icons.add_a_photo,
                                  size: 24.0,
                                )
                              : Image.file(
                                  _image!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildTextFormField(
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.person,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  SizedBox(height: 10),
                  _buildTextFormField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    validator: _validateEmail,
                  ),
                  SizedBox(height: 10),
                  _buildTextFormField(
                    controller: _phoneController,
                    label: 'Phone',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                  SizedBox(height: 10),
                  _buildTextFormField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.home,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Address is required'
                        : null,
                  ),
                  SizedBox(height: 20),
                  _buildChoiceChipSection(
                    title: 'Gender',
                    options: ['Male', 'Female'],
                    selectedOption: _selectedGender,
                    onSelected: (selected) {
                      setState(() {
                        _selectedGender = selected;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  _buildChoiceChipSection(
                    title: 'Batch',
                    options: ['Morning', 'Noon', 'Evening'],
                    selectedOption: _selectedBatch,
                    onSelected: (selected) {
                      setState(() {
                        _selectedBatch = selected;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  _buildDateSelection(
                    title: 'Date of Birth',
                    selectedDate: _selectedDob,
                    onSelectDate: () => _selectDate(context, isDob: true),
                  ),
                  SizedBox(height: 10),
                  _buildDateSelection(
                    title: 'Select Joining Date',
                    selectedDate: _selectedJoiningDate,
                    onSelectDate: () => _selectDate(context),
                  ),
                  SizedBox(height: 20),
                  _buildChoiceChipSection(
                    title: 'Plan Period',
                    options: ['Month','Days'],
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
                  // Show this field if "Days" is selected
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
                      validator: (value) => value == null || value.isEmpty ? 'Number of days is required' : null,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildTextFormField(
                    controller: _discountAmountController,
                    label: _selectedPeriod == 1 ? 'Amount' : 'Discount Amount',
                    icon: Icons.price_check,
                    keyboardType: TextInputType.number,
                    validator: (value) =>  _selectedPeriod == 1 && (value == null || value.isEmpty) ? 'Amount is required' : null,
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
              )),
            ),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ));
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

  Widget _buildDateSelection({
    required String title,
    required DateTime? selectedDate,
    required void Function() onSelectDate,
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
        ElevatedButton(
          onPressed: onSelectDate,
          child: Text(
            selectedDate == null
                ? 'Select Date'
                : DateFormat('MMM dd, yyyy').format(selectedDate),
            style: TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
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
