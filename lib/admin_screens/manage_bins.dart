import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageBinsPage extends StatefulWidget {
  const ManageBinsPage({Key? key}) : super(key: key);

  @override
  _ManageBinsPageState createState() => _ManageBinsPageState();
}

class _ManageBinsPageState extends State<ManageBinsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Marker> _binMarkers = [];
  final LatLng _initialLocation =
      const LatLng(6.9271, 79.8612); // Colombo, Sri Lanka
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _loadBinLocations();
  }

  /// Loads the bin locations from Firestore and updates the markers on the map.
  void _loadBinLocations() async {
    try {
      final querySnapshot = await _firestore.collection('bin_locations').get();

      setState(() {
        _binMarkers.clear();
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          _binMarkers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(data['latitude'], data['longitude']),
              infoWindow:
                  InfoWindow(title: 'Bin Location', snippet: 'ID: ${doc.id}'),
              onTap: () {
                _showDeleteConfirmation(doc.id, data['latitude'],
                    data['longitude']); // Show delete confirmation dialog
              },
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bin locations: $e')),
      );
    }
  }

  /// Adds a new bin location to Firestore and updates the map with a new marker.
  void _addBinLocation(LatLng location) async {
    try {
      final docRef = await _firestore.collection('bin_locations').add({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _binMarkers.add(
          Marker(
            markerId: MarkerId(docRef.id),
            position: location,
            infoWindow: InfoWindow(
                title: 'New Bin Location', snippet: 'ID: ${docRef.id}'),
            onTap: () {
              _showDeleteConfirmation(
                  docRef.id, location.latitude, location.longitude);
            },
          ),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bin location added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding bin location: $e')),
      );
    }
  }

  /// Shows a dialog to confirm the deletion of a bin location.
  void _showDeleteConfirmation(
      String docId, double latitude, double longitude) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Bin Location'),
          content: const Text('Are you sure you want to delete this bin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteBinLocation(docId, latitude, longitude);
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Deletes a bin location from Firestore and removes the marker from the map.
  void _deleteBinLocation(
      String docId, double latitude, double longitude) async {
    try {
      await _firestore.collection('bin_locations').doc(docId).delete();

      setState(() {
        _binMarkers.removeWhere((marker) => marker.markerId.value == docId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bin location deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting bin location: $e')),
      );
    }
  }

  /// Moves the map camera to Colombo, Sri Lanka.
  void _moveToColombo() {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _initialLocation,
          zoom: 14.0, // Adjust zoom level as desired
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bins'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.add_location_alt, color: Colors.yellow[800]),
            title: const Text('Add Bin Location'),
            subtitle: const Text('Tap on the map to add a bin location'),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialLocation,
                zoom: 12.0,
              ),
              markers: Set<Marker>.of(_binMarkers),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              onTap: (LatLng location) {
                _addBinLocation(location);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _moveToColombo,
        backgroundColor: Colors.yellow[700],
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
