import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/trip.dart';
import '../services/database_service.dart';

class AddTripScreen extends StatefulWidget {
  final Trip? existingTrip;

  const AddTripScreen({Key? key, this.existingTrip}) : super(key: key);

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  static const MethodChannel _placesChannel = MethodChannel(
    'roam_route/places',
  );

  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();
  final _stopController = TextEditingController();
  final _budgetController = TextEditingController();
  final _destinationFocusNode = FocusNode();
  final _stopFocusNode = FocusNode();

  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'upcoming';
  final List<String> _stops = [];
  final List<String> _imagePaths = [];
  final List<String> _destinationSuggestions = [];
  final List<String> _stopSuggestions = [];
  Timer? _destinationDebounce;
  Timer? _stopDebounce;

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
      _startDate = _parseDate(trip.startDate);
      _endDate = _parseDate(trip.endDate);
      _stops.addAll(trip.stops);
      _imagePaths.addAll(trip.imagePaths);
    }
  }

  @override
  void dispose() {
    _destinationDebounce?.cancel();
    _stopDebounce?.cancel();
    _destinationController.dispose();
    _notesController.dispose();
    _stopController.dispose();
    _budgetController.dispose();
    _destinationFocusNode.dispose();
    _stopFocusNode.dispose();
    super.dispose();
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String query) async {
    try {
      final response = await _placesChannel.invokeMethod<List<dynamic>>(
        'autocomplete',
        {'query': query},
      );

      if (response == null) return [];

      return response
          .whereType<Map>()
          .map((item) => (item['fullText'] ?? '').toString().trim())
          .where((text) => text.isNotEmpty)
          .toSet()
          .take(6)
          .toList();
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  void _onDestinationChanged(String value) {
    _destinationDebounce?.cancel();

    if (value.trim().length < 2) {
      setState(() => _destinationSuggestions.clear());
      return;
    }

    _destinationDebounce = Timer(const Duration(milliseconds: 300), () async {
      final suggestions = await _fetchAutocompleteSuggestions(value);
      if (!mounted) return;
      setState(() {
        _destinationSuggestions
          ..clear()
          ..addAll(suggestions);
      });
    });
  }

  void _onStopChanged(String value) {
    _stopDebounce?.cancel();

    if (value.trim().length < 2) {
      setState(() => _stopSuggestions.clear());
      return;
    }

    _stopDebounce = Timer(const Duration(milliseconds: 300), () async {
      final suggestions = await _fetchAutocompleteSuggestions(value);
      if (!mounted) return;
      setState(() {
        _stopSuggestions
          ..clear()
          ..addAll(suggestions);
      });
    });
  }

  void _selectDestinationSuggestion(String suggestion) {
    setState(() {
      _destinationController.text = suggestion;
      _destinationSuggestions.clear();
    });
    _destinationController.selection = TextSelection.fromPosition(
      TextPosition(offset: _destinationController.text.length),
    );
  }

  void _selectStopSuggestion(String suggestion) {
    setState(() {
      _stopController.text = suggestion;
      _stopSuggestions.clear();
    });
    _stopController.selection = TextSelection.fromPosition(
      TextPosition(offset: _stopController.text.length),
    );
  }

  DateTime? _parseDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveTrip() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both dates')),
        );
        return;
      }

      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date must be the same as or after start date'),
          ),
        );
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
        imagePaths: _imagePaths,
      );

      if (_isEditMode) {
        await DatabaseService.instance.updateTrip(trip);
      } else {
        await DatabaseService.instance.createTrip(trip);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Trip updated' : 'Trip saved'),
            duration: const Duration(seconds: 1),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _addStop() {
    final value = _stopController.text.trim();
    if (value.isEmpty) return;

    if (_stops.any((stop) => stop.toLowerCase() == value.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That stop is already in the trip')),
      );
      return;
    }

    setState(() {
      _stops.add(value);
      _stopController.clear();
      _stopSuggestions.clear();
    });
  }

  void _removeStop(int index) {
    setState(() {
      _stops.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imagePaths.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Trip' : 'Add New Trip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _destinationController,
                focusNode: _destinationFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Destination *',
                  hintText: 'e.g., Paris, France',
                  border: OutlineInputBorder(),
                  helperText: 'Type to see live place suggestions',
                ),
                onChanged: _onDestinationChanged,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a destination';
                  }
                  return null;
                },
              ),
              if (_destinationSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _destinationSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _destinationSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined),
                          title: Text(suggestion),
                          onTap: () => _selectDestinationSuggestion(suggestion),
                        );
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stopController,
                      focusNode: _stopFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Add Stop',
                        hintText: 'e.g., Rome, Italy',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _onStopChanged,
                      onFieldSubmitted: (_) => _addStop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _addStop, child: const Text('Add')),
                ],
              ),
              if (_stopSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _stopSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _stopSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.flag_outlined),
                          title: Text(suggestion),
                          onTap: () => _selectStopSuggestion(suggestion),
                        );
                      },
                    ),
                  ),
                ),
              ],
              if (_stops.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_stops.length, (index) {
                    return Chip(
                      label: Text(_stops[index]),
                      onDeleted: () => _removeStop(index),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_formatDate(_startDate)),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date *',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_formatDate(_endDate)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                  DropdownMenuItem(value: 'past', child: Text('Past')),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Add any notes about your trip...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 280,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budget (Total)',
                  hintText: 'e.g., 1500.00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_imagePaths.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagePaths.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(_imagePaths[index])),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add Photo'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTrip,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isEditMode ? 'Update Trip' : 'Save Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
