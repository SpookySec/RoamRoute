import 'dart:convert';

class Trip {
  final int? id;
  final String destination;
  final String startDate;
  final String endDate;
  final String notes;
  final String status; // 'upcoming' or 'past'
  final List<String> stops;
  final double budget;
  final List<String> imagePaths;

  Trip({
    this.id,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.notes,
    required this.status,
    this.stops = const [],
    this.budget = 0.0,
    this.imagePaths = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destination': destination,
      'startDate': startDate,
      'endDate': endDate,
      'notes': notes,
      'status': status,
      'stops': jsonEncode(stops),
      'budget': budget,
      'imagePaths': jsonEncode(imagePaths),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    final stopsValue = map['stops'];
    List<String> parsedStops = [];
    if (stopsValue is String && stopsValue.isNotEmpty) {
      try {
        final decoded = jsonDecode(stopsValue);
        if (decoded is List) {
          parsedStops = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        parsedStops = [];
      }
    }

    final imagesValue = map['imagePaths'];
    List<String> parsedImages = [];
    if (imagesValue is String && imagesValue.isNotEmpty) {
      try {
        final decoded = jsonDecode(imagesValue);
        if (decoded is List) {
          parsedImages = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        parsedImages = [];
      }
    }

    return Trip(
      id: map['id'],
      destination: map['destination'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      notes: map['notes'],
      status: map['status'],
      stops: parsedStops,
      budget: (map['budget'] ?? 0.0).toDouble(),
      imagePaths: parsedImages,
    );
  }

  Trip copyWith({
    int? id,
    String? destination,
    String? startDate,
    String? endDate,
    String? notes,
    String? status,
    List<String>? stops,
    double? budget,
    List<String>? imagePaths,
  }) {
    return Trip(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      stops: stops ?? this.stops,
      budget: budget ?? this.budget,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}
