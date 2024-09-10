import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GarbageCollectorRouteNavigationPage extends StatefulWidget {
  final List<LatLng> routePoints;

  GarbageCollectorRouteNavigationPage(
      {required this.routePoints, required Future<void> Function() onComplete});

  @override
  _GarbageCollectorRouteNavigationPageState createState() =>
      _GarbageCollectorRouteNavigationPageState();
}

class _GarbageCollectorRouteNavigationPageState
    extends State<GarbageCollectorRouteNavigationPage> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Map<LatLng, bool> _pointCompletionStatus = {};
  bool _routeCompleted = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _setRoute();
    _getLiveLocation(); // Fetch live location
  }

  // Set the route and markers on the map
  void _setRoute() {
    if (widget.routePoints.isNotEmpty) {
      final routePoints = widget.routePoints;

      for (LatLng point in routePoints) {
        _pointCompletionStatus[point] = false;
      }

      final bounds = _createLatLngBounds(routePoints);

      final polyline = Polyline(
        polylineId: PolylineId('route'),
        points: routePoints,
        color: Colors.blue,
        width: 5,
      );

      _updateMarkers(); // Update markers with initial completion status

      setState(() {
        _polylines.add(polyline);
      });

      WidgetsBinding.instance!.addPostFrameCallback((_) {
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      });
    }
  }

  // Fetch the live location of the garbage collector
  void _getLiveLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return; // Location services are not enabled
    }

    // Request location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return; // Permissions are denied forever
      }
    }

    // Start listening for live location updates
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentPosition = position;
        _updateLiveLocationMarker();
      });
    });
  }

  // Update the map with the garbage collector's live location
  void _updateLiveLocationMarker() {
    if (_currentPosition != null) {
      LatLng currentLatLng =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _markers.add(
        Marker(
          markerId: MarkerId('live_location'),
          position: currentLatLng,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Your Location'),
        ),
      );
      _mapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));
    }
  }

  LatLngBounds _createLatLngBounds(List<LatLng> points) {
    double x0, x1, y0, y1;
    x0 = x1 = points[0].latitude;
    y0 = y1 = points[0].longitude;

    for (LatLng point in points) {
      if (point.latitude > x1) x1 = point.latitude;
      if (point.latitude < x0) x0 = point.latitude;
      if (point.longitude > y1) y1 = point.longitude;
      if (point.longitude < y0) y0 = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(x0, y0),
      northeast: LatLng(x1, y1),
    );
  }

  // Update markers based on completion status
  void _updateMarkers() {
    _markers.clear();
    widget.routePoints.forEach((point) {
      _markers.add(Marker(
        markerId: MarkerId('${point.latitude},${point.longitude}'),
        position: point,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _pointCompletionStatus[point] == true
              ? BitmapDescriptor.hueBlue
              : BitmapDescriptor.hueRed,
        ),
        onTap: () => _onMarkerTapped(point),
      ));
    });
  }

  // Handle marker tap
  // Handle marker tap with 50 meter radius distance check
  void _onMarkerTapped(LatLng point) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to fetch your current location.')),
      );
      return;
    }

    // Calculate the distance between the current location and the marker point
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      point.latitude,
      point.longitude,
    );

    // Check if the distance is within 50 meters
    if (distance <= 50) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Mark Collection Point'),
            content: Text('Mark this point as completed?'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _pointCompletionStatus[point] = true;
                  });
                  Navigator.of(context).pop();
                  _updateMarkers();
                  _checkIfRouteCompleted();
                },
                child: Text('Completed'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _pointCompletionStatus[point] = false;
                  });
                  Navigator.of(context).pop();
                  _updateMarkers();
                },
                child: Text('Not Completed'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'You must be within 50 meters of the marker to complete it.')),
      );
    }
  }

  // Check if the entire route is completed
  void _checkIfRouteCompleted() {
    bool allPointsCompleted =
        _pointCompletionStatus.values.every((status) => status);

    if (allPointsCompleted) {
      setState(() {
        _routeCompleted = true;
      });
    }
  }

  // Mark the route as completed and save it for 7 days
  void _markRouteAsCompleted() async {
    await FirebaseFirestore.instance.collection('completed_routes').add({
      'route_points': widget.routePoints
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'completed_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Route has been successfully completed!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Garbage Collection Route'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: widget.routePoints.isNotEmpty
                    ? widget.routePoints[0]
                    : LatLng(0, 0),
                zoom: 14.0,
              ),
              polylines: _polylines,
              markers: _markers,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _routeCompleted
                  ? () {
                      _markRouteAsCompleted();
                    }
                  : null,
              child: Text('Complete Route'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _routeCompleted ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
