class Moment {
  final int? id;
  final int tripId;
  final String? filePath;
  final String note;
  final String timestamp;

  Moment({
    this.id,
    required this.tripId,
    this.filePath,
    required this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'filePath': filePath,
      'note': note,
      'timestamp': timestamp,
    };
  }

  factory Moment.fromMap(Map<String, dynamic> map) {
    return Moment(
      id: map['id'],
      tripId: map['tripId'],
      filePath: map['filePath'],
      note: map['note'] ?? '',
      timestamp: map['timestamp'],
    );
  }
}
