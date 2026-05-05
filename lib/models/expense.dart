class Expense {
  final int? id;
  final int tripId;
  final String title;
  final double amount;
  final String date;

  Expense({
    this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'title': title,
      'amount': amount,
      'date': date,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      tripId: map['tripId'],
      title: map['title'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: map['date'],
    );
  }
}
