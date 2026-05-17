import '../models/personnel.dart';
import '../database/database_helper.dart';

class PersonnelService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Ekle
  Future<int> insert(Personnel personnel) async {
    final db = await _dbHelper.database;
    return await db.insert('personnel', _toMap(personnel));
  }

  // Tümünü Getir
  Future<List<Personnel>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('personnel', orderBy: 'created_at DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  // ID ile Getir
  Future<Personnel?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('personnel', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Departmana göre getir
  Future<List<Personnel>> getByDepartment(int departmentId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'personnel',
      where: 'department_id = ?',
      whereArgs: [departmentId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Güncelle
  Future<int> update(Personnel personnel) async {
    final db = await _dbHelper.database;
    return await db.update(
      'personnel',
      _toMap(personnel),
      where: 'id = ?',
      whereArgs: [personnel.id],
    );
  }

  // Sil
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('personnel', where: 'id = ?', whereArgs: [id]);
  }

  // Ara
  Future<List<Personnel>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'personnel',
      where: 'name LIKE ? OR surname LIKE ? OR email LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Map<String, dynamic> _toMap(Personnel personnel) {
    return {
      'id': personnel.id,
      'name': personnel.name,
      'surname': personnel.surname,
      'phone': personnel.phone,
      'email': personnel.email,
      'tc_no': personnel.tcNo,
      'department_id': personnel.departmentId,
      'department_name': personnel.departmentName,
      'start_date': personnel.startDate?.toIso8601String(),
      'birth_date': personnel.birthDate?.toIso8601String(),
      'is_active': personnel.isActive ? 1 : 0,
      'salary': personnel.salary,
      'address': personnel.address,
      'image_url': personnel.imageUrl,
      'account_no': personnel.accountNo,
      'iban': personnel.iban,
    };
  }

  Personnel _fromMap(Map<String, dynamic> map) {
    return Personnel(
      id: map['id'] as int?,
      name: map['name'] as String,
      surname: map['surname'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      tcNo: map['tc_no'] as String?,
      departmentId: map['department_id'] as int?,
      departmentName: map['department_name'] as String?,
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date'] as String) : null,
      birthDate: map['birth_date'] != null ? DateTime.parse(map['birth_date'] as String) : null,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      salary: map['salary'] != null ? (map['salary'] as num).toDouble() : null,
      address: map['address'] as String?,
      imageUrl: map['image_url'] as String?,
      accountNo: map['account_no'] as String? ?? '',
      iban: map['iban'] as String? ?? '',
    );
  }
}

