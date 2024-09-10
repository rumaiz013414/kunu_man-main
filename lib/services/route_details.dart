import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> getRouteDetails(
    GeoPoint start, GeoPoint end, String apiKey) async {
  final url =
      'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final legs = route['legs'][0];
        final startAddress = legs['start_address'];
        final endAddress = legs['end_address'];
        final steps =
            legs['steps'].map((step) => step['html_instructions']).toList();
        return {
          'start_address': startAddress,
          'end_address': endAddress,
          'steps': steps,
        };
      } else {
        print('No routes found');
      }
    } else {
      print(
          'Failed to load route details. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching route details: $e');
  }
  return {'start_address': 'Unknown', 'end_address': 'Unknown', 'steps': []};
}
