// Pepper Clinical — Local SQLite Database
// Full schema: users, children, sessions, task_records, assessments
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  Database? _db;
  final _uuid = const Uuid();

  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    final path   = p.join(dbPath, 'pepper_clinical.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Database get db {
    if (_db == null) throw Exception('DB not initialized');
    return _db!;
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id            TEXT PRIMARY KEY,
        email         TEXT UNIQUE NOT NULL,
        full_name     TEXT NOT NULL,
        pin           TEXT UNIQUE NOT NULL,
        plan          TEXT DEFAULT 'trial',
        trial_start   TEXT,
        expires_at    TEXT,
        lang          TEXT DEFAULT 'ar',
        is_active     INTEGER DEFAULT 1,
        created_at    TEXT DEFAULT (datetime('now')),
        last_login    TEXT
      )''');

    await db.execute('''
      CREATE TABLE children (
        id              TEXT PRIMARY KEY,
        parent_id       TEXT REFERENCES users(id) ON DELETE CASCADE,
        name            TEXT NOT NULL,
        age             INTEGER,
        diagnosis       TEXT,
        notes           TEXT,
        avatar_color    TEXT DEFAULT '#7C3AED',
        skill_motor     REAL DEFAULT 50,
        skill_cognitive REAL DEFAULT 50,
        skill_verbal    REAL DEFAULT 50,
        skill_math      REAL DEFAULT 50,
        skill_social    REAL DEFAULT 50,
        total_sessions  INTEGER DEFAULT 0,
        total_score     INTEGER DEFAULT 0,
        created_at      TEXT DEFAULT (datetime('now'))
      )''');

    await db.execute('''
      CREATE TABLE sessions (
        id               TEXT PRIMARY KEY,
        user_id          TEXT REFERENCES users(id),
        child_id         TEXT REFERENCES children(id),
        started_at       TEXT DEFAULT (datetime('now')),
        ended_at         TEXT,
        duration_sec     INTEGER DEFAULT 0,
        protocol         TEXT DEFAULT 'ABA-DTT',
        level            INTEGER DEFAULT 1,
        mood_start       TEXT,
        score            INTEGER DEFAULT 0,
        tasks_total      INTEGER DEFAULT 0,
        tasks_success    INTEGER DEFAULT 0,
        tasks_fail       INTEGER DEFAULT 0,
        tasks_mastered   INTEGER DEFAULT 0,
        avg_attention    REAL DEFAULT 0,
        dominant_emotion TEXT,
        notes            TEXT,
        report_path      TEXT
      )''');

    await db.execute('''
      CREATE TABLE task_records (
        id          TEXT PRIMARY KEY,
        session_id  TEXT REFERENCES sessions(id) ON DELETE CASCADE,
        task_type   TEXT,
        task_name   TEXT,
        domain      TEXT,
        protocol    TEXT,
        level       INTEGER DEFAULT 1,
        result      TEXT,
        attempts    INTEGER DEFAULT 1,
        time_ms     INTEGER DEFAULT 0,
        tokens      INTEGER DEFAULT 0,
        attention   REAL DEFAULT 0,
        emotion     TEXT,
        timestamp   TEXT DEFAULT (datetime('now'))
      )''');

    await db.execute('''
      CREATE TABLE assessments (
        id         TEXT PRIMARY KEY,
        child_id   TEXT REFERENCES children(id),
        type       TEXT,
        score      REAL,
        answers    TEXT,
        notes      TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )''');
  }

  // ── USERS ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createTrialUser({
    required String email,
    required String fullName,
    String childName = '',
    int childAge = 6,
    String lang = 'ar',
  }) async {
    final uid = _uuid.v4();
    final pin = _generatePin();
    final now = DateTime.now().toUtc();
    final exp = now.add(const Duration(days: 15));

    await db.insert('users', {
      'id':          uid,
      'email':       email.toLowerCase(),
      'full_name':   fullName,
      'pin':         pin,
      'plan':        'trial',
      'trial_start': now.toIso8601String(),
      'expires_at':  exp.toIso8601String(),
      'lang':        lang,
    });

    String? cid;
    if (childName.isNotEmpty) {
      cid = _uuid.v4();
      await db.insert('children', {
        'id':        cid,
        'parent_id': uid,
        'name':      childName,
        'age':       childAge,
      });
    }

    return {'userId': uid, 'pin': pin, 'expiresAt': exp.toIso8601String(), 'childId': cid};
  }

  Future<Map<String, dynamic>?> loginPin(String email, String pin) async {
    final rows = await db.query(
      'users',
      where: 'email = ? AND pin = ? AND is_active = 1',
      whereArgs: [email.toLowerCase(), pin],
    );
    if (rows.isEmpty) return null;
    await db.update('users',
      {'last_login': DateTime.now().toUtc().toIso8601String()},
      where: 'id = ?', whereArgs: [rows.first['id']],
    );
    return Map<String, dynamic>.from(rows.first);
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  bool isLicenseValid(Map<String, dynamic> user) {
    final expStr = user['expires_at'] as String?;
    if (expStr == null) return false;
    return DateTime.now().toUtc().isBefore(DateTime.parse(expStr));
  }

  // ── CHILDREN ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getChildren(String parentId) async {
    final rows = await db.query(
      'children',
      where: 'parent_id = ?',
      whereArgs: [parentId],
      orderBy: 'name ASC',
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<Map<String, dynamic>?> getChild(String childId) async {
    final rows = await db.query('children', where: 'id = ?', whereArgs: [childId]);
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<String> addChild({
    required String parentId,
    required String name,
    required int age,
    String diagnosis = '',
    String notes = '',
  }) async {
    final id = _uuid.v4();
    await db.insert('children', {
      'id': id, 'parent_id': parentId, 'name': name,
      'age': age, 'diagnosis': diagnosis, 'notes': notes,
    });
    return id;
  }

  Future<void> updateChildSkill(String childId, String domain, double delta) async {
    final colMap = {
      'motor':     'skill_motor',
      'cognitive': 'skill_cognitive',
      'verbal':    'skill_verbal',
      'math':      'skill_math',
      'social':    'skill_social',
      'حركي':      'skill_motor',
      'معرفي':     'skill_cognitive',
      'لفظي':      'skill_verbal',
      'رياضي':     'skill_math',
      'اجتماعي':   'skill_social',
    };
    final col = colMap[domain] ?? 'skill_cognitive';
    await db.rawUpdate(
      'UPDATE children SET $col = MIN(100, MAX(0, $col + ?)) WHERE id = ?',
      [delta, childId],
    );
  }

  // ── SESSIONS ───────────────────────────────────────────────────

  Future<String> startSession({
    required String userId,
    required String childId,
    String protocol = 'ABA-DTT',
    String mood = '',
  }) async {
    final id = _uuid.v4();
    await db.insert('sessions', {
      'id':         id,
      'user_id':    userId,
      'child_id':   childId,
      'protocol':   protocol,
      'mood_start': mood,
    });
    return id;
  }

  Future<void> endSession(String sessionId, Map<String, dynamic> data) async {
    await db.update('sessions', {
      'ended_at':        DateTime.now().toUtc().toIso8601String(),
      'duration_sec':    data['durationSec'] ?? 0,
      'score':           data['score'] ?? 0,
      'tasks_total':     data['tasksTotal'] ?? 0,
      'tasks_success':   data['tasksSuccess'] ?? 0,
      'tasks_fail':      data['tasksFail'] ?? 0,
      'tasks_mastered':  data['tasksMastered'] ?? 0,
      'avg_attention':   data['avgAttention'] ?? 0.0,
      'dominant_emotion':data['dominantEmotion'] ?? '',
      'notes':           data['notes'] ?? '',
      'report_path':     data['reportPath'] ?? '',
    }, where: 'id = ?', whereArgs: [sessionId]);

    // Update child totals
    final rows = await db.query('sessions', where: 'id = ?', whereArgs: [sessionId]);
    if (rows.isNotEmpty) {
      final childId = rows.first['child_id'] as String;
      await db.rawUpdate(
        'UPDATE children SET total_sessions = total_sessions + 1, '
        'total_score = total_score + ? WHERE id = ?',
        [data['score'] ?? 0, childId],
      );
    }
  }

  Future<void> saveTaskRecord(String sessionId, Map<String, dynamic> data) async {
    await db.insert('task_records', {
      'id':         _uuid.v4(),
      'session_id': sessionId,
      'task_type':  data['type'] ?? '',
      'task_name':  data['name'] ?? '',
      'domain':     data['domain'] ?? '',
      'protocol':   data['protocol'] ?? 'ABA-DTT',
      'level':      data['level'] ?? 1,
      'result':     data['result'] ?? '',
      'attempts':   data['attempts'] ?? 1,
      'time_ms':    data['timeMs'] ?? 0,
      'tokens':     data['tokens'] ?? 0,
      'attention':  data['attention'] ?? 0.0,
      'emotion':    data['emotion'] ?? '',
    });
  }

  Future<List<Map<String, dynamic>>> getSessionHistory(
      String childId, {int limit = 20}) async {
    final rows = await db.query(
      'sessions',
      where: 'child_id = ? AND ended_at IS NOT NULL',
      whereArgs: [childId],
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<Map<String, dynamic>> getAnalytics(String childId) async {
    final child = await getChild(childId);
    final sessions = await getSessionHistory(childId, limit: 10);
    return {
      'child':    child ?? {},
      'sessions': sessions,
      'skills': {
        'motor':     (child?['skill_motor']     ?? 50.0) as double,
        'cognitive': (child?['skill_cognitive'] ?? 50.0) as double,
        'verbal':    (child?['skill_verbal']    ?? 50.0) as double,
        'math':      (child?['skill_math']      ?? 50.0) as double,
        'social':    (child?['skill_social']    ?? 50.0) as double,
      },
    };
  }

  // ── helpers ────────────────────────────────────────────────────
  String _generatePin() {
    final rng = DateTime.now().millisecondsSinceEpoch;
    return (100000 + rng % 900000).toString();
  }
}
