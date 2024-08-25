import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/Networking/Apis.dart';
import 'package:gymaccounted/screens/Dashboard/dashboard.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:gotrue/src/types/user.dart' as gotrueUser;
import 'package:gymaccounted/Modal/gym_dm.dart';
import 'package:gymaccounted/screens/Members/add_members.dart';
import 'package:gymaccounted/screens/Login/loginscreen.dart';
import 'package:gymaccounted/screens/home_screen.dart';

class AddUserScreen extends StatefulWidget {
  final Gym? gym; // Accept Gym object

  const AddUserScreen({Key? key, this.gym}) : super(key: key);

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  File? _image;
  String _base64Image = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late GymService _gymService;
  bool isEdit = false;
  bool _isLoading = false; // Add this line

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _gymService = GymService(Supabase.instance.client);

    if (widget.gym != null) {
      isEdit = true;
      _nameController.text = widget.gym!.name;
      _emailController.text = widget.gym!.email;
      _addressController.text = widget.gym!.address;
      _phoneController.text = widget.gym!.phoneNo;
      _base64Image = widget.gym!.image; // Assuming `image` is the base64 string

      if (_base64Image.isNotEmpty) {
        convertBase64ToImageFile(_base64Image).then((file) {
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

  Future<void> _logout(BuildContext context) async {
    await gymUser.User.clearUser();
    // Navigate to the login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
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
  Future<void> convertImageToBase64(File? imageFile) async {
    if (imageFile == null) {
      print('No file selected');
      return;
    }
    final bytes = await imageFile.readAsBytes();
    setState(() {
      _base64Image = base64Encode(bytes);
    });
  }

  Future<void> insertOrUpdateGym() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loader
      });

      if (_base64Image == null && !isEdit) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an image.')),
        );
        setState(() {
          _isLoading = false; // Hide loader
        });
        return;
      }

      gymUser.User? user = await gymUser.User.getUser();
      String? id = user?.id ?? "";

      if (isEdit) {
        // Update existing gym
        final result = await _gymService.updateGym(
          id: widget.gym!.id,
          name: _nameController.text,
          address: _addressController.text,
          email: _emailController.text,
          phoneNo: _phoneController.text,
          image: _base64Image ?? '',
        );

        if (result['success'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['message']}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gym updated successfully.')),
          );
          Navigator.pop(context);
        }
      } else {
        // Insert new gym
        final result = await _gymService.insertGym(
          name: _nameController.text,
          address: _addressController.text,
          email: _emailController.text,
          phoneNo: _phoneController.text,
          uid: id,
          image: _base64Image!,
        );

        if (result['success'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['message']}')),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(), // Replace with the screen you want to navigate to
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gym inserted successfully.')),
          );
        }
      }

      setState(() {
        _isLoading = false; // Hide loader
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "EDIT GYM" : "ADD GYM",
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          onPressed: () {
            if (isEdit) {
              Navigator.pop(context);
            } else {
              _logout(context);
            }
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      return 'Please enter your name';
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
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                        .hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    } else if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
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
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 50),
                ElevatedButton(
                  onPressed: insertOrUpdateGym,
                  child: Text(isEdit ? 'Update' : 'Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
