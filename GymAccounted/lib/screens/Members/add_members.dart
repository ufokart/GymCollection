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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String _selectedGender = '';
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
      _nameController.text = member.name;
      _emailController.text = member.email;
      _addressController.text = member.address ?? '';
      _phoneController.text = member.phoneNo ?? '';
      _selectedGender = member.gender ?? '';
      _selectedBatch = member.batch ?? '';
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

  // Future<void> _getImage() async {
  //   final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  //
  //   if (pickedFile != null) {
  //     setState(() {
  //       _image = File(pickedFile.path);
  //     });
  //     await convertImageToBase64(_image);
  //   } else {
  //     print('No image selected.');
  //   }
  // }

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

      if (_selectedJoiningDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joining Date is required.')),
        );
        setState(() {
          _isLoading = false; // Stop loading state
        });
        return; // Exit the method
      }

      // if (_selectedDob == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Date of Birth is required.')),
      //   );
      //   setState(() {
      //     _isLoading = false; // Stop loading state
      //   });
      //   return; // Exit the method
      // }

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
        String formattedDob = _selectedDob != null ? dateFormat.format(_selectedDob!) : "";

        // Check if updating or inserting
        if (widget.member == null) {
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
          } else {
            // Handle membership and transaction
            await _handleMembershipAndTransaction(result['data']);
          }
        } else {
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
    final futureDate = DateTime(joiningDate.year, joiningDate.month + plansLimit, joiningDate.day);
    final expiredDate = DateFormat('dd-MMMM-yyyy').format(futureDate);

    if (widget.member != null) {
      // Update Membership
      final membershipResponse = await _membershipService.updateMembership(
        joiningDate: insertedMember.joiningDate.toString(),
        planId: insertedMember.planId,
        expiredDate: expiredDate,
        memberId: insertedMember.id.toString(),
      );

      if (membershipResponse['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error updating membership: ${membershipResponse['message']}')),
        );
        return; // Early exit if update fails
      }
      // Update Transaction
      final planAmount = selectedPlan.planPrice;

      final transactionResponse = await _transactionService.updateTransaction(
          planId: insertedMember.planId,
          amount: planAmount,
          memberId: insertedMember.id,
          amountType: _selectedPaymentType.toString(),
          date: insertedMember.joiningDate.toString(),
          planName: selectedPlan.planName,
          planLimit: selectedPlan.planLimit.toString(),
          memberName: insertedMember.name,
          memberPhone: insertedMember.phoneNo);

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
      );

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

      final planAmount = selectedPlan.planPrice;

      final transactionResponse = await _transactionService.insertTransaction(
        gymId: insertedMember.gymId,
        planId: insertedMember.planId,
        amount: planAmount,
        amountType: _selectedPaymentType.toString(),
        memberId: insertedMember.id,
        date: insertedMember.joiningDate.toString(),
        planName: selectedPlan.planName,
        planLimit: selectedPlan.planLimit.toString(),
        memberName: insertedMember.name,
        memberPhone: insertedMember.phoneNo,
      );

      if (transactionResponse['success'] == false) {
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
    } else if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
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
            child: Container(
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
                              color: Colors.black,
                              width: 2.0,
                            ),
                          ),
                          child: ClipOval(
                            child: _image == null
                                ? Icon(
                                    Icons.add_a_photo,
                                    size: 24.0,
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
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateEmail,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: _validatePhone,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gender',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Wrap(
                          children: [
                            ChoiceChip(
                              label: Text('Male'),
                              selected: _selectedGender == 'Male',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedGender = selected ? 'Male' : '';
                                });
                              },
                            ),
                            SizedBox(width: 10),
                            ChoiceChip(
                              label: Text('Female'),
                              selected: _selectedGender == 'Female',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedGender = selected ? 'Female' : '';
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Wrap(
                          children: [
                            ChoiceChip(
                              label: Text('Morning'),
                              selected: _selectedBatch == 'Morning',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedBatch = selected ? 'Morning' : '';
                                });
                              },
                            ),
                            SizedBox(width: 10),
                            ChoiceChip(
                              label: Text('Noon'),
                              selected: _selectedBatch == 'Noon',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedBatch = selected ? 'Noon' : '';
                                });
                              },
                            ),
                            SizedBox(width: 10),
                            ChoiceChip(
                              label: Text('Evening'),
                              selected: _selectedBatch == 'Evening',
                              onSelected: (selected) {
                                setState(() {
                                  _selectedBatch = selected ? 'Evening' : '';
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Joining Date',
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
                                : DateFormat('MMM dd, yyyy')
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
                    SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date of Birth',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _selectDate(context, isDob: true),
                          child: Text(
                            _selectedDob == null
                                ? 'Select Date'
                                : DateFormat('MMM dd, yyyy')
                                    .format(_selectedDob!),
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
                    SizedBox(height: 10),
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
                    SizedBox(height: 10),
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
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ), // Your existing form building method
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
