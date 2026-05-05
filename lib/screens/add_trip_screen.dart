import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/trip.dart';
import '../services/database_service.dart';
import '../theme/duo_theme.dart';
import '../widgets/duo_form_widgets.dart';
import '../widgets/duo_card.dart';

class AddTripScreen extends StatefulWidget {
  final Trip? existingTrip;

  const AddTripScreen({Key? key, this.existingTrip}) : super(key: key);

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  static const MethodChannel _placesChannel = MethodChannel('roam_route/places');

  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _stopController = TextEditingController();
  final _notesController = TextEditingController();
  final _budgetController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'upcoming';
  final List<String> _stops = [];
  
  List<String> _destinationSuggestions = [];
  List<String> _stopSuggestions = [];
  Timer? _debounce;

  bool get _isEditMode => widget.existingTrip != null;

  @override
  void initState() {
    super.initState();
    final trip = widget.existingTrip;
    if (trip != null) {
      _destinationController.text = trip.destination;
      _notesController.text = trip.notes;
      _budgetController.text = trip.budget.toString();
      _status = trip.status;
      _startDate = DateTime.tryParse(trip.startDate);
      _endDate = DateTime.tryParse(trip.endDate);
      _stops.addAll(trip.stops);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _destinationController.dispose();
    _stopController.dispose();
    _notesController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String query, bool isDestination) async {
    _debounce?.cancel();
    if (query.length < 2) {
      setState(() {
        if (isDestination) _destinationSuggestions.clear();
        else _stopSuggestions.clear();
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final response = await _placesChannel.invokeMethod<List<dynamic>>('autocomplete', {'query': query});
        if (response == null) return;
        final suggestions = response.whereType<Map>().map((e) => e['fullText'].toString()).toList();
        if (!mounted) return;
        setState(() {
          if (isDestination) _destinationSuggestions = suggestions;
          else _stopSuggestions = suggestions;
        });
      } catch (_) {}
    });
  }

  void _addStop(String stop) {
    if (stop.isEmpty) return;
    setState(() {
      _stops.add(stop);
      _stopController.clear();
      _stopSuggestions.clear();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: DuoColors.duoGreen)), child: child!),
    );
    if (picked != null) setState(() { if (isStartDate) _startDate = picked; else _endDate = picked; });
  }

  String _formatDate(DateTime? date) => date == null ? 'SELECT DATE' : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _saveTrip() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both dates')));
        return;
      }
      final trip = Trip(
        id: widget.existingTrip?.id,
        destination: _destinationController.text,
        startDate: _formatDate(_startDate),
        endDate: _formatDate(_endDate),
        notes: _notesController.text,
        status: _status,
        stops: _stops,
        budget: double.tryParse(_budgetController.text) ?? 0.0,
      );
      if (_isEditMode) await DatabaseService.instance.updateTrip(trip);
      else await DatabaseService.instance.createTrip(trip);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'EDIT TRIP' : 'NEW ADVENTURE')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DuoTextField(
                controller: _destinationController,
                label: 'Destination',
                hint: 'e.g., Paris, France',
                icon: Icons.place,
                onChanged: (v) => _fetchSuggestions(v, true),
                validator: (v) => v!.isEmpty ? 'Where are we going?' : null,
              ),
              _buildSuggestionsList(_destinationSuggestions, (s) {
                _destinationController.text = s;
                setState(() => _destinationSuggestions.clear());
              }),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: DuoTextField(
                      controller: _stopController,
                      label: 'Add Stop',
                      hint: 'e.g., Rome, Italy',
                      icon: Icons.flag,
                      onChanged: (v) => _fetchSuggestions(v, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: DuoButton(text: 'ADD', onTap: () => _addStop(_stopController.text), width: 80),
                  ),
                ],
              ),
              _buildSuggestionsList(_stopSuggestions, (s) => _addStop(s)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _stops.asMap().entries.map((e) => Chip(
                  label: Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: DuoColors.duoBlue.withOpacity(0.1),
                  deleteIconColor: DuoColors.duoBlue,
                  onDeleted: () => setState(() => _stops.removeAt(e.key)),
                )).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildDateSelector('START DATE', _startDate, () => _selectDate(context, true))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateSelector('END DATE', _endDate, () => _selectDate(context, false))),
                ],
              ),
              const SizedBox(height: 24),
              DuoTextField(controller: _budgetController, label: 'Budget', hint: '0.00', icon: Icons.attach_money, keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              const Text('STATUS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: DuoColors.duoGray)),
              const SizedBox(height: 8),
              DuoCard(padding: const EdgeInsets.symmetric(horizontal: 16), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _status, isExpanded: true, style: const TextStyle(fontWeight: FontWeight.bold, color: DuoColors.duoTextMain), items: const [DropdownMenuItem(value: 'upcoming', child: Text('UPCOMING')), DropdownMenuItem(value: 'past', child: Text('PAST'))], onChanged: (v) => setState(() => _status = v!)))),
              const SizedBox(height: 24),
              DuoTextField(controller: _notesController, label: 'Notes', hint: 'Add any notes...', maxLines: 3),
              const SizedBox(height: 40),
              DuoButton(text: _isEditMode ? 'UPDATE TRIP' : 'START JOURNEY', onTap: _saveTrip),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(List<String> suggestions, Function(String) onSelect) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return DuoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: suggestions.map((s) => ListTile(
          title: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => onSelect(s),
          dense: true,
        )).toList(),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: DuoColors.duoGray)),
        const SizedBox(height: 8),
        GestureDetector(onTap: onTap, child: DuoCard(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), child: Center(child: Text(_formatDate(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: DuoColors.duoTextMain))))),
      ],
    );
  }
}
