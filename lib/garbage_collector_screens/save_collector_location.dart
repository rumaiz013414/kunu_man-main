import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<void> saveCollectorLocation(LatLng selectedPosition) async {
  String? uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid != null) {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.update({
          'location': GeoPoint(selectedPosition.latitude, selectedPosition.longitude),
        });
      } else {
        await docRef.set({
          'location': GeoPoint(selectedPosition.latitude, selectedPosition.longitude),
        });
      }
    } catch (e) {
      // Handle any errors here
      throw Exception('Failed to save location.');
    }
  } else {
    throw Exception('User not logged in.');
  }
}
