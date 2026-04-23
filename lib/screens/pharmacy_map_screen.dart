import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:medinutri/services/pharmacy_service.dart';
import 'package:medinutri/services/theme_notifier.dart';
import 'package:url_launcher/url_launcher.dart';

class PharmacyMapScreen extends StatefulWidget {
  const PharmacyMapScreen({super.key});

  @override
  State<PharmacyMapScreen> createState() => _PharmacyMapScreenState();
}

class _PharmacyMapScreenState extends State<PharmacyMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userPosition;
  List<HealthPOI> _pois = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all'; // 'all', 'pharmacy', 'hospital', 'clinic'
  HealthPOI? _selectedPOI;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Activez la localisation pour trouver les pharmacies.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Permission de localisation refusée.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Permission de localisation refusée définitivement.\nAllez dans les paramètres.';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _userPosition = LatLng(position.latitude, position.longitude);
      });

      await _loadPOIs();
    } catch (e) {
      setState(() {
        _error = 'Erreur de localisation: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPOIs() async {
    if (_userPosition == null) return;
    setState(() => _isLoading = true);

    final pois = await PharmacyService.instance.fetchNearbyPOIs(
      lat: _userPosition!.latitude,
      lon: _userPosition!.longitude,
      radiusMeters: 5000,
      filterType: _filter == 'all' ? null : _filter,
    );

    if (mounted) {
      setState(() {
        _pois = pois;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Map
          if (_userPosition != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userPosition!,
                initialZoom: 14.5,
                onTap: (tapPosition, point) => setState(() => _selectedPOI = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: isDark
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
                  userAgentPackageName: 'com.medinutri.medinutri',
                ),
                // User position marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userPosition!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                    ),
                    // POI markers
                    ..._pois.map((poi) => Marker(
                      point: LatLng(poi.lat, poi.lon),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPOI = poi),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _poiColor(poi.type),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: _poiColor(poi.type).withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(poi.typeEmoji, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ],
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 64, color: isDark ? Colors.white38 : Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 15)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _initLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),

          // Top bar overlay
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      // Back button
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black54 : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Spacer(),
                      // Title
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black54 : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_pharmacy, color: Color(0xFF0D9488), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_pois.length} point${_pois.length > 1 ? 's' : ''} trouvé${_pois.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Recenter button
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black54 : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.my_location, color: isDark ? Colors.white : Colors.black87),
                          onPressed: () {
                            if (_userPosition != null) {
                              _mapController.move(_userPosition!, 14.5);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Filter chips
                _buildFilterRow(isDark),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading && _userPosition != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black87 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D9488))),
                      SizedBox(width: 10),
                      Text('Recherche en cours...'),
                    ],
                  ),
                ),
              ),
            ),

          // Selected POI detail card
          if (_selectedPOI != null)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: _buildPOICard(_selectedPOI!, isDark)
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .slideY(begin: 0.3, end: 0),
            ),

          // Emergency button
          if (_selectedPOI == null)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: _buildEmergencyBar(isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'Tout', 'emoji': '📍'},
      {'key': 'pharmacy', 'label': 'Pharmacies', 'emoji': '💊'},
      {'key': 'hospital', 'label': 'Hôpitaux', 'emoji': '🏥'},
      {'key': 'clinic', 'label': 'Cliniques', 'emoji': '🏨'},
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: filters.map((f) {
          final isSelected = _filter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _filter = f['key']!);
                _loadPOIs();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? const LinearGradient(colors: ThemeNotifier.primaryGradient) : null,
                  color: isSelected ? null : (isDark ? Colors.black54 : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(f['emoji']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(f['label']!, style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700]),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPOICard(HealthPOI poi, bool isDark) {
    final color = _poiColor(poi.type);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(poi.typeEmoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(poi.name, style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    )),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(poi.typeLabel, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        if (poi.distanceLabel.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.near_me, size: 12, color: isDark ? Colors.white38 : Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(poi.distanceLabel, style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 12,
                          )),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _selectedPOI = null),
              ),
            ],
          ),
          if (poi.address != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.white38 : Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(child: Text(poi.address!, style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 12,
                ))),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              // Directions button
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(colors: ThemeNotifier.primaryGradient),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _openDirections(poi.lat, poi.lon),
                    icon: const Icon(Icons.directions, color: Colors.white, size: 18),
                    label: const Text('Itinéraire', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              if (poi.phone != null) ...[
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.phone, color: Color(0xFF10B981)),
                    onPressed: () => _callPhone(poi.phone!),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.emergency, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Urgence', style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          )),
          const Spacer(),
          _emergencyButton('SAMU', '190', Colors.redAccent),
          const SizedBox(width: 8),
          _emergencyButton('Pompiers', '198', Colors.orange),
          const SizedBox(width: 8),
          _emergencyButton('Police', '197', const Color(0xFF3B82F6)),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _emergencyButton(String label, String number, Color color) {
    return GestureDetector(
      onTap: () => _callPhone(number),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
      ),
    );
  }

  Color _poiColor(String type) => switch (type) {
    'pharmacy' => const Color(0xFF10B981),
    'hospital' => const Color(0xFFEF4444),
    'clinic' => const Color(0xFF3B82F6),
    'doctors' => const Color(0xFF8B5CF6),
    _ => const Color(0xFF0D9488),
  };

  Future<void> _openDirections(double lat, double lon) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch navigation: $e');
    }
  }

  Future<void> _callPhone(String number) async {
    final url = Uri.parse('tel:${number.replaceAll(' ', '')}');
    try {
      await launchUrl(url);
    } catch (e) {
      debugPrint('Could not launch phone call: $e');
    }
  }
}
