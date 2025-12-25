import '../models/book.dart';
import '../database/database_helper.dart';

class BookService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Ekle
  Future<int> insert(Book book) async {
    final db = await _dbHelper.database;
    return await db.insert('books', _toMap(book));
  }

  // Tümünü Getir
  Future<List<Book>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('books', orderBy: 'created_at DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  // ID ile Getir
  Future<Book?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('books', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Kategoriye göre getir
  Future<List<Book>> getByCategory(int categoryId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'books',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'title ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Yayınevine göre getir
  Future<List<Book>> getByPublisher(int publisherId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'books',
      where: 'publisher_id = ?',
      whereArgs: [publisherId],
      orderBy: 'title ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Yazara göre getir
  Future<List<Book>> getByAuthor(int authorId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'books',
      where: 'author_id = ?',
      whereArgs: [authorId],
      orderBy: 'title ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Güncelle
  Future<int> update(Book book) async {
    final db = await _dbHelper.database;
    return await db.update(
      'books',
      _toMap(book),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  // Sil
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  // Ara
  Future<List<Book>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'books',
      where: 'title LIKE ? OR isbn LIKE ? OR author_name LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'title ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Kopya sayılarını güncelle
  Future<void> updateCopies(int bookId, int available, int borrowed) async {
    final db = await _dbHelper.database;
    await db.update(
      'books',
      {
        'available_copies': available,
        'borrowed_copies': borrowed,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Map<String, dynamic> _toMap(Book book) {
    return {
      'id': book.id,
      'isbn': book.isbn,
      'title': book.title,
      'subtitle': book.subtitle,
      'author_id': book.authorId,
      'author_name': book.authorName,
      'category_id': book.categoryId,
      'category_name': book.categoryName,
      'publisher_id': book.publisherId,
      'publisher_name': book.publisherName,
      'publication_year': book.publicationYear,
      'page_count': book.pageCount,
      'language': book.language,
      'description': book.description,
      'cover_image_url': book.coverImageUrl,
      'total_copies': book.totalCopies,
      'available_copies': book.availableCopies,
      'borrowed_copies': book.borrowedCopies,
      'location': book.location,
      'added_date': book.addedDate?.toIso8601String(),
      'is_active': book.isActive ? 1 : 0,
    };
  }

  Book _fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int?,
      isbn: map['isbn'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String?,
      authorId: map['author_id'] as int?,
      authorName: map['author_name'] as String?,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?,
      publisherId: map['publisher_id'] as int?,
      publisherName: map['publisher_name'] as String?,
      publicationYear: map['publication_year'] as int?,
      pageCount: map['page_count'] as int?,
      language: map['language'] as String?,
      description: map['description'] as String?,
      coverImageUrl: map['cover_image_url'] as String?,
      totalCopies: map['total_copies'] as int? ?? 1,
      availableCopies: map['available_copies'] as int? ?? 1,
      borrowedCopies: map['borrowed_copies'] as int? ?? 0,
      location: map['location'] as String?,
      addedDate: map['added_date'] != null ? DateTime.parse(map['added_date'] as String) : null,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}

