import '../models/book_category.dart';
import '../database/database_helper.dart';

class BookCategoryService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Ekle
  Future<int> insert(BookCategory category) async {
    final db = await _dbHelper.database;
    return await db.insert('book_categories', _toMap(category));
  }

  // Tümünü Getir
  Future<List<BookCategory>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('book_categories', orderBy: 'id DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  // ID ile Getir
  Future<BookCategory?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('book_categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Güncelle
  Future<int> update(BookCategory category) async {
    final db = await _dbHelper.database;
    return await db.update(
      'book_categories',
      _toMap(category),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // Sil
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('book_categories', where: 'id = ?', whereArgs: [id]);
  }

  // Ara
  Future<List<BookCategory>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'book_categories',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Kitap sayısını güncelle
  Future<void> updateBooksCount(int categoryId, int count) async {
    final db = await _dbHelper.database;
    await db.update(
      'book_categories',
      {'books_count': count},
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  Map<String, dynamic> _toMap(BookCategory category) {
    return {
      'id': category.id,
      'name': category.name,
      'description': category.description,
      'color_code': category.colorCode,
      'books_count': category.booksCount,
    };
  }

  BookCategory _fromMap(Map<String, dynamic> map) {
    return BookCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      colorCode: map['color_code'] as String?,
      booksCount: map['books_count'] as int? ?? 0,
    );
  }
}

