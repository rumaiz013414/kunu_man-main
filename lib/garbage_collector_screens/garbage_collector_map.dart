import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SetGarbageCollectorMapScreen extends StatefulWidget {
  final String userId; // Receive the userId for the specific garbage collector

  SetGarbageCollectorMapScreen({required this.userId, required List<LatLng> closestCustomerLocations}); // Constructor to accept the userId

  @override
  _SetGarbageCollectionScreenState createState() => _SetGarbageCollectionScreenState();
}

class _SetGarbageCollectionScreenState extends State<SetGarbageCollectorMapScreen> {
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  Set<Polyline> _routes = {}; // To store the routes

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _fetchRoutes(); // Fetch the routes from Firestore
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied.')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _selectedPosition = _currentPosition;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get current location.')),
        );
      }
    }
  }

  Future<void> _fetchRoutes() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('garbage_routes')
          .get(); // Fetch garbage routes

      Set<Polyline> routePolylines = {};

      for (var doc in snapshot.docs) {
        List<LatLng> routePoints = (doc['route_points'] as List)
            .map((point) => LatLng(point['latitude'], point['longitude']))
            .toList();

        // Create a polyline for each route
        Polyline routePolyline = Polyline(
          polylineId: PolylineId(doc.id),
          points: routePoints,
          color: Colors.blue, // You can set different colors based on conditions
          width: 5,
        );

        routePolylines.add(routePolyline);
      }

      if (mounted) {
        setState(() {
          _routes = routePolylines;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch routes: $e')),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {}

  void _onMapTapped(LatLng position) {
    if (mounted) {
      setState(() {
        _selectedPosition = position;
      });
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedPosition != null) {
      try {
        // Save the selected location for the specific garbage collector
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({
          'location': GeoPoint(_selectedPosition!.latitude, _selectedPosition!.longitude),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update location: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Location & View Routes'),
      ),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 14.0,
                  ),
                  onTap: _onMapTapped,
                  markers: _selectedPosition != null
                      ? {
                          Marker(
                            markerId: MarkerId('selected-location'),
                            position: _selectedPosition!,
                          )
                        }
                      : {},
                  polylines: _routes, // Add the routes to the map
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _saveLocation,
                    child: Text('Save Location'),
                  ),
                ),
              ],
            ),
    );
  }
}
