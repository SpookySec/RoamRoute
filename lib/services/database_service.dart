import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/trip.dart';
import '../models/expense.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('trips.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        destination TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        notes TEXT,
        status TEXT NOT NULL,
        stops TEXT NOT NULL DEFAULT '[]',
        budget REAL NOT NULL DEFAULT 0.0,
        imagePaths TEXT NOT NULL DEFAULT '[]'
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tripId INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE trips ADD COLUMN stops TEXT NOT NULL DEFAULT '[]'",
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE trips ADD COLUMN budget REAL NOT NULL DEFAULT 0.0",
      );
      await db.execute(
        "ALTER TABLE trips ADD COLUMN imagePaths TEXT NOT NULL DEFAULT '[]'",
      );
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tripId INTEGER NOT NULL,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<int> createTrip(Trip trip) async {
    final db = await instance.database;
    return await db.insert('trips', trip.toMap());
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await instance.database;
    final result = await db.query('trips', orderBy: 'startDate DESC');
    return result.map((json) => Trip.fromMap(json)).toList();
  }

  Future<Trip?> getTripById(int id) async {
    final db = await instance.database;
    final maps = await db.query('trips', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Trip.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Trip>> getTripsByStatus(String status) async {
    final db = await instance.database;
    final result = await db.query(
      'trips',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'startDate DESC',
    );
    return result.map((json) => Trip.fromMap(json)).toList();
  }

  Future<int> updateTrip(Trip trip) async {
    final db = await instance.database;
    return db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<int> deleteTrip(int id) async {
    final db = await instance.database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  // Expense Methods
  Future<int> createExpense(Expense expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getExpensesByTrip(int tripId) async {
    final db = await instance.database;
    final result = await db.query(
      'expenses',
      where: 'tripId = ?',
      whereArgs: [tripId],
      orderBy: 'date DESC',
    );
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
