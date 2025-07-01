import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/party.dart';
import '../models/gatepass.dart';
import '../models/warehouse.dart';
import '../models/user.dart';

class DatabaseService {

  factory DatabaseService() => _instance;

  DatabaseService._internal();
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static const String _databaseName = 'gatepass.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    try {
      await database;
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    String path;
    if (Platform.isWindows || Platform.isLinux) {
      path = join(Directory.current.path, _databaseName);
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, _databaseName);
    }

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Verify database integrity
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE warehouses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        isActive INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE parties(
        name TEXT PRIMARY KEY,
        gstNumber TEXT,
        addresses TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE gatepasses(
        id TEXT PRIMARY KEY,
        serialNumber TEXT NOT NULL,
        dateTime TEXT,
        warehouseId INTEGER,
        invoiceNumber TEXT,
        partyName TEXT,
        gstNumber TEXT,
        address TEXT,
        vehicleNumber TEXT,
        quantity REAL,
        productGrade TEXT,
        isPrinted INTEGER,
        isSynced INTEGER,
        createdBy TEXT,
        FOREIGN KEY (warehouseId) REFERENCES warehouses (id),
        FOREIGN KEY (partyName) REFERENCES parties (name)
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        warehouseId INTEGER,
        isActive INTEGER DEFAULT 1,
        FOREIGN KEY (warehouseId) REFERENCES warehouses (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE product_grades(
        grade TEXT PRIMARY KEY
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new tables and columns for version 2
      await db.execute('ALTER TABLE gatepasses ADD COLUMN warehouseId INTEGER');
      await db.execute('ALTER TABLE gatepasses ADD COLUMN serialNumber TEXT');
      await db.execute('ALTER TABLE gatepasses ADD COLUMN createdBy TEXT');
    }
  }

  // Warehouse operations
  Future<void> insertWarehouse(Warehouse warehouse) async {
    final db = await database;
    await db.insert('warehouses', warehouse.toMap());
  }

  Future<List<Warehouse>> getAllWarehouses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('warehouses');
    return List.generate(maps.length, (i) => Warehouse.fromMap(maps[i]));
  }

  Future<void> deleteWarehouse(int id) async {
    final db = await database;
    await db.delete(
      'warehouses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Party operations
  Future<void> insertParty(Party party) async {
    final db = await database;
    await db.insert(
      'parties',
      party.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteParty(String name) async {
    final db = await database;
    await db.delete(
      'parties',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  Future<List<Party>> getAllParties() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('parties');
    return List.generate(maps.length, (i) => Party.fromMap(maps[i]));
  }

  Future<Party?> getPartyByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'parties',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (maps.isEmpty) return null;
    return Party.fromMap(maps.first);
  }

  // Gatepass operations
  Future<String> generateSerialNumber(int warehouseId) async {
    final db = await database;
    final now = DateTime.now();
    final prefix = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    final result = await db.query(
      'gatepasses',
      where: 'serialNumber LIKE ? AND warehouseId = ?',
      whereArgs: ['$prefix%', warehouseId],
      orderBy: 'serialNumber DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return '$prefix${'0001'.padLeft(4, '0')}';
    }

    final lastSerial = result.first['serialNumber'] as String;
    final lastNumber = int.parse(lastSerial.substring(6));
    final nextNumber = lastNumber + 1;
    
    if (nextNumber > 9999) {
      throw Exception('Maximum daily gatepass limit reached');
    }

    return '$prefix${nextNumber.toString().padLeft(4, '0')}';
  }

  Future<void> insertGatepass(Gatepass gatepass) async {
    final db = await database;
    await db.insert(
      'gatepasses',
      gatepass.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Gatepass>> getGatepasses({
    DateTime? startDate,
    DateTime? endDate,
    String? partyName,
    int? warehouseId,
    bool? isSynced,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause += 'dateTime BETWEEN ? AND ?';
      whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }

    if (partyName != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'partyName = ?';
      whereArgs.add(partyName);
    }

    if (warehouseId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'warehouseId = ?';
      whereArgs.add(warehouseId);
    }

    if (isSynced != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'isSynced = ?';
      whereArgs.add(isSynced ? 1 : 0);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'gatepasses',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'dateTime DESC',
    );

    return List.generate(maps.length, (i) => Gatepass.fromMap(maps[i]));
  }

  Future<void> updateGatepass(Gatepass gatepass) async {
    final db = await database;
    await db.update(
      'gatepasses',
      gatepass.toMap(),
      where: 'id = ?',
      whereArgs: [gatepass.id],
    );
  }

  Future<void> deleteGatepass(String id) async {
    final db = await database;
    await db.delete(
      'gatepasses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // User operations
  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap());
  }

  Future<User?> authenticateUser(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ? AND isActive = 1',
      whereArgs: [username, password],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  // Product Grade operations
  Future<List<String>> getProductGrades() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('product_grades');
    return List.generate(maps.length, (i) => maps[i]['grade'] as String);
  }

  Future<void> addProductGrade(String grade) async {
    final db = await database;
    await db.insert(
      'product_grades',
      {'grade': grade},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteProductGrade(String grade) async {
    final db = await database;
    await db.delete(
      'product_grades',
      where: 'grade = ?',
      whereArgs: [grade],
    );
  }

  Future<User?> getCurrentUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'isActive = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }
} 