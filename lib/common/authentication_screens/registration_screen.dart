import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../../customer_screens/daytimeSelection.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String role = 'customer';
  bool _isLoading = false;

  // Form-specific fields
  String firstName = '';
  String lastName = '';
  String address = '';
  String phoneNumber = '';
  String postalCode = '';
  String nic = '';
  String city = '';
  String vehicleDetails = '';

  // List of Sri Lankan cities for the dropdown
  final List<String> _sriLankanCities = [
    'Colombo',
    'Kandy',
    'Galle',
    'Gampaha',
    'Jaffna',
    'Matara',
    'Trincomalee',
    'Ratnapura',
    'Badulla',
    'Kurunegala',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = await _authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        await user.sendEmailVerification();
        await _saveUserDetails(user);

        await FirebaseAuth.instance.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registration successful. Please verify your email before logging in.',
              ),
            ),
          );

          // Navigate to DayTimeSelectionPage only for customers
          if (role == 'customer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DayTimeSelectionPage(userId: user.uid),
              ),
            );
          } else {
            _navigateToHome(); // Navigate to the appropriate home page for other roles
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUserDetails(User user) async {
    // Save common user details
    await _firestore.collection('users').doc(user.uid).set({
      'email': _emailController.text.trim(),
      'role': role,
      'verified': false,
      'created_at': FieldValue.serverTimestamp(),
      'first_time': true,
    });

    // Additional logic based on user role
    if (role == 'customer') {
      await _firestore.collection('users').doc(user.uid).update({
        'first_name': firstName,
        'last_name': lastName,
        'address': address,
        'phone_number': phoneNumber,
        'postal_code': postalCode,
        'nic_no': nic,
        'city': city,
      });
    } else if (role == 'garbage_collector') {
      await _firestore.collection('users').doc(user.uid).update({
        'name': '$firstName $lastName',
        'phone_number': phoneNumber,
        'vehicle_details': vehicleDetails,
        'nic_no': nic,
        'collector_address': address,
        'collector_city': city,
        'collector_postal_code': postalCode,
      });
    } else if (role == 'admin') {
      await _firestore.collection('users').doc(user.uid).update({
        'name': '$firstName $lastName',
      });
    }
  }

  void _navigateToHome() {
    String route = '/';
    if (role == 'customer') {
      route = '/customerHome';
    } else if (role == 'garbage_collector') {
      route = '/garbageCollectorHome';
    } else if (role == 'admin') {
      route = '/adminHome';
    }

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10.0,
        title: Text(
          'REGISTER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black26,
                offset: Offset(3, 3),
              ),
            ],
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.yellow[700]!, Colors.orange[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/pic3.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : Center(
                    child: SingleChildScrollView(
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Container(
                            padding: EdgeInsets.all(24.0),
                            margin: EdgeInsets.only(
                                top: 50), // Brings the form down
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10.0,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 40), // Space for the logo
                                  _buildRoleSelection(), // Updated role selection
                                  SizedBox(
                                      height:
                                          24.0), // Added space between buttons and form
                                  _buildForm(),
                                  SizedBox(height: 24.0),
                                  buildButton(
                                      context, 'Register', registerUser),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  12), // Rounded corners for the logo
                              child: Image.asset(
                                'assets/images/pic15.png',
                                height: 90,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged ?? (value) {},
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20), // Rounded corners
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Email',
          icon: Icons.email,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
                .hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        SizedBox(height: 16.0),
        _buildTextField(
          label: 'Password',
          icon: Icons.lock,
          controller: _passwordController,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters long';
            }
            if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{6,}$')
                .hasMatch(value)) {
              return 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
            }
            return null;
          },
        ),
        SizedBox(height: 16.0),
        _buildTextField(
          label: 'Confirm Password',
          icon: Icons.lock,
          controller: _confirmPasswordController,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        SizedBox(height: 16.0),

        // Common fields for all roles
        _buildTextField(
          label: 'First Name',
          icon: Icons.person,
          onChanged: (value) => firstName = value,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your first name';
            }
            return null;
          },
        ),
        SizedBox(height: 16.0),

        // Last Name only for roles other than admin
        if (role != 'admin')
          _buildTextField(
            label: 'Last Name',
            icon: Icons.person,
            onChanged: (value) => lastName = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),

        // Fields specific to garbage collectors and customers
        if (role != 'admin') ...[
          SizedBox(height: 16.0),
          _buildTextField(
            label: 'NIC',
            icon: Icons.badge,
            onChanged: (value) => nic = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your NIC';
              }
              if (!RegExp(r'^[0-9]{9}[vVxX]|[0-9]{12}$').hasMatch(value)) {
                return 'Please enter a valid NIC number';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          _buildTextField(
            label: 'Phone Number',
            icon: Icons.phone,
            onChanged: (value) => phoneNumber = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          _buildTextField(
            label: 'Address',
            icon: Icons.home,
            onChanged: (value) => address = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          DropdownButtonFormField<String>(
            value: city.isEmpty ? null : city,
            icon: Icon(Icons.arrow_downward),
            decoration: InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            items:
                _sriLankanCities.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                city = newValue!;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your city';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),
          _buildTextField(
            label: 'Postal Code',
            icon: Icons.markunread_mailbox,
            onChanged: (value) => postalCode = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your postal code';
              }
              if (!RegExp(r'^\d{5}$').hasMatch(value)) {
                return 'Please enter a valid postal code';
              }
              return null;
            },
          ),
          SizedBox(height: 16.0),

          // Vehicle details only for garbage collectors
          if (role == 'garbage_collector')
            _buildTextField(
              label: 'Vehicle Details',
              icon: Icons.directions_car,
              onChanged: (value) => vehicleDetails = value,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your vehicle details';
                }
                return null;
              },
            ),
        ],
      ],
    );
  }

  Widget buildButton(
      BuildContext context, String label, void Function()? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          backgroundColor: Colors.orange[800],
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return DropdownButtonFormField<String>(
      value: role,
      icon: Icon(Icons.arrow_downward),
      decoration: InputDecoration(
        labelText: 'Select Role',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      items: [
        DropdownMenuItem<String>(
          value: 'customer',
          child: Text('Customer'),
        ),
        DropdownMenuItem<String>(
          value: 'garbage_collector',
          child: Text('Garbage Collector'),
        ),
        DropdownMenuItem<String>(
          value: 'admin',
          child: Text('Admin'),
        ),
      ],
      onChanged: (String? newValue) {
        setState(() {
          role = newValue!;
        });
      },
    );
  }
}
