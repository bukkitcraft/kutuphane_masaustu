import '../models/user.dart';
import '../database/database_helper.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class UserService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Şifreyi hash'le (basit MD5 hash - production'da daha güvenli hash kullanılmalı)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<int> insert(User user) async {
    final db = await _dbHelper.database;
    final hashedPassword = _hashPassword(user.password);
    // Yeni kullanıcı için otomatik olarak oluşturulma tarihini ayarla
    final userWithDate = user.copyWith(
      password: hashedPassword,
      createdAt: DateTime.now(),
    );
    
    // allowed_menus sütununun var olup olmadığını kontrol et
    final insertMap = _toMap(userWithDate);
    
    // Sütun yoksa allowed_menus'u map'ten çıkar
    try {
      // Önce sütunun var olup olmadığını kontrol et
      final tableInfo = await db.rawQuery('PRAGMA table_info(users)');
      final columnExists = tableInfo.any((column) => column['name'] == 'allowed_menus');
      
      if (!columnExists) {
        // Sütun yoksa map'ten çıkar
        insertMap.remove('allowed_menus');
        // Sütunu eklemeyi dene (upgrade çalışmamış olabilir)
        try {
          await db.execute('ALTER TABLE users ADD COLUMN allowed_menus TEXT');
          // Sütun eklendi, tekrar map'e ekle
          if (userWithDate.allowedMenus != null) {
            insertMap['allowed_menus'] = userWithDate.allowedMenus;
          }
        } catch (_) {
          // Sütun eklenemedi, devam et (allowed_menus olmadan)
        }
      }
    } catch (_) {
      // Kontrol hatası, allowed_menus'u çıkar ve devam et
      insertMap.remove('allowed_menus');
    }
    
    return await db.insert('users', insertMap);
  }

  Future<List<User>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('users', orderBy: 'created_at DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<User?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  Future<User?> getByUsername(String username) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  Future<User?> authenticate(String username, String password) async {
    final user = await getByUsername(username);
    if (user == null) return null;
    
    final hashedPassword = _hashPassword(password);
    if (user.password == hashedPassword) {
      return user;
    }
    return null;
  }

  Future<int> update(User user) async {
    final db = await _dbHelper.database;
    final hashedPassword = user.password.length == 32 && user.password.contains(RegExp(r'^[a-f0-9]+$'))
        ? user.password // Zaten hash'lenmiş
        : _hashPassword(user.password);
    
    // Update işleminde sadece güncellenecek alanları ekle
    final updateMap = <String, dynamic>{
      'username': user.username,
      'password': hashedPassword,
      'role': user.role,
    };
    
    // allowed_menus sütununun var olup olmadığını kontrol et
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(users)');
      final columnExists = tableInfo.any((column) => column['name'] == 'allowed_menus');
      
      if (columnExists) {
        updateMap['allowed_menus'] = user.allowedMenus; // null olabilir
      } else {
        // Sütun yoksa eklemeyi dene
        try {
          await db.execute('ALTER TABLE users ADD COLUMN allowed_menus TEXT');
          updateMap['allowed_menus'] = user.allowedMenus;
        } catch (_) {
          // Sütun eklenemedi, devam et (allowed_menus olmadan)
        }
      }
    } catch (_) {
      // Kontrol hatası, allowed_menus olmadan devam et
    }
    
    // created_at ve id UPDATE'de kullanılmaz
    
    return await db.update(
      'users',
      updateMap,
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, dynamic> _toMap(User user) {
    final map = <String, dynamic>{
      'username': user.username,
      'password': user.password,
      'role': user.role,
    };
    
    // id sadece null değilse ekle (INSERT işlemlerinde null olabilir)
    if (user.id != null) {
      map['id'] = user.id;
    }
    
    // allowed_menus sadece null değilse ekle
    if (user.allowedMenus != null) {
      map['allowed_menus'] = user.allowedMenus;
    }
    
    // created_at sadece null değilse ekle
    if (user.createdAt != null) {
      map['created_at'] = user.createdAt!.toIso8601String();
    }
    
    return map;
  }

  User _fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
      allowedMenus: map['allowed_menus'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}

