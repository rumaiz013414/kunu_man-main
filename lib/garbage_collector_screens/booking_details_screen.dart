import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDetailScreen extends StatelessWidget {
  final String userId; // User ID to access the correct user's collection
  final String date;
  final String time;
  final String wasteQuantity;
  final String additionalInfo;
  final LatLng location;
  final String documentId; // Document ID to identify the booking in Firestore
  final String status; // Current status of the booking

  BookingDetailScreen({
    required this.userId,
    required this.date,
    required this.time,
    required this.wasteQuantity,
    required this.additionalInfo,
    required this.location,
    required this.documentId,
    required this.status, // Status is now passed in as a parameter
  });

  Future<void> _completeBooking(BuildContext context) async {
    try {
      // Update the booking document to mark it as completed
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId) // Access the user's document using userId
          .collection('bookings') // Access the 'bookings' subcollection
          .doc(documentId)
          .update({'status': 'completed'}); // Update the booking status to completed

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking marked as completed!')),
      );

      // Optionally, navigate back to the previous screen after completion
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: $date', style: TextStyle(fontSize: 18)),
            Text('Time: $time', style: TextStyle(fontSize: 18)),
            Text('Waste Quantity: $wasteQuantity kg', style: TextStyle(fontSize: 18)),
            Text('Additional Info: $additionalInfo', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text('Status: $status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: status == 'completed' ? Colors.green : Colors.orange)),
            SizedBox(height: 20),
            Text('Collection Location:', style: TextStyle(fontSize: 20)),
            Container(
              height: 300,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: location,
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId('collection_location'),
                    position: location,
                    infoWindow: InfoWindow(
                      title: 'Collection Location',
                      snippet: 'Latitude: ${location.latitude}, Longitude: ${location.longitude}',
                    ),
                  ),
                },
              ),
            ),
            Spacer(), // Push the button to the bottom
            if (status != 'completed') // Only show the button if the status is not completed
              Center(
                child: ElevatedButton(
                  onPressed: () => _completeBooking(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15), backgroundColor: Colors.green[700],
                    textStyle: TextStyle(fontSize: 18), // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // Rounded edges
                    ),
                  ),
                  child: Text('Complete Booking'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
