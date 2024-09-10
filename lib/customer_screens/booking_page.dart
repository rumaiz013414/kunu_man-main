import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingScreenCustomer extends StatefulWidget {
  @override
  _BookingScreenCustomerState createState() => _BookingScreenCustomerState();
}

class _BookingScreenCustomerState extends State<BookingScreenCustomer> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _wasteQuantity;
  String? _additionalInfo;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  static final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.9271, 79.8612), // Colombo, Sri Lanka coordinates
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    var permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _mapController
              ?.animateCamera(CameraUpdate.newLatLng(_selectedLocation!));
        });
      }
    } else if (permissionStatus.isDenied ||
        permissionStatus.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission is required.')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      if (pickedTime.hour >= 8 && pickedTime.hour <= 17) {
        setState(() {
          _selectedTime = pickedTime;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Please select a time between 8:00 AM and 5:00 PM')),
        );
      }
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  Future<void> _goToUserLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    PermissionStatus permission = await Permission.location.status;
    if (permission.isDenied || permission.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission is denied.')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    LatLng userLatLng = LatLng(position.latitude, position.longitude);

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 15));
  }

  Future<void> _submitBooking() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String userId = user.uid;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('bookings')
              .add({
            'date': _selectedDate?.toIso8601String(),
            'time': _selectedTime?.format(context),
            'waste_quantity': _wasteQuantity,
            'additional_info': _additionalInfo,
            'location': GeoPoint(
                _selectedLocation!.latitude, _selectedLocation!.longitude),
            'status': 'pending', // Set the initial status of the booking
            'created_at': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booking submitted successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book an Appointment',
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Please select your booking details below:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 20),
                _buildBookingDateTimeCard(),
                SizedBox(height: 20),
                _buildLocationSelector(),
                SizedBox(height: 20),
                _buildTextInputFields(),
                SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingDateTimeCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 5,
      shadowColor: Colors.greenAccent,
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.calendar_today,
            title: _selectedDate == null
                ? 'Select Date'
                : '${_selectedDate!.toLocal()}'.split(' ')[0],
            onTap: () => _selectDate(context),
            subtitle: _selectedDate == null
                ? Text(
                    'Date is required',
                    style: TextStyle(color: Colors.red),
                  )
                : null,
          ),
          Divider(color: Colors.greenAccent),
          _buildListTile(
            icon: Icons.access_time,
            title: _selectedTime == null
                ? 'Select Time'
                : _selectedTime!.format(context),
            onTap: () => _selectTime(context),
            subtitle: _selectedTime == null
                ? Text(
                    'Time is required',
                    style: TextStyle(color: Colors.red),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.yellow[800]),
      title: Text(title),
      onTap: onTap,
      subtitle: subtitle,
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.greenAccent,
                  width: 2.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_selectedLocation != null) {
                      _mapController?.animateCamera(
                          CameraUpdate.newLatLng(_selectedLocation!));
                    }
                  },
                  initialCameraPosition: _initialPosition,
                  myLocationEnabled: true,
                  onTap: _onMapTap,
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: MarkerId('selected-location'),
                            position: _selectedLocation!,
                          ),
                        }
                      : {},
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: FloatingActionButton(
                onPressed: _goToUserLocation,
                child: Icon(Icons.my_location),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Waste Quantity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Enter quantity of waste (e.g., 5 kg)',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the waste quantity';
            }
            return null;
          },
          onSaved: (value) {
            _wasteQuantity = value;
          },
        ),
        SizedBox(height: 20),
        Text(
          'Additional Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Enter any additional info',
          ),
          maxLines: 4,
          onSaved: (value) {
            _additionalInfo = value;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _submitBooking,
        child: Text('Submit Booking'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.yellow[700],
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
