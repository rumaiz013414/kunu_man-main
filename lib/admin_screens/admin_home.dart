import 'package:flutter/material.dart';
import './manage_garbage_routes.dart';
import 'manage_customers.dart';
import 'manage_feedback_screen.dart';
import 'manage_garbage_collectors.dart';
import 'manage_bins.dart';
import 'add_news.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHome extends StatefulWidget {
  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _garbageRoutesStream;
  late Stream<QuerySnapshot> _customersStream;
  late Stream<QuerySnapshot> _garbageCollectorsStream;
  late Stream<QuerySnapshot> _feedbackStream;
  late Stream<QuerySnapshot> _binsStream;
  late Stream<QuerySnapshot> _newsStream;
  String? adminName;

  @override
  void initState() {
    super.initState();
    _garbageRoutesStream = _firestore.collection('garbage_routes').snapshots();
    _customersStream = _firestore
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .snapshots();
    _garbageCollectorsStream = _firestore
        .collection('users')
        .where('role', isEqualTo: 'garbage_collector')
        .snapshots();
    _feedbackStream = _firestore.collection('feedback').snapshots();
    _binsStream = _firestore.collection('bin_locations').snapshots();
    _newsStream = _firestore.collection('latest_news').snapshots();
    _fetchAdminName();
  }

  Future<void> _fetchAdminName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot adminSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          adminName = adminSnapshot[
              'name']; // Assumes 'name' field exists in admin data
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up resources or streams if necessary
    super.dispose();
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsTile(
      IconData icon, String title, Stream<QuerySnapshot> stream, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final count = snapshot.data?.docs.length ?? 0;

        return Card(
          margin: const EdgeInsets.all(8.0),
          color: color,
          child: Container(
            padding: const EdgeInsets.all(12.0), // Adjusted padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.white), // Reduced icon size
                const SizedBox(
                    height: 6), // Reduced space between icon and text
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14, // Reduced font size
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                    height: 6), // Reduced space between title and count
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28, // Reduced font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.yellow[700],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white, // Changed drawer background color to white
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color:
                      Colors.white, // Changed header background color to white
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      adminName != null ? 'Welcome, $adminName!' : 'Welcome!',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.route, color: Colors.yellow[800]),
                title: const Text('Manage Routes'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ManageGarbageRoutesPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.people, color: Colors.yellow[800]),
                title: const Text('Manage Customers'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ViewCustomersPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.person, color: Colors.yellow[800]),
                title: const Text('Manage Garbage Collectors'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ViewGarbageCollectorsPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.yellow[800]),
                title: const Text('Manage Bins'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ManageBinsPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.new_releases, color: Colors.yellow[800]),
                title: const Text('Upload Latest News'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UploadLatestNewsPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.feedback, color: Colors.yellow[800]),
                title: const Text('Manage Feedback'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ManageFeedbackScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                onTap: () {
                  _logout(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: Colors.white, // Changed body background color to white
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GridView(
                shrinkWrap: true, // Ensures GridView takes up only needed space
                physics:
                    NeverScrollableScrollPhysics(), // Disables GridView scrolling
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                children: [
                  _buildAnalyticsTile(Icons.route, 'Garbage Routes',
                      _garbageRoutesStream, Colors.blue),
                  _buildAnalyticsTile(Icons.people, 'Customers',
                      _customersStream, Colors.green),
                  _buildAnalyticsTile(Icons.person, 'Garbage Collectors',
                      _garbageCollectorsStream, Colors.orange),
                  _buildAnalyticsTile(Icons.feedback, 'Feedback Entries',
                      _feedbackStream, Colors.red),
                  _buildAnalyticsTile(
                      Icons.delete_outline, 'Bins', _binsStream, Colors.purple),
                  _buildAnalyticsTile(Icons.new_releases, 'News Entries',
                      _newsStream, Colors.teal),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
