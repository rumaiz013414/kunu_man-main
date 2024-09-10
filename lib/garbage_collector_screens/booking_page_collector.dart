import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'booking_details_screen.dart'; // Import the BookingDetailScreen

class BookingListScreenCollector extends StatefulWidget {
  @override
  _BookingListScreenCollectorState createState() =>
      _BookingListScreenCollectorState();
}

class _BookingListScreenCollectorState
    extends State<BookingListScreenCollector> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchBookings() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Fetch bookings from Firestore
        QuerySnapshot<Map<String, dynamic>> snapshot =
            await _firestore.collectionGroup('bookings').get();

        // Return the data as a list of maps
        return snapshot.docs.map((doc) {
          return doc.data()
            ..['documentId'] = doc.id
            ..['userId'] = doc.reference.parent.parent?.id;
        }).toList();
      }
    } catch (e) {
      print('Error fetching bookings: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBookings(),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No bookings found.'));
          } else {
            // Separate bookings by status
            List<Map<String, dynamic>> completedBookings = snapshot.data!
                .where((booking) => booking['status'] == 'completed')
                .toList();
            List<Map<String, dynamic>> uncompletedBookings = snapshot.data!
                .where((booking) => booking['status'] != 'completed')
                .toList();

            return ListView(
              children: [
                if (uncompletedBookings.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Uncompleted Bookings',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...uncompletedBookings.map((booking) {
                    GeoPoint? geoPoint = booking['location'];
                    LatLng? location;
                    if (geoPoint != null) {
                      location = LatLng(geoPoint.latitude, geoPoint.longitude);
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(Icons.event_note),
                        title: Text('Date: ${booking['date']}'),
                        subtitle: Text(
                            'Time: ${booking['time']}\nWaste Quantity: ${booking['waste_quantity']} kg\nAdditional Info: ${booking['additional_info']}\nStatus: ${booking['status']}'),
                        onTap: () {
                          if (location != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingDetailScreen(
                                  date: booking['date'],
                                  time: booking['time'],
                                  wasteQuantity: booking['waste_quantity'],
                                  additionalInfo: booking['additional_info'],
                                  location: location!,
                                  documentId: booking['documentId'],
                                  userId: booking['userId'],
                                  status: booking['status'] ?? 'unknown',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Location data is not available for this booking.'),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                ],
                if (completedBookings.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Completed Bookings',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...completedBookings.map((booking) {
                    GeoPoint? geoPoint = booking['location'];
                    LatLng? location;
                    if (geoPoint != null) {
                      location = LatLng(geoPoint.latitude, geoPoint.longitude);
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(Icons.event_note),
                        title: Text('Date: ${booking['date']}'),
                        subtitle: Text(
                            'Time: ${booking['time']}\nWaste Quantity: ${booking['waste_quantity']} kg\nAdditional Info: ${booking['additional_info']}\nStatus: ${booking['status']}'),
                        onTap: () {
                          if (location != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingDetailScreen(
                                  date: booking['date'],
                                  time: booking['time'],
                                  wasteQuantity: booking['waste_quantity'],
                                  additionalInfo: booking['additional_info'],
                                  location: location!,
                                  documentId: booking['documentId'],
                                  userId: booking['userId'],
                                  status: booking['status'] ?? 'unknown',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Location data is not available for this booking.'),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                ],
              ],
            );
          }
        },
      ),
    );
  }
}
