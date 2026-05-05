import 'dart:convert';

class Trip {
  final int? id;
  final String destination;
  final String startDate;
  final String endDate;
  final String notes;
  final String status; // 'upcoming' or 'past'
  final List<String> stops;

  Trip({
    this.id,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.notes,
    required this.status,
    this.stops = const [],
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

    return Trip(
      id: map['id'],
      destination: map['destination'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      notes: map['notes'],
      status: map['status'],
      stops: parsedStops,
    );
  }
}
