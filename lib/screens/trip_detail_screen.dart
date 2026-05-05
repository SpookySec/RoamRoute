import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip.dart';
import '../models/expense.dart';
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
  List<Expense> _expenses = [];
  bool _isLoading = true;
  List<LatLng> _routePoints = [];
  Set<Marker> _markers = {};
  String? _routeError;
  GoogleMapController? _mapController;
  bool _travelMode = false;
  int _activeStopIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _optimizeRoute() async {
    if (_trip == null || _trip!.stops.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Simple nearest neighbor optimization logic
      final optimizedStops = List<String>.from(_trip!.stops);
      List<Location> currentPos = [];

      try {
        currentPos = await locationFromAddress(_trip!.destination);
      } catch (e) {
        debugPrint('Geocoding error for destination: $e');
      }

      if (currentPos.isNotEmpty) {
        final startLat = currentPos.first.latitude;
        final startLng = currentPos.first.longitude;

        final Map<String, LatLng> stopCoords = {};
        for (final stop in optimizedStops) {
          try {
            final locs = await locationFromAddress(stop);
            if (locs.isNotEmpty) {
              stopCoords[stop] =
                  LatLng(locs.first.latitude, locs.first.longitude);
            }
          } catch (_) {}
        }

        final List<String> sortedStops = [];
        var currentLat = startLat;
        var currentLng = startLng;
        final remainingStops = List<String>.from(optimizedStops);

        while (remainingStops.isNotEmpty) {
          String? nearest;
          double minDistance = double.infinity;

          for (final stop in remainingStops) {
            final coord = stopCoords[stop];
            if (coord != null) {
              final d =
                  (coord.latitude - currentLat) *
                      (coord.latitude - currentLat) +
                  (coord.longitude - currentLng) *
                      (coord.longitude - currentLng);
              if (d < minDistance) {
                minDistance = d;
                nearest = stop;
              }
            }
          }

          if (nearest != null) {
            sortedStops.add(nearest);
            remainingStops.remove(nearest);
            currentLat = stopCoords[nearest]!.latitude;
            currentLng = stopCoords[nearest]!.longitude;
          } else {
            sortedStops.addAll(remainingStops);
            break;
          }
        }

        final updatedTrip = Trip(
          id: _trip!.id,
          destination: _trip!.destination,
          startDate: _trip!.startDate,
          endDate: _trip!.endDate,
          notes: _trip!.notes,
          status: _trip!.status,
          stops: sortedStops,
          budget: _trip!.budget,
          imagePaths: _trip!.imagePaths,
        );

        await DatabaseService.instance.updateTrip(updatedTrip);
        await _loadTrip();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Route optimized!')),
          );
        }
      } else {
        throw Exception('Could not determine destination coordinates');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Platform.isLinux
                  ? 'Optimization is only supported on Android/iOS (Geocoding requirement).'
                  : 'Optimization failed: Could not resolve addresses.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadTrip() async {
    final trip = await DatabaseService.instance.getTripById(widget.tripId);
    final expenses = await DatabaseService.instance.getExpensesByTrip(widget.tripId);
    
    if (trip != null) {
      await _buildRoute(trip);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _expenses = expenses;
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

  Future<void> _launchNavigation(String destination) async {
    final query = Uri.encodeComponent(destination);
    final url = 'google.navigation:q=$query';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      final webUrl = 'https://www.google.com/maps/search/?api=1&query=$query';
      await launchUrl(Uri.parse(webUrl));
    }
  }

  Future<void> _exploreNearby(String stop, String category) async {
    final query = Uri.encodeComponent('$category near $stop');
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    await launchUrl(Uri.parse(url));
  }

  String _getTripStatusMessage() {
    if (_trip == null) return '';
    final now = DateTime.now();
    final start = DateTime.parse(_trip!.startDate);
    final end = DateTime.parse(_trip!.endDate);

    if (now.isBefore(start)) {
      final diff = start.difference(now).inDays;
      return 'Starts in $diff days';
    } else if (now.isAfter(end)) {
      return 'Completed';
    } else {
      return 'Currently on Day ${now.difference(start).inDays + 1}';
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

  void _addExpense() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title (e.g., Lunch)'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (titleController.text.isNotEmpty && amount > 0) {
                final expense = Expense(
                  tripId: _trip!.id!,
                  title: titleController.text,
                  amount: amount,
                  date: DateTime.now().toIso8601String(),
                );
                await DatabaseService.instance.createExpense(expense);
                if (mounted) Navigator.pop(context);
                _loadTrip();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  double get _totalSpent => _expenses.fold(0, (sum, e) => sum + e.amount);

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
          IconButton(
            icon: Icon(_travelMode ? Icons.explore : Icons.explore_outlined),
            onPressed: () {
              setState(() => _travelMode = !_travelMode);
            },
            tooltip: 'Toggle Travel Mode',
          ),
          IconButton(icon: const Icon(Icons.edit), onPressed: _editTrip),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareTrip),
        ],
      ),
      bottomNavigationBar: _travelMode
          ? BottomAppBar(
            child: Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Next Stop'),
                    subtitle: Text(
                      _activeStopIndex == 0
                          ? _trip!.destination
                          : _trip!.stops[_activeStopIndex - 1],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _launchNavigation(
                    _activeStopIndex == 0
                        ? _trip!.destination
                        : _trip!.stops[_activeStopIndex - 1],
                  ),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Go'),
                ),
                const SizedBox(width: 8),
              ],
            ),
          )
          : null,
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
                              Text(
                                _getTripStatusMessage(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Budget Remaining',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${(_trip!.budget - _totalSpent).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                color: (_trip!.budget - _totalSpent) >= 0 
                                    ? Colors.green 
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Spent: \$${_totalSpent.toStringAsFixed(2)} of \$${_trip!.budget.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
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
                                _trip!.status == 'upcoming'
                                    ? 'Upcoming'
                                    : 'Past',
                                style: TextStyle(
                                  color: _trip!.status == 'upcoming'
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_trip!.stops.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Stops',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _optimizeRoute,
                            icon: const Icon(Icons.auto_fix_high, size: 18),
                            label: const Text('Optimize Route'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_trip!.stops.length, (index) {
                          final stop = _trip!.stops[index];
                          return ActionChip(
                            label: Text(stop),
                            avatar: _travelMode && _activeStopIndex == index + 1
                                ? const Icon(Icons.play_arrow, size: 16)
                                : null,
                            onPressed: () {
                              if (_travelMode) {
                                setState(() => _activeStopIndex = index + 1);
                                if (_routePoints.length > index + 1) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLng(
                                      _routePoints[index + 1],
                                    ),
                                  );
                                }
                              } else {
                                _showStopActions(stop);
                              }
                            },
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Memories Section
            if (_trip!.imagePaths.isNotEmpty)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Memories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _trip!.imagePaths.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(
                                    File(_trip!.imagePaths[index]),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Expenses Section
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Expenses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _addExpense,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    if (_expenses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No expenses logged yet.', style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _expenses.length,
                        itemBuilder: (context, index) {
                          final expense = _expenses[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(expense.title),
                            subtitle: Text(expense.date.split('T')[0]),
                            trailing: Text(
                              '-\$${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                            onLongPress: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Expense?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await DatabaseService.instance.deleteExpense(expense.id!);
                                _loadTrip();
                              }
                            },
                          );
                        },
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

  void _showStopActions(String stop) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Explore around $stop',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Find Restaurants'),
                onTap: () {
                  Navigator.pop(context);
                  _exploreNearby(stop, 'restaurants');
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_pharmacy),
                title: const Text('Nearby Pharmacy'),
                onTap: () {
                  Navigator.pop(context);
                  _exploreNearby(stop, 'pharmacy');
                },
              ),
              ListTile(
                leading: const Icon(Icons.atm),
                title: const Text('Nearby ATM'),
                onTap: () {
                  Navigator.pop(context);
                  _exploreNearby(stop, 'atm');
                },
              ),
              ListTile(
                leading: const Icon(Icons.navigation),
                title: const Text('Get Directions'),
                onTap: () {
                  Navigator.pop(context);
                  _launchNavigation(stop);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
