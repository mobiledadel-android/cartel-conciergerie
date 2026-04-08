import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const String _apiKey = 'AIzaSyB-FFBugiGiTKlVX1TenrJwpjaLdrHkM24';

  // Frais de transport fixe
  static const int fixedTransportFee = 2500;

  /// Autocomplete : suggestions d'adresses au Gabon
  Future<List<PlaceSuggestion>> getPlaceSuggestions(String input) async {
    if (input.length < 3) return [];

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(input)}'
      '&components=country:ga'
      '&language=fr'
      '&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body);
    if (data['status'] != 'OK') return [];

    return (data['predictions'] as List)
        .map((p) => PlaceSuggestion(
              placeId: p['place_id'],
              description: p['description'],
            ))
        .toList();
  }

  /// Récupérer les coordonnées d'un lieu par son placeId
  Future<PlaceLocation?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=geometry,formatted_address'
      '&language=fr'
      '&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    if (data['status'] != 'OK') return null;

    final result = data['result'];
    final location = result['geometry']['location'];

    return PlaceLocation(
      lat: location['lat'].toDouble(),
      lng: location['lng'].toDouble(),
      address: result['formatted_address'] ?? '',
    );
  }

  /// Calculer la distance entre deux points via Distance Matrix API
  Future<DistanceResult?> calculateDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
      '?origins=$originLat,$originLng'
      '&destinations=$destLat,$destLng'
      '&language=fr'
      '&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    if (data['status'] != 'OK') return null;

    final element = data['rows'][0]['elements'][0];
    if (element['status'] != 'OK') return null;

    final distanceMeters = element['distance']['value'] as int;
    final durationSeconds = element['duration']['value'] as int;

    return DistanceResult(
      distanceKm: distanceMeters / 1000.0,
      distanceText: element['distance']['text'],
      durationMinutes: (durationSeconds / 60).round(),
      durationText: element['duration']['text'],
    );
  }

  /// Frais de transport fixe
  static int calculateTransportFee() {
    return fixedTransportFee;
  }

  /// Calculer le prix total = prix service + frais transport
  static int calculateTotalPrice(int basePrice) {
    if (basePrice == 0) return 0; // Sur devis
    return basePrice + fixedTransportFee;
  }
}

class PlaceSuggestion {
  final String placeId;
  final String description;

  PlaceSuggestion({required this.placeId, required this.description});
}

class PlaceLocation {
  final double lat;
  final double lng;
  final String address;

  PlaceLocation({required this.lat, required this.lng, required this.address});
}

class DistanceResult {
  final double distanceKm;
  final String distanceText;
  final int durationMinutes;
  final String durationText;

  DistanceResult({
    required this.distanceKm,
    required this.distanceText,
    required this.durationMinutes,
    required this.durationText,
  });
}
