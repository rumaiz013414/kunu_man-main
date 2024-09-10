import 'package:geocoding/geocoding.dart';

Future<String> getStreetNameFromCoordinates(
    double latitude, double longitude) async {
  try {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      return place.street ?? 'Unknown street';
    } else {
      return 'No address available';
    }
  } catch (e) {
    return 'Error: ${e.toString()}';
  }
}
