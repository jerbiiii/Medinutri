import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Represents a point of interest (pharmacy, hospital, etc.)
class HealthPOI {
  final String name;
  final String type; // 'pharmacy', 'hospital', 'clinic'
  final double lat;
  final double lon;
  final String? address;
  final String? phone;
  final String? openingHours;
  final double? distance; // in meters

  HealthPOI({
    required this.name,
    required this.type,
    required this.lat,
    required this.lon,
    this.address,
    this.phone,
    this.openingHours,
    this.distance,
  });

  String get typeLabel => switch (type) {
    'pharmacy' => 'Pharmacie',
    'hospital' => 'Hôpital',
    'clinic' => 'Clinique',
    'doctors' => 'Cabinet médical',
    _ => type,
  };

  String get typeEmoji => switch (type) {
    'pharmacy' => '💊',
    'hospital' => '🏥',
    'clinic' => '🏨',
    'doctors' => '👨‍⚕️',
    _ => '📍',
  };

  String get distanceLabel {
    if (distance == null) return '';
    if (distance! < 1000) return '${distance!.round()} m';
    return '${(distance! / 1000).toStringAsFixed(1)} km';
  }
}

class PharmacyService {
  static final PharmacyService instance = PharmacyService._();
  PharmacyService._();

  /// Query OpenStreetMap Overpass API for health POIs near a location.
  Future<List<HealthPOI>> fetchNearbyPOIs({
    required double lat,
    required double lon,
    double radiusMeters = 5000,
    String? filterType, // null = all, 'pharmacy', 'hospital', 'clinic'
  }) async {
    final radiusStr = radiusMeters.round().toString();

    // Build Overpass query for pharmacies, hospitals, clinics
    String amenityFilter;
    if (filterType != null) {
      amenityFilter = '["amenity"="$filterType"]';
    } else {
      amenityFilter = '["amenity"~"pharmacy|hospital|clinic|doctors"]';
    }

    final query = '''
[out:json][timeout:15];
(
  node$amenityFilter(around:$radiusStr,$lat,$lon);
  way$amenityFilter(around:$radiusStr,$lat,$lon);
);
out center body;
''';

    try {
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {
          'User-Agent': 'MediNutriApp/1.0',
          'Accept': 'application/json',
        },
        body: {'data': query},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        debugPrint('[PharmacyService] Overpass API error: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body);
      final elements = data['elements'] as List? ?? [];

      final pois = <HealthPOI>[];
      for (final el in elements) {
        final tags = el['tags'] as Map<String, dynamic>? ?? {};
        final elLat = (el['lat'] ?? el['center']?['lat']) as double?;
        final elLon = (el['lon'] ?? el['center']?['lon']) as double?;
        if (elLat == null || elLon == null) continue;

        final name = tags['name'] as String? ??
            tags['name:fr'] as String? ??
            tags['name:ar'] as String? ??
            _defaultName(tags['amenity'] as String? ?? 'unknown');

        final type = tags['amenity'] as String? ?? 'pharmacy';
        final dist = _haversineDistance(lat, lon, elLat, elLon);

        pois.add(HealthPOI(
          name: name,
          type: type,
          lat: elLat,
          lon: elLon,
          address: tags['addr:street'] as String? ?? tags['addr:full'] as String?,
          phone: tags['phone'] as String? ?? tags['contact:phone'] as String?,
          openingHours: tags['opening_hours'] as String?,
          distance: dist,
        ));
      }

      // Sort by distance
      pois.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
      return pois;
    } catch (e) {
      debugPrint('[PharmacyService] Error: $e');
      return [];
    }
  }

  String _defaultName(String amenity) => switch (amenity) {
    'pharmacy' => 'Pharmacie',
    'hospital' => 'Hôpital',
    'clinic' => 'Clinique',
    'doctors' => 'Cabinet médical',
    _ => 'Point de santé',
  };

  /// Haversine formula to calculate distance between two coordinates in meters.
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;
}
