import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/mesh_service.dart';

class TacticalMapView extends StatefulWidget {
  const TacticalMapView({super.key});

  @override
  State<TacticalMapView> createState() => _TacticalMapViewState();
}

class _TacticalMapViewState extends State<TacticalMapView> {
  final MapController _mapController = MapController();
  final MeshService _mesh = MeshService();
  
  LatLng _currentLocation = const LatLng(34.0522, -118.2437); // Default: LA
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStream;
  Timer? _broadcastTimer;

  @override
  void initState() {
    super.initState();
    _initLocation();
    
    // Listen for peer changes to refresh markers
    _mesh.onDevicesChanged = () {
      if (mounted) setState(() {});
    };

    // Periodic location broadcast to peers
    _broadcastTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _mesh.broadcastLocation(_currentLocation.latitude, _currentLocation.longitude);
    });
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }

    // Get current
    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _mapController.move(_currentLocation, 15);
    }

    // Stream updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _broadcastTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "MISSION MAP",
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, 
            color: isDark ? Colors.white : AppColors.lightTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 🗺 THE MAP ENGINE
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15,
              maxZoom: 18,
              minZoom: 3,
            ),
            children: [
              // 🌑 TACTICAL DARK TILES
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                retinaMode: true,
                userAgentPackageName: 'com.sirenzero.app',
              ),
              
              // 📍 MARKER LAYER
              MarkerLayer(
                markers: [
                  // 🟢 YOU ARE HERE
                  Marker(
                    point: _currentLocation,
                    width: 80,
                    height: 80,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location_rounded, 
                          color: Color(0xFF38BDF8), size: 28),
                      ).animate(onPlay: (controller) => controller.repeat())
                       .shimmer(duration: 2000.ms, color: Colors.white, stops: [0, 0.5, 1])
                       .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 1200.ms, curve: Curves.easeInOut),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 📡 SCANNING OVERLAY (Subtle)
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
            ),

          // 📐 TACTICAL UI OVERLAYS
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              children: [
                _buildMapControl(Icons.add, () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                }),
                const SizedBox(height: 12),
                _buildMapControl(Icons.remove, () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                }),
                const SizedBox(height: 12),
                _buildMapControl(Icons.gps_fixed, () {
                  _mapController.move(_currentLocation, 15);
                }),
              ],
            ),
          ),

          // 🧭 COORDINATE BAR
          Positioned(
            top: 100,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCoordLine("LAT", _currentLocation.latitude.toStringAsFixed(6)),
                  _buildCoordLine("LNG", _currentLocation.longitude.toStringAsFixed(6)),
                  const SizedBox(height: 4),
                  Text("OFFLINE MODE ACTIVE", 
                    style: TextStyle(color: AppColors.safeGreen, fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
            ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white70, size: 24),
      ),
    );
  }

  Widget _buildCoordLine(String label, String value) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
      ],
    );
  }
}
