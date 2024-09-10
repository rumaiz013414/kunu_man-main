import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:testing/garbage_collector_screens/garbage_collector_routes.dart';
import '../customer_screens/customer_home_routes.dart';
import '../admin_screens/admin_home.dart';
import '../common/authentication_screens/login_screen.dart';


class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          User? user = snapshot.data;
          if (user != null) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: getUserData(user),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasData) {
                  var userData = userSnapshot.data;
                  String? role = userData?['role'];
                  bool firstTime = userData?['first_time'] ?? true;

                   
                    if (role == 'customer') {
                      return CustomerHomePage();
                    } else if (role == 'garbage_collector') {
                      return GarbageCollectorRoutes();
                    } else if (role == 'admin') {
                      return AdminHome();
                    } else {
                      return Center(child: Text('Unknown role'));
                    }
                  
                } else if (userSnapshot.hasError) {
                  return Center(child: Text('Error: ${userSnapshot.error}'));
                }

                return Center(child: Text('User data not found'));
              },
            );
          }
        }

        return LoginPage();
      },
    );
  }

  Future<Map<String, dynamic>?> getUserData(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        print('User document does not exist for uid: ${user.uid}');
        return null;
      }
      return doc.data();
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }
}
