import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'customer_subscription.dart';

class DayTimeSelectionPage extends StatefulWidget {
  final String userId;

  DayTimeSelectionPage({required this.userId});

  @override
  _DayTimeSelectionPageState createState() => _DayTimeSelectionPageState();
}

class _DayTimeSelectionPageState extends State<DayTimeSelectionPage> {
  final Map<String, TimeOfDay?> selectedDays = {
    'Monday': null,
    'Tuesday': null,
    'Wednesday': null,
    'Thursday': null,
    'Friday': null,
    'Saturday': null,
    'Sunday': null,
  };

  final int maxSelections = 3;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  LatLng _selectedLocation = LatLng(37.42796133580664, -122.085749655962);

  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _trackLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _selectTime(String day) async {
    if (_getSelectedCount() >= maxSelections && selectedDays[day] == null) {
      _showMaxSelectionAlert();
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (pickedTime != null &&
        ((pickedTime.hour >= 8 && pickedTime.hour < 10) ||
            (pickedTime.hour >= 15 && pickedTime.hour < 17))) {
      setState(() {
        selectedDays[day] = pickedTime;
      });
    } else if (pickedTime != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Please Select A Time Between 8 AM - 10 AM or 3 PM - 5 PM')),
      );
    }
  }

  void _deselectTime(String day) {
    setState(() {
      selectedDays[day] = null;
    });
  }

  int _getSelectedCount() {
    return selectedDays.values.where((time) => time != null).length;
  }

  void _showMaxSelectionAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You Can Only Select Up To 3 Time Slots')),
    );
  }

  Future<void> _saveSelection() async {
  // Check if the user has selected exactly 3 days and times
  if (_getSelectedCount() != maxSelections) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please select exactly 3 days and times.')),
    );
    return;
  }

  Map<String, String> dayTimePreferences = {};

  selectedDays.forEach((day, time) {
    if (time != null) {
      dayTimePreferences[day] = time.format(context);
    }
  });

  try {
    await _firestore.collection('users').doc(widget.userId).update({
      'day_time_preferences': dayTimePreferences,
      'location':
          GeoPoint(_selectedLocation.latitude, _selectedLocation.longitude),
      'location_timestamp': FieldValue.serverTimestamp(),
    });

    // Navigate to the next screen only after successful saving
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionPage(
          userId: widget.userId,
          userName: '',
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save preferences: $e')),
    );
  }
}

  void _trackLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _updateLocation(LatLng(position.latitude, position.longitude));
    });
  }

  void _updateLocation(LatLng newLocation) {
    setState(() {
      _selectedLocation = newLocation;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId('currentLocation'),
          position: _selectedLocation,
          infoWindow: InfoWindow(title: 'Current Location'),
        ),
      );

      _mapController.animateCamera(
        CameraUpdate.newLatLng(_selectedLocation),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10.0,
        title: Text(
          'Select Days & Time Slots',
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
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.yellow[700]!, Colors.orange[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/pic3.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    color: Colors.orange[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Instructions:\n'
                        '1. You can select up to 3 days and 3 time slots.\n'
                        '2. Time slots must be between 8 AM - 10 AM or 3 PM - 5 PM.\n'
                        '3. To change a selection, tap the selected time again to deselect.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ListView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: selectedDays.keys.map((String day) {
                      return Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(day),
                          trailing: selectedDays[day] != null
                              ? IconButton(
                                  icon: Icon(Icons.mark_chat_read_outlined,
                                      color: const Color.fromARGB(
                                          255, 54, 244, 79)),
                                  onPressed: () {
                                    _deselectTime(day);
                                  },
                                )
                              : IconButton(
                                  icon: Icon(Icons.access_time),
                                  onPressed: () {
                                    _selectTime(day);
                                  },
                                ),
                          subtitle: selectedDays[day] != null
                              ? Text(
                                  'Selected time: ${selectedDays[day]!.format(context)}')
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          _trackLocation();
                        },
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation,
                          zoom: 14.0,
                        ),
                        markers: _markers,
                        onTap: (LatLng position) {
                          setState(() {
                            _selectedLocation = position;
                            _markers.clear();
                            _markers.add(
                              Marker(
                                markerId: MarkerId('selectedLocation'),
                                position: _selectedLocation,
                              ),
                            );
                          });
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveSelection,
                    child: Text(
                      'Save Preferences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 5.0,
                            color: Colors.black45,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 10,
                      shadowColor: Colors.black26,
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
