import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'garbage_collector_map.dart';
import 'garbage_collector_route_navigation.dart';

class GarbageCollectionRoutes extends StatefulWidget {
  @override
  _GarbageCollectionRoutesState createState() =>
      _GarbageCollectionRoutesState();
}

class _GarbageCollectionRoutesState extends State<GarbageCollectionRoutes> {
  LatLng? _collectorLocation;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  // Fetch the current user ID and location
  Future<void> _fetchCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      // Fetch the collector's location from Firestore
      _fetchCollectorLocation(user.uid);
    }
  }

  // Fetch the collector's location from Firestore
  Future<void> _fetchCollectorLocation(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc['location'] != null) {
        GeoPoint location = userDoc['location'];
        setState(() {
          _collectorLocation = LatLng(location.latitude, location.longitude);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch location.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching location: $e')),
        );
      }
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
          point1.latitude,
          point1.longitude,
          point2.latitude,
          point2.longitude,
        ) /
        1000; // Convert distance to kilometers
  }

  bool _isRouteAvailableThisWeek(DateTime lastCompletedDate) {
    final now = DateTime.now();
    return now.difference(lastCompletedDate).inDays >= 7;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Assigned Routes'),
        actions: [
          IconButton(
            icon: Icon(Icons.location_on),
            onPressed: _userId == null
                ? null // Disable the button until userId is available
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetGarbageCollectorMapScreen(
                          userId: _userId!,
                          closestCustomerLocations: const [],
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
      body: _collectorLocation == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('garbage_routes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<DocumentSnapshot> completedRoutes = [];
                List<DocumentSnapshot> uncompletedRoutes = [];

                snapshot.data!.docs.forEach((doc) {
                  final docData = doc.data() as Map<String, dynamic>?;
                  bool isCompleted =
                      (docData != null && docData.containsKey('completed'))
                          ? doc['completed']
                          : false;

                  // Extract the starting point of the route
                  List<LatLng> routePoints = (doc['route_points'] as List)
                      .map((point) =>
                          LatLng(point['latitude'], point['longitude']))
                      .toList();
                  LatLng routeStartPoint = routePoints.first;

                  // Calculate distance from collector's location to route start point
                  double distance =
                      _calculateDistance(_collectorLocation!, routeStartPoint);

                  if (distance <= 1) {
                    // Filter routes within 1 km radius
                    if (docData != null &&
                        docData.containsKey('last_completed')) {
                      DateTime lastCompletedDate =
                          (doc['last_completed'] as Timestamp).toDate();
                      if (_isRouteAvailableThisWeek(lastCompletedDate)) {
                        if (isCompleted) {
                          completedRoutes.add(doc);
                        } else {
                          uncompletedRoutes.add(doc);
                        }
                      }
                    } else {
                      // If no last_completed date is available, consider it as uncompleted
                      uncompletedRoutes.add(doc);
                    }
                  }
                });

                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Uncompleted Routes for This Week',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    ...uncompletedRoutes
                        .map((doc) => buildRouteTile(doc, isCompleted: false))
                        .toList(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Completed Routes for This Week',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    ...completedRoutes
                        .map((doc) => buildRouteTile(doc, isCompleted: true))
                        .toList(),
                  ],
                );
              },
            ),
    );
  }

  Widget buildRouteTile(DocumentSnapshot doc, {required bool isCompleted}) {
    String routeId = doc.id;
    List<LatLng> routePoints = (doc['route_points'] as List)
        .map((point) => LatLng(point['latitude'], point['longitude']))
        .toList();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 3,
      child: ListTile(
        leading: Icon(
          Icons.route,
          color: isCompleted ? Colors.green : Colors.red,
        ),
        title: Text('Route: ${routePoints.length} points',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            'Time: ${doc['start_time']} - ${doc['end_time']}\nWaste Type: ${doc['waste_type']}'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GarbageCollectorRouteNavigationPage(
                routePoints: routePoints,
                onComplete: () async {
                  // Handle route completion here
                  await FirebaseFirestore.instance
                      .collection('garbage_routes')
                      .doc(routeId)
                      .update({
                    'completed': true,
                    'last_completed': DateTime.now()
                  });

                  // Optionally, show a confirmation message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Route marked as completed!')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
