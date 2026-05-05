import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip.dart';
import '../services/database_service.dart';
import '../widgets/trip_card.dart';
import 'add_trip_screen.dart';
import 'trip_detail_screen.dart';

class TripsListScreen extends StatefulWidget {
  final bool showOnboardingTip;
  final VoidCallback? onOnboardingDismissed;

  const TripsListScreen({
    Key? key,
    this.showOnboardingTip = false,
    this.onOnboardingDismissed,
  }) : super(key: key);

  @override
  State<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends State<TripsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Trip> _upcomingTrips = [];
  List<Trip> _pastTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _loadTrips();
    }
  }

  Future<void> _openAddTrip() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTripScreen()),
    );
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    final upcomingTrips = await DatabaseService.instance.getTripsByStatus(
      'upcoming',
    );
    final pastTrips = await DatabaseService.instance.getTripsByStatus('past');

    if (!mounted) return;

    setState(() {
      _upcomingTrips = upcomingTrips;
      _pastTrips = pastTrips;
      _isLoading = false;
    });
  }

  Future<void> _deleteTrip(Trip trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Delete trip to ${trip.destination}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.instance.deleteTrip(trip.id!);
      _loadTrips();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Trip deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await DatabaseService.instance.createTrip(
                Trip(
                  destination: trip.destination,
                  startDate: trip.startDate,
                  endDate: trip.endDate,
                  notes: trip.notes,
                  status: trip.status,
                  stops: trip.stops,
                ),
              );
              _loadTrips();
            },
          ),
        ),
      );
    }
  }

  void _shareTrip(Trip trip) {
    final text =
        'Trip to ${trip.destination}\n'
        '${trip.startDate} - ${trip.endDate}\n'
        '${trip.notes}';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Planner'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _openAddTrip),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Upcoming'),
            Tab(icon: Icon(Icons.schedule), text: 'Past'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (widget.showOnboardingTip)
            MaterialBanner(
              content: const Text(
                'Welcome! Add your first trip and start building a route with real places.',
              ),
              leading: const Icon(Icons.tips_and_updates_outlined),
              actions: [
                TextButton(
                  onPressed: widget.onOnboardingDismissed,
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTripsList(_upcomingTrips, 'upcoming'),
                      _buildTripsList(_pastTrips, 'past'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(List<Trip> trips, String status) {
    if (trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTrips,
        child: ListView(
          children: [
            SizedBox(
              height: 380,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No $status trips yet',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first itinerary in a few taps.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _openAddTrip,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Trip'),
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

    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return TripCard(
            trip: trip,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripDetailScreen(tripId: trip.id!),
                ),
              );
              _loadTrips();
            },
            onDelete: () => _deleteTrip(trip),
            onShare: () => _shareTrip(trip),
          );
        },
      ),
    );
  }
}
