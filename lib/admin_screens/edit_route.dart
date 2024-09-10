import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'select_route_points.dart';

class EditRoutePage extends StatefulWidget {
  final String routeId;
  final Map<String, dynamic> routeData;

  EditRoutePage({required this.routeId, required this.routeData});

  @override
  _EditRoutePageState createState() => _EditRoutePageState();
}

class _EditRoutePageState extends State<EditRoutePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  String? _selectedWasteType;
  List<LatLng> _routePoints = [];
  Set<Marker> _customerMarkers = {};
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _startTimeController =
        TextEditingController(text: widget.routeData['start_time']);
    _endTimeController =
        TextEditingController(text: widget.routeData['end_time']);
    _selectedWasteType = widget.routeData['waste_type'];

    // Convert the points from GeoPoint to LatLng
    var points = widget.routeData['points'] as List<dynamic>;
    _routePoints =
        points.map((p) => LatLng(p['latitude'], p['longitude'])).toList();

    _fetchCustomerLocations();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      final time =
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      controller.text = DateFormat('HH:mm').format(time);
    }
  }

  Future<void> _fetchCustomerLocations() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      Set<Marker> markers = {};

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('current_location')) {
          var location = data['current_location'];
          var lat = location['latitude'];
          var lng = location['longitude'];

          markers.add(Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: doc.id,
              snippet: 'Lat: $lat, Lng: $lng',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
          ));
        }
      }

      setState(() {
        _customerMarkers = markers;
      });
    } catch (e) {
      print("Error fetching customer locations: $e");
    }
  }

  Future<void> _checkLocationPermission() async {
    if (await Permission.location.request().isGranted) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _controller?.animateCamera(CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude)));
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  void _updateRoute() async {
    if (_formKey.currentState!.validate()) {
      String startTime = _startTimeController.text.trim();
      String endTime = _endTimeController.text.trim();
      String wasteType = _selectedWasteType!;

      try {
        await FirebaseFirestore.instance
            .collection('garbage_routes')
            .doc(widget.routeId)
            .update({
          'points': _routePoints
              .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
              .toList(),
          'start_time': startTime,
          'end_time': endTime,
          'waste_type': wasteType,
          'updated_at': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route updated successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectRoutePoints() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectRoutePointsPage()),
    );

    if (result != null && result['route_points'] != null) {
      setState(() {
        _routePoints = result['route_points'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Garbage Collection Route'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _selectRoutePoints,
                child: Text('Select Route Points'),
              ),
              if (_routePoints.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Route Points:'),
                    ..._routePoints
                        .map((point) =>
                            Text('(${point.latitude}, ${point.longitude})'))
                        .toList(),
                  ],
                ),
              Container(
                height: 300,
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target:
                        LatLng(37.7749, -122.4194), // Default to San Francisco
                    zoom: 12,
                  ),
                  markers: _customerMarkers,
                  polylines: {
                    Polyline(
                      polylineId: PolylineId('route'),
                      points: _routePoints,
                      color: Colors.blue,
                      width: 5,
                    )
                  },
                ),
              ),
              TextFormField(
                controller: _startTimeController,
                readOnly: true,
                decoration: InputDecoration(labelText: 'Start Time'),
                onTap: () => _selectTime(context, _startTimeController),
              ),
              TextFormField(
                controller: _endTimeController,
                readOnly: true,
                decoration: InputDecoration(labelText: 'End Time'),
                onTap: () => _selectTime(context, _endTimeController),
              ),
              DropdownButtonFormField<String>(
                value: _selectedWasteType,
                decoration: InputDecoration(labelText: 'Waste Type'),
                items: [
                  DropdownMenuItem(
                    value: 'Electronics',
                    child: Text('Electronics'),
                  ),
                  DropdownMenuItem(
                    value: 'Plastics',
                    child: Text('Plastics'),
                  ),
                  DropdownMenuItem(
                    value: 'Paper',
                    child: Text('Paper'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedWasteType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a waste type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateRoute,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
