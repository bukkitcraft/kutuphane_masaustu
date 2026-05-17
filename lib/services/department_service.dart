import '../models/department.dart';
import '../database/database_helper.dart';

class DepartmentService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Ekle
  Future<int> insert(Department department) async {
    final db = await _dbHelper.database;
    return await db.insert('departments', _toMap(department));
  }

  // Tümünü Getir
  Future<List<Department>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('departments', orderBy: 'created_at DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  // ID ile Getir
  Future<Department?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('departments', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Güncelle
  Future<int> update(Department department) async {
    final db = await _dbHelper.database;
    return await db.update(
      'departments',
      _toMap(department),
      where: 'id = ?',
      whereArgs: [department.id],
    );
  }

  // Sil
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('departments', where: 'id = ?', whereArgs: [id]);
  }

  // Ara
  Future<List<Department>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'departments',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Personel sayısını güncelle
  Future<void> updatePersonnelCount(int departmentId, int count) async {
    final db = await _dbHelper.database;
    await db.update(
      'departments',
      {'books_count': count}, // Veritabanında books_count olarak saklanıyor ama personel sayısı için kullanılıyor
      where: 'id = ?',
      whereArgs: [departmentId],
    );
  }

  Map<String, dynamic> _toMap(Department department) {
    return {
      'id': department.id,
      'name': department.name,
      'description': department.description,
      'color_code': department.colorCode,
      'books_count': department.personnelCount,
    };
  }

  Department _fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      colorCode: map['color_code'] as String?,
      personnelCount: map['books_count'] as int? ?? 0,
    );
  }
}

