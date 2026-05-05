import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../models/moment.dart';
import '../services/database_service.dart';
import '../theme/duo_theme.dart';
import '../widgets/squishy_button.dart';
import '../widgets/duo_card.dart';
import '../widgets/duo_form_widgets.dart';

class TripDetailScreen extends StatefulWidget {
  final int tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  Trip? _trip;
  List<Expense> _expenses = [];
  List<Moment> _moments = [];
  List<dynamic> _sortedItems = [];
  bool _isLoading = true;
  List<LatLng> _routePoints = [];
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTrip() async {
    final trip = await DatabaseService.instance.getTripById(widget.tripId);
    final expenses = await DatabaseService.instance.getExpensesByTrip(widget.tripId);
    final moments = await DatabaseService.instance.getMomentsByTrip(widget.tripId);

    if (trip != null) {
      await _buildRoute(trip);
      final items = [...expenses, ...moments];
      items.sort((a, b) {
        final dateA = DateTime.tryParse(a is Expense ? a.date : (a as Moment).timestamp) ?? DateTime(0);
        final dateB = DateTime.tryParse(b is Expense ? b.date : (b as Moment).timestamp) ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      if (!mounted) return;
      setState(() {
        _trip = trip;
        _expenses = expenses;
        _moments = moments;
        _sortedItems = items;
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
        final point = LatLng(locations.first.latitude, locations.first.longitude);
        points.add(point);
        markers.add(Marker(
          markerId: MarkerId('stop_$i'),
          position: point,
          infoWindow: InfoWindow(title: i == 0 ? 'Destination' : 'Stop $i', snippet: orderedPlaces[i]),
        ));
      } catch (_) { continue; }
    }
    _routePoints = points;
    _markers = markers;
  }

  Future<void> _optimizeRoute() async {
    if (_trip == null || _trip!.stops.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final currentPos = await locationFromAddress(_trip!.destination);
      if (currentPos.isNotEmpty) {
        final startLat = currentPos.first.latitude;
        final startLng = currentPos.first.longitude;
        
        List<String> remainingStops = List.from(_trip!.stops);
        List<String> optimizedStops = [];
        double currentLat = startLat;
        double currentLng = startLng;

        while (remainingStops.isNotEmpty) {
          String? nearestStop;
          double minDistance = double.maxFinite;
          int nearestIndex = -1;

          for (int i = 0; i < remainingStops.length; i++) {
            try {
              final locs = await locationFromAddress(remainingStops[i]);
              if (locs.isNotEmpty) {
                final d = (locs.first.latitude - currentLat).abs() + (locs.first.longitude - currentLng).abs();
                if (d < minDistance) {
                  minDistance = d;
                  nearestStop = remainingStops[i];
                  nearestIndex = i;
                }
              }
            } catch (_) {}
          }

          if (nearestIndex != -1) {
            optimizedStops.add(nearestStop!);
            final locs = await locationFromAddress(nearestStop);
            currentLat = locs.first.latitude;
            currentLng = locs.first.longitude;
            remainingStops.removeAt(nearestIndex);
          } else {
            optimizedStops.addAll(remainingStops);
            break;
          }
        }

        final updatedTrip = _trip!.copyWith(stops: optimizedStops);
        await DatabaseService.instance.updateTrip(updatedTrip);
        await _loadTrip();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareTrip() {
    if (_trip == null) return;
    Share.share('Check out my trip to ${_trip!.destination}!');
  }

  void _addExpense() {
    final titleC = TextEditingController();
    final amountC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('NEW EXPENSE', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleC, decoration: const InputDecoration(labelText: 'What for?')),
            TextField(controller: amountC, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DuoColors.duoGreen, foregroundColor: Colors.white),
            onPressed: () async {
              final amount = double.tryParse(amountC.text) ?? 0;
              if (amount > 0) {
                await DatabaseService.instance.createExpense(Expense(
                  tripId: widget.tripId, title: titleC.text, amount: amount, date: DateTime.now().toIso8601String(),
                ));
                if (mounted) Navigator.pop(context);
                _loadTrip();
              }
            },
            child: const Text('ADD'),
          )
        ],
      ),
    );
  }

  Future<void> _addMoment() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final noteC = TextEditingController();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('CAPTURE MOMENT', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(image.path), height: 120, fit: BoxFit.cover)),
            TextField(controller: noteC, decoration: const InputDecoration(labelText: 'Add a note...')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DuoColors.duoBlue, foregroundColor: Colors.white),
            onPressed: () async {
              await DatabaseService.instance.createMoment(Moment(
                tripId: widget.tripId, filePath: image.path, note: noteC.text, timestamp: DateTime.now().toIso8601String(),
              ));
              if (mounted) Navigator.pop(context);
              _loadTrip();
            },
            child: const Text('SAVE'),
          )
        ],
      ),
    );
  }

  double get _totalSpent => _expenses.fold(0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: DuoColors.duoGreen)));
    if (_trip == null) return const Scaffold(body: Center(child: Text('Trip not found')));

    final progress = _trip!.budget > 0 ? (_totalSpent / _trip!.budget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 300,
                decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
                clipBehavior: Clip.antiAlias,
                child: _routePoints.isNotEmpty
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(target: _routePoints.first, zoom: 12),
                        markers: _markers,
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: true,
                        polylines: {Polyline(polylineId: const PolylineId('r'), points: _routePoints, color: DuoColors.duoBlue, width: 5, jointType: JointType.round)},
                        onMapCreated: (controller) => _mapController = controller,
                      )
                    : Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [DuoColors.duoBlue, Color(0xFF86D3F9)])), child: const Center(child: Icon(Icons.map, size: 64, color: Colors.white))),
              ),
              Positioned(top: 0, left: 0, right: 0, child: Container(height: 100, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.4), Colors.transparent])))),
              SafeArea(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)), IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: _shareTrip)])),
            ],
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(_trip!.destination.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1, color: DuoColors.duoTextMain))),
                          if (_trip!.stops.isNotEmpty) DuoButton(text: 'OPTIMIZE', onTap: _optimizeRoute, width: 100, color: DuoColors.duoBlue, shadowColor: DuoColors.duoBlueDark),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${_trip!.startDate} — ${_trip!.endDate}', style: const TextStyle(color: DuoColors.duoGray, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      _buildBudgetProgress(progress),
                    ],
                  ),
                ),
                if (_trip!.stops.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PLANNED STOPS', style: TextStyle(fontWeight: FontWeight.w900, color: DuoColors.duoGray)),
                        const SizedBox(height: 12),
                        ..._trip!.stops.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DuoCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(radius: 12, backgroundColor: DuoColors.duoBlue, child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                                const SizedBox(width: 12),
                                Expanded(child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold, color: DuoColors.duoTextMain))),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sortedItems.length,
                    itemBuilder: (context, index) {
                      final item = _sortedItems[index];
                      return _buildTimelineItem(item, index == _sortedItems.length - 1);
                    },
                  ),
                ),
                if (_sortedItems.isEmpty) Padding(padding: const EdgeInsets.all(60), child: Column(children: [const Icon(Icons.auto_awesome, size: 64, color: DuoColors.duoCardBorder), const SizedBox(height: 16), const Text('Your journey begins here...', style: TextStyle(fontStyle: FontStyle.italic, color: DuoColors.duoGray, fontSize: 18, fontWeight: FontWeight.bold))])),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SquishyButton(icon: Icons.attach_money, color: DuoColors.duoGreen, onTap: _addExpense),
          const SizedBox(width: 12),
          SquishyButton(icon: Icons.camera_alt, color: DuoColors.duoBlue, onTap: _addMoment),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress(double progress) {
    return Column(
      children: [
        Stack(
          children: [
            Container(height: 16, width: double.infinity, decoration: BoxDecoration(color: DuoColors.duoCardBorder, borderRadius: BorderRadius.circular(12))),
            AnimatedContainer(
              duration: const Duration(milliseconds: 800), curve: Curves.elasticOut, height: 16, width: MediaQuery.of(context).size.width * progress,
              decoration: BoxDecoration(gradient: LinearGradient(colors: progress > 0.9 ? [DuoColors.duoOrange, const Color(0xFFFFB03B)] : [DuoColors.duoGreen, const Color(0xFF78D700)]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: (progress > 0.9 ? DuoColors.duoOrange : DuoColors.duoGreen).withOpacity(0.3), offset: const Offset(0, 4))]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$${_totalSpent.toStringAsFixed(0)} spent', style: const TextStyle(fontWeight: FontWeight.w900, color: DuoColors.duoTextMain)),
            Text('\$${_trip!.budget.toStringAsFixed(0)} budget', style: const TextStyle(color: DuoColors.duoGray, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineItem(dynamic item, bool isLast) {
    final isExpense = item is Expense;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              DuoCard(padding: EdgeInsets.zero, shadowHeight: 2, child: Container(width: 46, height: 46, decoration: BoxDecoration(color: isExpense ? DuoColors.duoGreen : DuoColors.duoBlue, shape: BoxShape.circle), child: Icon(isExpense ? Icons.attach_money : Icons.camera_alt, size: 24, color: Colors.white))),
              if (!isLast) Expanded(child: Container(width: 8, margin: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: DuoColors.duoCardBorder, borderRadius: BorderRadius.circular(4)))),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 32, top: 4), child: isExpense ? _buildDuoExpenseCard(item) : _buildDuoMomentCard(item))),
        ],
      ),
    );
  }

  Widget _buildDuoExpenseCard(Expense e) {
    return DuoCard(
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.title, style: const TextStyle(fontWeight: FontWeight.w900, color: DuoColors.duoTextMain, fontSize: 18)), Text(e.date.split('T')[0], style: const TextStyle(color: DuoColors.duoGray, fontWeight: FontWeight.bold, fontSize: 14))])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFFEFEF), borderRadius: BorderRadius.circular(12)), child: Text('-\$${e.amount}', style: const TextStyle(fontWeight: FontWeight.w900, color: DuoColors.duoRed))),
        ],
      ),
    );
  }

  Widget _buildDuoMomentCard(Moment m) {
    return DuoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (m.filePath != null) ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(18)), child: Image.file(File(m.filePath!), height: 180, width: double.infinity, fit: BoxFit.cover)),
          Padding(padding: const EdgeInsets.all(16), child: Text(m.note, style: const TextStyle(fontWeight: FontWeight.bold, color: DuoColors.duoTextMain, fontSize: 16, fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }
}
