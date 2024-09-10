import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_garbage_profile.dart';
import 'garbage_profile_photo.dart'; // Import the GarbageProfilePhotoPage

class GarbageCollectorProfileSection extends StatefulWidget {
  @override
  _GarbageCollectorProfileDetailsState createState() =>
      _GarbageCollectorProfileDetailsState();
}

class _GarbageCollectorProfileDetailsState
    extends State<GarbageCollectorProfileSection> {
  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void navigateToEditProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditGarbageProfilePage()),
    );
  }

  void navigateToProfilePhotoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GarbageProfilePhotoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Garbage Collector Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                    String? profilePictureUrl = userData['profilePicture'];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Display profile picture at the top
                        if (profilePictureUrl != null)
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(profilePictureUrl),
                          )
                        else
                          CircleAvatar(
                            radius: 50,
                            child: Icon(Icons.person, size: 50),
                          ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: navigateToProfilePhotoPage,
                          child: Text('Change Profile Picture'),
                        ),
                        SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                ListTile(
                                  leading: Icon(Icons.person),
                                  title: Text('Name'),
                                  subtitle: Text(userData['name'] ?? 'N/A'),
                                ),
                                ListTile(
                                  leading: Icon(Icons.phone),
                                  title: Text('Phone Number'),
                                  subtitle:
                                      Text(userData['phone_number'] ?? 'N/A'),
                                ),
                                ListTile(
                                  leading: Icon(Icons.credit_card),
                                  title: Text('NIC Number'),
                                  subtitle: Text(userData['nic_no'] ?? 'N/A'),
                                ),
                                ListTile(
                                  leading: Icon(Icons.home),
                                  title: Text('Address'),
                                  subtitle: Text(
                                      userData['collector_address'] ?? 'N/A'),
                                ),
                                ListTile(
                                  leading: Icon(Icons.location_city),
                                  title: Text('City'),
                                  subtitle:
                                      Text(userData['collector_city'] ?? 'N/A'),
                                ),
                                ListTile(
                                  leading: Icon(Icons.mail),
                                  title: Text('Postal Code'),
                                  subtitle: Text(
                                      userData['collector_postal_code'] ??
                                          'N/A'),
                                ),
                                ListTile(
                                  leading: Icon(Icons.directions_car),
                                  title: Text('Vehicle Details'),
                                  subtitle: Text(
                                      userData['vehicle_details'] ?? 'N/A'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: navigateToEditProfilePage,
                  icon: Icon(Icons.edit),
                  label: Text('Edit Details'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: logout,
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: Colors.red,
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
