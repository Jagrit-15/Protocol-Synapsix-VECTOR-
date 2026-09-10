// SQLite storage for raw sensor frames — Phase 1 requirement: "raw sensor
// logger → local SQLite (needed for later ML training data collection too)".
//
// Kept separate from any trip-level SQLite tables so this can log
// continuously regardless of whether a "trip" concept exists yet.

import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class RawSensorLogDb {
  RawSensorLogDb._();
  static final RawSensorLogDb instance = RawSensorLogDb._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'raw_sensor_log.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTablesV2(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateV1ToV2(db);
        }
      },
    );
  }

  Future<void> _createTablesV2(Database db) async {
    await db.execute('''
      CREATE TABLE raw_sensor_samples (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ts_ms INTEGER NOT NULL,
        accel_x REAL NOT NULL,
        accel_y REAL NOT NULL,
        accel_z REAL NOT NULL,
        gyro_x REAL NOT NULL,
        gyro_y REAL NOT NULL,
        gyro_z REAL NOT NULL,
        mag_x REAL NOT NULL,
        mag_y REAL NOT NULL,
        mag_z REAL NOT NULL,
        baro_hpa REAL,
        gnss_lat REAL,
        gnss_lon REAL,
        gnss_accuracy_m REAL,
        gnss_heading_deg REAL,
        recording_id TEXT,
        label TEXT,
        gt_x REAL,
        gt_y REAL,
        gt_heading REAL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_raw_sensor_samples_ts ON raw_sensor_samples(ts_ms)',
    );
    await db.execute(
      'CREATE INDEX idx_raw_sensor_samples_recording ON raw_sensor_samples(recording_id)',
    );

    await db.execute('''
      CREATE TABLE recordings (
        id TEXT PRIMARY KEY,
        label TEXT,
        start_ts_ms INTEGER NOT NULL,
        end_ts_ms INTEGER,
        sample_count INTEGER DEFAULT 0,
        notes TEXT
      )
    ''');
  }

  Future<void> _migrateV1ToV2(Database db) async {
    // Add new columns to existing table
    await db.execute('ALTER TABLE raw_sensor_samples ADD COLUMN recording_id TEXT');
    await db.execute('ALTER TABLE raw_sensor_samples ADD COLUMN label TEXT');
    await db.execute('ALTER TABLE raw_sensor_samples ADD COLUMN gt_x REAL');
    await db.execute('ALTER TABLE raw_sensor_samples ADD COLUMN gt_y REAL');
    await db.execute('ALTER TABLE raw_sensor_samples ADD COLUMN gt_heading REAL');

    await db.execute(
      'CREATE INDEX idx_raw_sensor_samples_recording ON raw_sensor_samples(recording_id)',
    );

    await db.execute('''
      CREATE TABLE recordings (
        id TEXT PRIMARY KEY,
        label TEXT,
        start_ts_ms INTEGER NOT NULL,
        end_ts_ms INTEGER,
        sample_count INTEGER DEFAULT 0,
        notes TEXT
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}