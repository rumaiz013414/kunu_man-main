import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_profile_photo.dart';
import 'edit_customer_profile.dart';

class CustomerProfileDetails extends StatefulWidget {
  @override
  _CustomerProfileDetailsState createState() => _CustomerProfileDetailsState();
}

class _CustomerProfileDetailsState extends State<CustomerProfileDetails>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void logout() async {
    bool confirmed = await _showLogoutConfirmationDialog();
    if (confirmed) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<bool> _showLogoutConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible:
              false, // User must tap a button to dismiss the dialog
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirm Logout'),
              content: Text('Are you sure you want to logout?'),
              actions: <Widget>[
                TextButton(
                  child: Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Return false
                  },
                ),
                TextButton(
                  child: Text('Yes'),
                  onPressed: () {
                    Navigator.of(context).pop(true); // Return true
                  },
                ),
              ],
            );
          },
        ) ??
        false; // Return false if the dialog is dismissed by tapping outside
  }

  void navigateToProfilePhotoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomerProfilePhotoPage()),
    );
  }

  void navigateToEditProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditCustomerProfilePage()),
    );
  }

  void cancelSubscription() async {
    bool confirmed = await _showCancelSubscriptionDialog();
    if (confirmed) {
      try {
        var userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'subscriptionStatus': 'Canceled',
            'subscriptionDate': null, // Optional: Reset subscription date
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Subscription canceled successfully.')),
          );

          setState(() {}); // Refresh UI
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error canceling subscription: $e')),
        );
      }
    }
  }

  Future<bool> _showCancelSubscriptionDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Cancel Subscription'),
              content:
                  Text('Are you sure you want to cancel your subscription?'),
              actions: <Widget>[
                TextButton(
                  child: Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Return false
                  },
                ),
                TextButton(
                  child: Text('Yes'),
                  onPressed: () {
                    Navigator.of(context).pop(true); // Return true
                  },
                ),
              ],
            );
          },
        ) ??
        false; // Return false if dialog is dismissed outside
  }

  Map<String, String> _calculateSubscriptionDetails(
      Timestamp? subscriptionDate) {
    if (subscriptionDate == null) return {'status': 'N/A', 'expiration': 'N/A'};

    DateTime startDate = subscriptionDate.toDate();
    DateTime currentDate = DateTime.now();
    Duration duration = currentDate.difference(startDate);

    DateTime expirationDate = startDate.add(Duration(days: 180)); // 6 months

    String status = duration.inDays > 180 ? 'Expired' : 'Active';
    String expiration = expirationDate
        .toLocal()
        .toString()
        .split(' ')[0]; // Date only in YYYY-MM-DD format

    return {'status': status, 'expiration': expiration};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'PROFILE',
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
        backgroundColor: Colors.yellow[700],
        centerTitle: true,
        elevation: 10.0,
        shadowColor: Colors.yellow[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _animation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text('User data not found');
                      }

                      var userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      var subscriptionDetails = _calculateSubscriptionDetails(
                          userData['subscriptionDate'] as Timestamp?);

                      return Column(
                        children: [
                          GestureDetector(
                            onTap: navigateToProfilePhotoPage,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 75,
                                    backgroundImage:
                                        userData['profilePicture'] != null
                                            ? NetworkImage(
                                                userData['profilePicture'])
                                            : null,
                                    child: userData['profilePicture'] == null
                                        ? Icon(Icons.person, size: 75)
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    height: 30,
                                    width: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.yellow[700],
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 5,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(Icons.camera_alt,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: Card(
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              shadowColor: Colors.yellow[200],
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.greenAccent,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Details',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10.0,
                                              color: Colors.grey[400]!,
                                              offset: Offset(2.0, 2.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(color: Colors.yellow[800]),
                                      SizedBox(height: 20),
                                      _buildProfileInfoTile(Icons.email,
                                          'Email', userData['email']),
                                      SizedBox(height: 10),
                                      _buildProfileInfoTile(Icons.person,
                                          'First Name', userData['first_name']),
                                      SizedBox(height: 10),
                                      _buildProfileInfoTile(Icons.person,
                                          'Last Name', userData['last_name']),
                                      SizedBox(height: 10),
                                      _buildProfileInfoTile(Icons.phone,
                                          'Phone', userData['phone_number']),
                                      SizedBox(height: 10),
                                      _buildProfileInfoTile(Icons.home,
                                          'Address', userData['address']),
                                      SizedBox(height: 10),
                                      _buildProfileInfoTile(Icons.location_city,
                                          'City', userData['city']),
                                      SizedBox(height: 10),
                                      _buildProfileInfoTile(
                                          Icons.local_post_office,
                                          'Postal Code',
                                          userData['postal_code']),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: Card(
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              shadowColor: Colors.yellow[200],
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blueAccent,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Subscription',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10.0,
                                              color: Colors.grey[400]!,
                                              offset: Offset(2.0, 2.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(color: Colors.yellow[800]),
                                      SizedBox(height: 20),
                                      _buildProfileInfoTile(
                                          Icons.check_circle,
                                          'Subscription Status',
                                          subscriptionDetails['status']!),
                                      SizedBox(height: 10),
                                      _buildProfileInfoTile(
                                          Icons.calendar_today,
                                          'Expiration Date',
                                          subscriptionDetails['expiration']!),
                                      SizedBox(height: 30),
                                      ElevatedButton.icon(
                                        onPressed: cancelSubscription,
                                        icon: Icon(Icons.cancel),
                                        label: Text('Cancel Subscription'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[600],
                                          elevation: 5,
                                          shadowColor: Colors.red[300],
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 30, vertical: 15),
                                          textStyle: TextStyle(fontSize: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: navigateToEditProfilePage,
                            icon: Icon(Icons.edit),
                            label: Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[700],
                              elevation: 10,
                              shadowColor: Colors.yellow[300],
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              textStyle: TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: logout,
                            icon: Icon(Icons.logout),
                            label: Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              elevation: 10,
                              shadowColor: Colors.red[300],
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              textStyle: TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.yellow[800]),
        SizedBox(width: 20),
        Expanded(
          child: Text(
            '$title: $value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              shadows: [
                Shadow(
                  blurRadius: 5.0,
                  color: Colors.grey[300]!,
                  offset: Offset(2.0, 2.0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
