import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip.dart';
import '../services/database_service.dart';
import '../theme/duo_theme.dart';
import '../widgets/trip_card.dart';
import '../widgets/squishy_button.dart';
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

class _TripsListScreenState extends State<TripsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Trip> _upcomingTrips = [];
  List<Trip> _pastTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final upcomingTrips = await DatabaseService.instance.getTripsByStatus('upcoming');
    final pastTrips = await DatabaseService.instance.getTripsByStatus('past');

    if (!mounted) return;
    setState(() {
      _upcomingTrips = upcomingTrips;
      _pastTrips = pastTrips;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ROAM ROUTE'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: DuoColors.duoCardBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: DuoColors.duoGreen,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: DuoColors.duoGreenDark, offset: Offset(0, 4))],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: DuoColors.duoGray,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              tabs: const [
                Tab(text: 'UPCOMING'),
                Tab(text: 'PAST'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripsList(_upcomingTrips, 'upcoming'),
          _buildTripsList(_pastTrips, 'past'),
        ],
      ),
      floatingActionButton: SquishyButton(
        icon: Icons.add,
        color: DuoColors.duoGreen,
        onTap: _openAddTrip,
      ),
    );
  }

  Widget _buildTripsList(List<Trip> trips, String status) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: DuoColors.duoGreen));

    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map, size: 80, color: DuoColors.duoCardBorder),
              const SizedBox(height: 24),
              Text(
                'NO ${status.toUpperCase()} TRIPS',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: DuoColors.duoGray),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start your next adventure by tapping the button below!',
                textAlign: TextAlign.center,
                style: TextStyle(color: DuoColors.duoGray, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return TripCard(
          trip: trip,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TripDetailScreen(tripId: trip.id!)),
            );
            _loadTrips();
          },
          onDelete: () => _deleteTrip(trip),
          onShare: () => _shareTrip(trip),
        );
      },
    );
  }

  Future<void> _deleteTrip(Trip trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('DELETE TRIP?'),
        content: Text('Are you sure you want to delete your trip to ${trip.destination}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DuoColors.duoRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.instance.deleteTrip(trip.id!);
      _loadTrips();
    }
  }

  void _shareTrip(Trip trip) {
    Share.share('Check out my trip to ${trip.destination}!');
  }
}
