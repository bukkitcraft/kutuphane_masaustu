import '../models/company.dart';
import '../database/database_helper.dart';

class CompanyService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Ekle
  Future<int> insert(Company company) async {
    final db = await _dbHelper.database;
    return await db.insert('companies', _toMap(company));
  }

  // Tümünü Getir
  Future<List<Company>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('companies', orderBy: 'created_at DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  // ID ile Getir
  Future<Company?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('companies', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Güncelle
  Future<int> update(Company company) async {
    final db = await _dbHelper.database;
    return await db.update(
      'companies',
      _toMap(company),
      where: 'id = ?',
      whereArgs: [company.id],
    );
  }

  // Sil
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('companies', where: 'id = ?', whereArgs: [id]);
  }

  // Ara
  Future<List<Company>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'companies',
      where: 'name LIKE ? OR tax_number LIKE ? OR phone LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Kitap sayısını güncelle
  Future<void> updateBooksCount(int companyId, int count) async {
    final db = await _dbHelper.database;
    await db.update(
      'companies',
      {'books_count': count},
      where: 'id = ?',
      whereArgs: [companyId],
    );
  }

  Map<String, dynamic> _toMap(Company company) {
    return {
      'id': company.id,
      'name': company.name,
      'tax_number': company.taxNumber,
      'tax_office': company.taxOffice,
      'phone': company.phone,
      'email': company.email,
      'address': company.address,
      'city': company.city,
      'country': company.country,
      'website': company.website,
      'contact_person': company.contactPerson,
      'contact_phone': company.contactPhone,
      'contact_email': company.contactEmail,
      'company_type': company.companyType,
      'registration_date': company.registrationDate?.toIso8601String(),
      'is_active': company.isActive ? 1 : 0,
      'notes': company.notes,
      'books_count': company.booksCount,
      'image_url': company.imageUrl,
    };
  }

  Company _fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as int?,
      name: map['name'] as String,
      taxNumber: map['tax_number'] as String?,
      taxOffice: map['tax_office'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      country: map['country'] as String?,
      website: map['website'] as String?,
      contactPerson: map['contact_person'] as String?,
      contactPhone: map['contact_phone'] as String?,
      contactEmail: map['contact_email'] as String?,
      companyType: map['company_type'] as String,
      registrationDate: map['registration_date'] != null ? DateTime.parse(map['registration_date'] as String) : null,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      notes: map['notes'] as String?,
      booksCount: map['books_count'] as int? ?? 0,
      imageUrl: map['image_url'] as String?,
    );
  }
}

