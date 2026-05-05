import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geocoding/geocoding.dart';
import '../models/trip.dart';
import '../services/database_service.dart';
import 'add_trip_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;

  const TripDetailScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  Trip? _trip;
  bool _isLoading = true;
  List<LatLng> _routePoints = [];
  Set<Marker> _markers = {};
  String? _routeError;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    final trip = await DatabaseService.instance.getTripById(widget.tripId);
    if (trip != null) {
      await _buildRoute(trip);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _buildRoute(Trip trip) async {
    final points = <LatLng>[];
    final markers = <Marker>{};
    final orderedPlaces = [trip.destination, ...trip.stops];

    for (int i = 0; i < orderedPlaces.length; i++) {
      try {
        final locations = await locationFromAddress(orderedPlaces[i]);
        if (locations.isEmpty) continue;

        final point = LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
        points.add(point);
        markers.add(
          Marker(
            markerId: MarkerId('stop_$i'),
            position: point,
            infoWindow: InfoWindow(
              title: i == 0 ? 'Destination' : 'Stop $i',
              snippet: orderedPlaces[i],
            ),
          ),
        );
      } catch (_) {
        continue;
      }
    }

    _routePoints = points;
    _markers = markers;
    _routeError = points.isEmpty
        ? 'Could not find map coordinates for this destination/stops.'
        : null;
  }

  Future<void> _fitCameraToRoute() async {
    if (_mapController == null || _routePoints.isEmpty) return;

    if (_routePoints.length == 1) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _routePoints.first, zoom: 12),
        ),
      );
      return;
    }

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (final point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50,
      ),
    );
  }

  void _shareTrip() {
    if (_trip != null) {
      final text =
          'Trip to ${_trip!.destination}\n'
          '${_trip!.startDate} - ${_trip!.endDate}\n'
          '${_trip!.notes}\n'
          'Stops: ${_trip!.stops.isEmpty ? 'None' : _trip!.stops.join(', ')}';
      Share.share(text);
    }
  }

  Future<void> _editTrip() async {
    if (_trip == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTripScreen(existingTrip: _trip),
      ),
    );

    _loadTrip();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Details')),
        body: const Center(child: Text('Trip not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editTrip),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareTrip),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Trip Info Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.place, color: Colors.blue, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _trip!.destination,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Travel Dates',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_trip!.startDate} to ${_trip!.endDate}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_trip!.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Notes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _trip!.notes,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                    if (_trip!.stops.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Stops',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _trip!.stops
                            .map((stop) => Chip(label: Text(stop)))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _trip!.status == 'upcoming'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _trip!.status == 'upcoming' ? 'Upcoming' : 'Past',
                        style: TextStyle(
                          color: _trip!.status == 'upcoming'
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Google Maps Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: _routeError != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _routeError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : _routePoints.isNotEmpty
                        ? GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _routePoints.first,
                              zoom: 5,
                            ),
                            markers: _markers,
                            polylines: {
                              Polyline(
                                polylineId: const PolylineId('trip_route'),
                                points: _routePoints,
                                color: Colors.blue,
                                width: 4,
                                geodesic: true,
                              ),
                            },
                            onMapCreated: (controller) {
                              _mapController = controller;
                              _fitCameraToRoute();
                            },
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
