import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardme_app/domain/entities/trip.dart';
import 'package:guardme_app/presentation/providers/trip_provider.dart';
import 'package:guardme_app/presentation/widgets/my_button.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  StreamSubscription<Position>? _positionStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _isLoading = false;
      _updateMarker(position);
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position pos) {
      setState(() {
        _currentPosition = pos;
        _updateMarker(pos);
      });
    });
  }

  void _updateMarker(Position pos) {
    _markers = {
      Marker(
        markerId: const MarkerId('current_position'),
        position: LatLng(pos.latitude, pos.longitude),
        infoWindow: const InfoWindow(title: 'You are here'),
      ),
    };
    _animateToPosition(pos);
  }

  void _animateToPosition(Position pos) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pos.latitude, pos.longitude),
          zoom: 15,
        ),
      ),
    );
  }

  void _startTrip() async {
    final pos = _currentPosition;
    if (pos == null) return;

    final trip = Trip(
      startTime: DateTime.now(),
      startLat: pos.latitude,
      startLng: pos.longitude,
      status: 'ACTIVE',
    );
    await ref.read(tripProvider.notifier).createTrip(trip);
  }

  void _endTrip() async {
    final currentTrip = ref.read(tripProvider).currentTrip;
    if (currentTrip?.id != null) {
      await ref.read(tripProvider.notifier).endTrip(currentTrip!.id!);
    }
  }

  void _triggerEmergency() async {
    final currentTrip = ref.read(tripProvider).currentTrip;
    if (currentTrip?.id != null) {
      await ref.read(tripProvider.notifier).triggerEmergency(currentTrip!.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Emergency alert sent!'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final hasActiveTrip = tripState.currentTrip != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Map',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_currentPosition == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Location not available',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  MyButton(
                    text: 'Enable Location',
                    onPressed: _initLocation,
                  ),
                ],
              ),
            )
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasActiveTrip) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _TripStat(
                            icon: Icons.timer,
                            label: 'Duration',
                            value: '00:00',
                          ),
                          _TripStat(
                            icon: Icons.speed,
                            label: 'Distance',
                            value: '0 km',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        if (hasActiveTrip) ...[
                          Expanded(
                            child: MyButton(
                              text: 'End Trip',
                              color: Colors.orange,
                              onPressed: _endTrip,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MyButton(
                              text: 'EMERGENCY',
                              color: Colors.red,
                              onPressed: _triggerEmergency,
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: MyButton(
                              text: 'Start Trip',
                              color: Colors.green,
                              onPressed: _startTrip,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TripStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
