import '../models/reminder.dart';
import '../database/database_helper.dart';

class ReminderService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Reminder reminder) async {
    final db = await _dbHelper.database;
    
    // Tablonun var olup olmadığını kontrol et
    try {
      final tableInfo = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='reminders'"
      );
      
      if (tableInfo.isEmpty) {
        // Tablo yoksa oluştur
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            type TEXT NOT NULL,
            location TEXT NOT NULL,
            record_date TEXT NOT NULL,
            reminder_date TEXT NOT NULL,
            description TEXT,
            is_completed INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        
        // İndeksler
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_date ON reminders(reminder_date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_reminders_completed ON reminders(is_completed)');
      }
    } catch (e) {
      // Hata durumunda devam et
      print('Warning: Could not check/create reminders table: $e');
    }
    
    return await db.insert('reminders', _toMap(reminder));
  }

  Future<List<Reminder>> getAll() async {
    final db = await _dbHelper.database;
    
    // Tablonun var olup olmadığını kontrol et
    try {
      final tableInfo = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='reminders'"
      );
      
      if (tableInfo.isEmpty) {
        // Tablo yoksa boş liste döndür
        return [];
      }
    } catch (e) {
      // Hata durumunda boş liste döndür
      return [];
    }
    
    final maps = await db.query('reminders', orderBy: 'reminder_date ASC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<List<Reminder>> getUpcoming() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'reminders',
      where: 'reminder_date >= ? AND is_completed = ?',
      whereArgs: [now, 0],
      orderBy: 'reminder_date ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<List<Reminder>> getOverdue() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'reminders',
      where: 'reminder_date < ? AND is_completed = ?',
      whereArgs: [now, 0],
      orderBy: 'reminder_date ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<List<Reminder>> getDueReminders() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final inOneHour = now.add(const Duration(hours: 1)).toIso8601String();
    final maps = await db.query(
      'reminders',
      where: 'reminder_date >= ? AND reminder_date <= ? AND is_completed = ?',
      whereArgs: [now.toIso8601String(), inOneHour, 0],
      orderBy: 'reminder_date ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<Reminder?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('reminders', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  Future<int> update(Reminder reminder) async {
    final db = await _dbHelper.database;
    return await db.update(
      'reminders',
      _toMap(reminder),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> markAsCompleted(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'reminders',
      {'is_completed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Reminder>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'reminders',
      where: 'title LIKE ? OR type LIKE ? OR location LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'reminder_date ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Map<String, dynamic> _toMap(Reminder reminder) {
    final map = <String, dynamic>{
      'title': reminder.title,
      'type': reminder.type,
      'location': reminder.location,
      'record_date': reminder.recordDate.toIso8601String(),
      'reminder_date': reminder.reminderDate.toIso8601String(),
      'is_completed': reminder.isCompleted ? 1 : 0,
    };
    
    // id sadece null değilse ekle (INSERT işlemlerinde null olabilir)
    if (reminder.id != null) {
      map['id'] = reminder.id;
    }
    
    // description ve created_at sadece null değilse ekle
    if (reminder.description != null) {
      map['description'] = reminder.description;
    }
    
    if (reminder.createdAt != null) {
      map['created_at'] = reminder.createdAt!.toIso8601String();
    }
    
    return map;
  }

  Reminder _fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      title: map['title'] as String,
      type: map['type'] as String,
      location: map['location'] as String,
      recordDate: DateTime.parse(map['record_date'] as String),
      reminderDate: DateTime.parse(map['reminder_date'] as String),
      description: map['description'] as String?,
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}

