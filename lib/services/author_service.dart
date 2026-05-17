import '../models/author.dart';
import '../database/database_helper.dart';

class AuthorService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Ekle
  Future<int> insert(Author author) async {
    final db = await _dbHelper.database;
    return await db.insert('authors', _toMap(author));
  }

  // Tümünü Getir
  Future<List<Author>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('authors', orderBy: 'id DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  // ID ile Getir
  Future<Author?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('authors', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Güncelle
  Future<int> update(Author author) async {
    final db = await _dbHelper.database;
    return await db.update(
      'authors',
      _toMap(author),
      where: 'id = ?',
      whereArgs: [author.id],
    );
  }

  // Sil
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('authors', where: 'id = ?', whereArgs: [id]);
  }

  // Ara
  Future<List<Author>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'authors',
      where: 'name LIKE ? OR surname LIKE ? OR nationality LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Kitap sayısını güncelle
  Future<void> updateBooksCount(int authorId, int count) async {
    final db = await _dbHelper.database;
    await db.update(
      'authors',
      {'books_count': count},
      where: 'id = ?',
      whereArgs: [authorId],
    );
  }

  Map<String, dynamic> _toMap(Author author) {
    return {
      'id': author.id,
      'name': author.name,
      'surname': author.surname,
      'biography': author.biography,
      'birth_date': author.birthDate?.toIso8601String(),
      'death_date': author.deathDate?.toIso8601String(),
      'nationality': author.nationality,
      'image_url': author.imageUrl,
      'books_count': author.booksCount,
    };
  }

  Author _fromMap(Map<String, dynamic> map) {
    return Author(
      id: map['id'] as int?,
      name: map['name'] as String,
      surname: map['surname'] as String,
      biography: map['biography'] as String?,
      birthDate: map['birth_date'] != null ? DateTime.parse(map['birth_date'] as String) : null,
      deathDate: map['death_date'] != null ? DateTime.parse(map['death_date'] as String) : null,
      nationality: map['nationality'] as String?,
      imageUrl: map['image_url'] as String?,
      booksCount: map['books_count'] as int? ?? 0,
    );
  }
}

