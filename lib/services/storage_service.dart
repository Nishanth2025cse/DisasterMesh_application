import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/sos_model.dart';
import '../models/message_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Database? _db;
  
  // Web fallback storage
  UserModel? _webUser;
  final Map<String, SosModel> _webSosAlerts = {};
  final Set<String> _webRelayMessages = {};

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db;
  }

  Future<Database?> _initDatabase() async {
    if (kIsWeb) return null;
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'disaster_mesh.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      if (kDebugMode) print("DB init exception: $e");
      return null;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        bloodGroup TEXT NOT NULL,
        emergencyContact TEXT NOT NULL,
        registeredAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sos_alerts (
        sosId TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        victimName TEXT NOT NULL,
        victimPhone TEXT,
        message TEXT NOT NULL,
        category TEXT NOT NULL,
        priority TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp TEXT NOT NULL,
        status TEXT NOT NULL,
        ttl INTEGER NOT NULL,
        originDeviceId TEXT NOT NULL,
        version INTEGER NOT NULL,
        updateHistory TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE relay_messages (
        messageId TEXT PRIMARY KEY,
        sosId TEXT NOT NULL,
        payloadType TEXT NOT NULL,
        senderDeviceId TEXT NOT NULL,
        receivedAt TEXT NOT NULL,
        ttl INTEGER NOT NULL,
        hopsCount INTEGER NOT NULL
      )
    ''');
  }

  // --- USER PROFILE OPERATIONS ---

  Future<void> saveUser(UserModel user) async {
    if (kIsWeb) {
      _webUser = user;
      return;
    }
    final db = await database;
    if (db == null) {
      _webUser = user;
      return;
    }
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUser() async {
    if (kIsWeb) return _webUser;
    final db = await database;
    if (db == null) return _webUser;
    try {
      final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
      if (maps.isNotEmpty) {
        return UserModel.fromMap(maps.first);
      }
    } catch (e) {
      return _webUser;
    }
    return _webUser;
  }

  Future<void> clearUser() async {
    _webUser = null;
    if (kIsWeb) return;
    final db = await database;
    if (db != null) await db.delete('users');
  }

  // --- SOS OPERATIONS ---

  Future<void> saveSos(SosModel sos) async {
    _webSosAlerts[sos.sosId] = sos;
    if (kIsWeb) return;
    final db = await database;
    if (db != null) {
      await db.insert(
        'sos_alerts',
        sos.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<SosModel?> getSosById(String sosId) async {
    if (_webSosAlerts.containsKey(sosId)) return _webSosAlerts[sosId];
    if (kIsWeb) return null;
    final db = await database;
    if (db == null) return null;
    final List<Map<String, dynamic>> maps = await db.query(
      'sos_alerts',
      where: 'sosId = ?',
      whereArgs: [sosId],
    );
    if (maps.isNotEmpty) {
      return SosModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<SosModel>> getAllSos() async {
    if (kIsWeb) {
      final list = _webSosAlerts.values.toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }
    final db = await database;
    if (db == null) {
      final list = _webSosAlerts.values.toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }
    final List<Map<String, dynamic>> maps = await db.query(
      'sos_alerts',
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => SosModel.fromMap(map)).toList();
  }

  Future<List<SosModel>> getSosByPriority() async {
    final list = await getAllSos();
    list.sort((a, b) {
      int pA = _priorityScore(a.priority);
      int pB = _priorityScore(b.priority);
      if (pA != pB) return pB.compareTo(pA);
      return b.timestamp.compareTo(a.timestamp);
    });
    return list;
  }

  int _priorityScore(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH': return 3;
      case 'MEDIUM': return 2;
      case 'LOW': return 1;
      default: return 0;
    }
  }

  Future<void> updateSosStatus(String sosId, String newStatus) async {
    if (_webSosAlerts.containsKey(sosId)) {
      final old = _webSosAlerts[sosId]!;
      _webSosAlerts[sosId] = SosModel(
        sosId: old.sosId,
        userId: old.userId,
        victimName: old.victimName,
        victimPhone: old.victimPhone,
        message: old.message,
        category: old.category,
        priority: old.priority,
        latitude: old.latitude,
        longitude: old.longitude,
        timestamp: old.timestamp,
        status: newStatus,
        ttl: old.ttl,
        originDeviceId: old.originDeviceId,
        version: old.version,
        updateHistory: old.updateHistory,
      );
    }
    if (kIsWeb) return;
    final db = await database;
    if (db != null) {
      await db.update(
        'sos_alerts',
        {'status': newStatus},
        where: 'sosId = ?',
        whereArgs: [sosId],
      );
    }
  }

  // --- DUPLICATE PREVENTION & RELAY LOGS ---

  Future<bool> isDuplicateMessage(String messageId) async {
    if (_webRelayMessages.contains(messageId)) return true;
    if (kIsWeb) return false;
    final db = await database;
    if (db == null) return false;
    final result = await db.query(
      'relay_messages',
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
    return result.isNotEmpty;
  }

  Future<void> recordRelayMessage(MeshMessage message) async {
    _webRelayMessages.add(message.messageId);
    if (kIsWeb) return;
    final db = await database;
    if (db != null) {
      await db.insert(
        'relay_messages',
        {
          'messageId': message.messageId,
          'sosId': message.sosId,
          'payloadType': message.payloadType,
          'senderDeviceId': message.senderDeviceId,
          'receivedAt': DateTime.now().toIso8601String(),
          'ttl': message.ttl,
          'hopsCount': message.hopsCount,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
