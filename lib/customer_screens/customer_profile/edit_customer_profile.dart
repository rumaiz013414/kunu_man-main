import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditCustomerProfilePage extends StatefulWidget {
  @override
  _EditCustomerProfilePageState createState() =>
      _EditCustomerProfilePageState();
}

class _EditCustomerProfilePageState extends State<EditCustomerProfilePage> {
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _postalCodeController = TextEditingController();
  TextEditingController _nicController = TextEditingController();
  TextEditingController _cityController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _nicController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> updateUserProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone_number': _phoneNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'nic_no': _nicController.text.trim(),
        'city': _cityController.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')));
      Navigator.pop(context); // Navigate back to profile page
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10.0,
        title: Text(
          'EDIT PROFILE',
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
        backgroundColor: Colors.yellow[700],
        shadowColor: Colors.yellow[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow[50]!, Colors.yellow[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('User data not found'));
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            _firstNameController.text = userData['first_name'] ?? '';
            _lastNameController.text = userData['last_name'] ?? '';
            _phoneNumberController.text = userData['phone_number'] ?? '';
            _addressController.text = userData['address'] ?? '';
            _postalCodeController.text = userData['postal_code'] ?? '';
            _nicController.text = userData['nic_no'] ?? '';
            _cityController.text = userData['city'] ?? '';

            return ListView(
              children: [
                _buildProfileImage(),
                _buildTextField('First Name', _firstNameController,
                    icon: Icons.person),
                _buildTextField('Last Name', _lastNameController,
                    icon: Icons.person),
                _buildTextField('Phone Number', _phoneNumberController,
                    icon: Icons.phone),
                _buildTextField('Address', _addressController,
                    icon: Icons.home),
                _buildTextField('Postal Code', _postalCodeController,
                    icon: Icons.post_add),
                _buildTextField('NIC Number', _nicController,
                    icon: Icons.credit_card),
                _buildTextField('City', _cityController,
                    icon: Icons.location_city),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: updateUserProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      padding:
                          EdgeInsets.symmetric(vertical: 16.0, horizontal: 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      elevation: 5,
                      shadowColor: Colors.yellow[300],
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.yellow[700],
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.yellow[800]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              hintStyle: TextStyle(color: Colors.grey[500]),
            ),
            style: TextStyle(color: Colors.grey[800], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
