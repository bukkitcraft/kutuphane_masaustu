import '../models/escrow.dart';
import '../database/database_helper.dart';

class EscrowService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Ekle
  Future<int> insert(Escrow escrow) async {
    final db = await _dbHelper.database;
    return await db.insert('escrows', _toMap(escrow));
  }

  // Tümünü Getir
  Future<List<Escrow>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('escrows', orderBy: 'created_at DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  // ID ile Getir
  Future<Escrow?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('escrows', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Emanet No ile Getir
  Future<Escrow?> getByEscrowNo(String escrowNo) async {
    final db = await _dbHelper.database;
    final maps = await db.query('escrows', where: 'escrow_no = ?', whereArgs: [escrowNo]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  // Üyeye göre getir
  Future<List<Escrow>> getByMember(int memberId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'escrows',
      where: 'member_id = ?',
      whereArgs: [memberId],
      orderBy: 'borrow_date DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Kitaba göre getir
  Future<List<Escrow>> getByBook(int bookId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'escrows',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'borrow_date DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Duruma göre getir
  Future<List<Escrow>> getByStatus(String status) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'escrows',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'borrow_date DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // Güncelle
  Future<int> update(Escrow escrow) async {
    final db = await _dbHelper.database;
    return await db.update(
      'escrows',
      _toMap(escrow),
      where: 'id = ?',
      whereArgs: [escrow.id],
    );
  }

  // Sil
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('escrows', where: 'id = ?', whereArgs: [id]);
  }

  // Ara
  Future<List<Escrow>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'escrows',
      where: 'book_title LIKE ? OR member_name LIKE ? OR escrow_no LIKE ? OR book_isbn LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'borrow_date DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  // İade et
  Future<int> returnBook(int id, DateTime returnDate, {double? fineAmount, String? fineReason}) async {
    final db = await _dbHelper.database;
    return await db.update(
      'escrows',
      {
        'status': 'İade Edildi',
        'return_date': returnDate.toIso8601String(),
        'fine_amount': fineAmount,
        'fine_reason': fineReason,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, dynamic> _toMap(Escrow escrow) {
    return {
      'id': escrow.id,
      'escrow_no': escrow.escrowNo,
      'book_id': escrow.bookId,
      'book_title': escrow.bookTitle,
      'book_isbn': escrow.bookIsbn,
      'book_cover_url': escrow.bookCoverUrl,
      'member_id': escrow.memberId,
      'member_name': escrow.memberName,
      'member_no': escrow.memberNo,
      'borrow_date': escrow.borrowDate.toIso8601String(),
      'due_date': escrow.dueDate.toIso8601String(),
      'return_date': escrow.returnDate?.toIso8601String(),
      'status': escrow.status,
      'notes': escrow.notes,
      'personnel_id': escrow.personnelId,
      'personnel_name': escrow.personnelName,
      'fine_amount': escrow.fineAmount,
      'fine_reason': escrow.fineReason,
    };
  }

  Escrow _fromMap(Map<String, dynamic> map) {
    return Escrow(
      id: map['id'] as int?,
      escrowNo: map['escrow_no'] as String,
      bookId: map['book_id'] as int,
      bookTitle: map['book_title'] as String,
      bookIsbn: map['book_isbn'] as String?,
      bookCoverUrl: map['book_cover_url'] as String?,
      memberId: map['member_id'] as int,
      memberName: map['member_name'] as String,
      memberNo: map['member_no'] as String,
      borrowDate: DateTime.parse(map['borrow_date'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      returnDate: map['return_date'] != null ? DateTime.parse(map['return_date'] as String) : null,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      personnelId: map['personnel_id'] as int?,
      personnelName: map['personnel_name'] as String?,
      fineAmount: map['fine_amount'] != null ? (map['fine_amount'] as num).toDouble() : null,
      fineReason: map['fine_reason'] as String?,
    );
  }
}

