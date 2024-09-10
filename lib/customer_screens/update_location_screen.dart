import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpdateLocationScreen extends StatefulWidget {
  @override
  _UpdateLocationScreenState createState() => _UpdateLocationScreenState();
}

class _UpdateLocationScreenState extends State<UpdateLocationScreen> {
  GoogleMapController? _controller;
  LatLng? _customerLocation;
  LatLng? _hoverLocation;
  Set<Polyline> _routePolylines = {};
  Set<Marker> _routeMarkers = {};
  bool _loadingRoutes = false;
  double _radius = 2.0; // Radius in kilometers
  DateTime? _lastUpdated; // Last location update time
  bool _isSaveButtonEnabled =
      false; // To track if the save button should be enabled

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _fetchLastUpdatedTime();
  }

  Future<void> _checkLocationPermission() async {
    if (await Permission.location.request().isGranted) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _customerLocation = LatLng(position.latitude, position.longitude);
          _hoverLocation = _customerLocation;
          _routeMarkers.add(Marker(
            markerId: MarkerId('customer_location'),
            position: _customerLocation!,
            draggable: true,
            onDragEnd: (newPosition) {
              setState(() {
                _hoverLocation = newPosition;
                _isSaveButtonEnabled =
                    true; // Enable the save button when the marker is dragged
              });
            },
          ));
        });
        _controller?.animateCamera(CameraUpdate.newLatLng(_customerLocation!));
        _fetchNearbyRoutes();
      }
    }
  }

  Future<void> _fetchLastUpdatedTime() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          Timestamp? lastUpdatedTimestamp =
              userDoc['last_location_update'] as Timestamp?;
          if (lastUpdatedTimestamp != null) {
            setState(() {
              _lastUpdated = lastUpdatedTimestamp.toDate();
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching last updated time: $e");
    }
  }

  Future<void> _fetchNearbyRoutes() async {
    if (_customerLocation == null) return;

    setState(() {
      _loadingRoutes = true;
    });

    try {
      QuerySnapshot routesSnapshot =
          await FirebaseFirestore.instance.collection('garbage_routes').get();

      Set<Polyline> polylines = {};
      Set<Marker> markers = {};

      for (var doc in routesSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        var points = data['route_points'] as List<dynamic>;
        var routePoints =
            points.map((p) => LatLng(p['latitude'], p['longitude'])).toList();
        var wasteType = data['waste_type'];

        double closestDistance = double.infinity;
        for (var point in routePoints) {
          double distance = Geolocator.distanceBetween(
            _customerLocation!.latitude,
            _customerLocation!.longitude,
            point.latitude,
            point.longitude,
          );
          if (distance < closestDistance) {
            closestDistance = distance;
          }
        }

        if (closestDistance <= _radius * 1000) {
          Color routeColor;
          switch (wasteType) {
            case 'Electronics':
              routeColor = Colors.red;
              break;
            case 'Plastics':
              routeColor = Colors.blue;
              break;
            case 'Paper':
              routeColor = Colors.green;
              break;
            default:
              routeColor = Colors.grey;
              break;
          }

          for (var point in routePoints) {
            markers.add(Marker(
              markerId:
                  MarkerId('${doc.id}_${point.latitude}_${point.longitude}'),
              position: point,
              infoWindow: InfoWindow(title: '$wasteType Route Point'),
            ));
          }

          polylines.add(Polyline(
            polylineId: PolylineId(doc.id),
            points: routePoints,
            color: routeColor,
            width: 5,
          ));
        }
      }

      setState(() {
        _routePolylines = polylines;
        _routeMarkers = markers;
        _loadingRoutes = false;
      });

      _adjustCameraToIncludeRoutes();
    } catch (e) {
      print("Error fetching routes: $e");
      setState(() {
        _loadingRoutes = false;
      });
    }
  }

  void _adjustCameraToIncludeRoutes() {
    if (_routePolylines.isEmpty || _customerLocation == null) return;

    LatLngBounds bounds = _getBoundsForRoutesAndLocation();
    _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _getBoundsForRoutesAndLocation() {
    double north = _customerLocation!.latitude;
    double south = _customerLocation!.latitude;
    double east = _customerLocation!.longitude;
    double west = _customerLocation!.longitude;

    for (var polyline in _routePolylines) {
      for (var point in polyline.points) {
        if (point.latitude > north) north = point.latitude;
        if (point.latitude < south) south = point.latitude;
        if (point.longitude > east) east = point.longitude;
        if (point.longitude < west) west = point.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  Future<void> _saveLocation() async {
    if (_hoverLocation == null) return;

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'saved_location':
              GeoPoint(_hoverLocation!.latitude, _hoverLocation!.longitude),
          'last_location_update': FieldValue.serverTimestamp(),
        });
        setState(() {
          _lastUpdated = DateTime.now();
          _isSaveButtonEnabled = false; // Disable the button after saving
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update location: $e')),
      );
    }
  }

  Future<bool?> _showConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you want to save this location?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _adjustCameraToIncludeRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'UPDATE LOCATION',
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
        ),
        backgroundColor: Colors.yellow[700],
        elevation: 10.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Step 1: Move the marker to your desired location.\n'
              'Step 2: Click on "Save Location" to save your updated location.\n'
              'Note: You can update your location anytime.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: Container(
                height: MediaQuery.of(context).size.height *
                    0.5, // Smaller map height
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.greenAccent, // Green border
                    width: 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _customerLocation ?? LatLng(0, 0),
                      zoom: 15,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    polylines: _routePolylines,
                    markers: _routeMarkers,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaveButtonEnabled
                  ? () async {
                      bool? confirm = await _showConfirmationDialog(context);
                      if (confirm == true) {
                        _saveLocation();
                      }
                    }
                  : null,
              icon: Icon(Icons.save),
              label: Text('Save Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isSaveButtonEnabled ? Colors.yellow[700] : Colors.grey,
                elevation: 5,
                shadowColor: _isSaveButtonEnabled
                    ? Colors.yellow[300]
                    : Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
