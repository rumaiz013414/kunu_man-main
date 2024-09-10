import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class GarbageBinsScreen extends StatefulWidget {
  @override
  _GarbageBinsScreenState createState() => _GarbageBinsScreenState();
}

class _GarbageBinsScreenState extends State<GarbageBinsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Marker> _binMarkers = [];
  LatLng? _currentLocation;
  late GoogleMapController _mapController;
  Location _location = Location();
  Set<Polyline> _polylines = Set<Polyline>();
  StreamSubscription<LocationData>? _locationSubscription;
  Marker? _customerMarker;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
    _loadBinLocations();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermissions() async {
    final isServiceEnabled = await _location.serviceEnabled();
    if (!isServiceEnabled) {
      final serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    var permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
    }

    _getCurrentLocation();
  }

  void _loadBinLocations() async {
    try {
      final querySnapshot = await _firestore.collection('bin_locations').get();
      if (mounted) {
        setState(() {
          _binMarkers.clear();
          for (var doc in querySnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            _binMarkers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(data['latitude'], data['longitude']),
                infoWindow: InfoWindow(
                  title: 'Bin Location',
                  snippet: 'ID: ${doc.id}',
                  onTap: () {
                    _showRouteToBin(
                        LatLng(data['latitude'], data['longitude']));
                  },
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bin locations: $e')),
        );
      }
    }
  }

  void _getCurrentLocation() async {
    try {
      final locationData = await _location.getLocation();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );

          _customerMarker = Marker(
            markerId: MarkerId('customer'),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(title: 'Your Location'),
          );
        });

        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 14.0),
        );

        // Start a timer to update location every 5 seconds
        _locationUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) {
          _updateLocation();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting current location: $e')),
        );
      }
    }
  }

  void _updateLocation() async {
    try {
      final locationData = await _location.getLocation();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );

          _customerMarker = Marker(
            markerId: MarkerId('customer'),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(title: 'Your Location'),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating location: $e')),
        );
      }
    }
  }

  void _showRouteToBin(LatLng binLocation) async {
    if (_currentLocation == null) return;

    final directionsUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&'
        'destination=${binLocation.latitude},${binLocation.longitude}&');

    try {
      final response = await http.get(directionsUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routePoints =
            _decodePolyline(data['routes'][0]['overview_polyline']['points']);

        final polyline = Polyline(
          polylineId: PolylineId('route'),
          points: routePoints,
          color: Colors.blue,
          width: 5,
        );

        if (mounted) {
          setState(() {
            _polylines = {polyline};
          });

          _mapController.animateCamera(
            CameraUpdate.newLatLngBounds(
              _getLatLngBounds(_currentLocation!, binLocation),
              50,
            ),
          );
        }
      } else {
        throw Exception('Failed to fetch directions');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error showing route: $e')),
        );
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  LatLngBounds _getLatLngBounds(LatLng origin, LatLng destination) {
    return LatLngBounds(
      southwest: LatLng(
        min(origin.latitude, destination.latitude),
        min(origin.longitude, destination.longitude),
      ),
      northeast: LatLng(
        max(origin.latitude, destination.latitude),
        max(origin.longitude, destination.longitude),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'GARBAGE COLLECTION BINS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: Colors.black26,
                  offset: Offset(3, 3),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.yellow[700],
        elevation: 10.0,
        shadowColor: Colors.yellow[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.greenAccent,
                  width: 3.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(6.9271, 79.8612),
                    zoom: 12.0,
                  ),
                  markers: Set<Marker>.of(_binMarkers)
                    ..addAll(_customerMarker != null ? [_customerMarker!] : []),
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;

                    if (_currentLocation != null) {
                      _mapController.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentLocation!, 14.0),
                      );
                    }
                  },
                ),
              ),
            ),
            if (_currentLocation == null)
              Center(child: CircularProgressIndicator()),

            // Instructions Container
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Tap on a garbage bin location and click the "Get Directions" icon to get directions.',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // GPS button to manually get the current location
            Positioned(
              bottom: 100,
              right: 20,
              child: FloatingActionButton(
                onPressed: _getCurrentLocation,
                backgroundColor: Colors.yellow[700],
                child: Icon(Icons.my_location),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
