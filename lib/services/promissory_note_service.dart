import '../models/promissory_note.dart';
import '../database/database_helper.dart';

class PromissoryNoteService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(PromissoryNote note) async {
    final db = await _dbHelper.database;
    return await db.insert('promissory_notes', _toMap(note));
  }

  Future<List<PromissoryNote>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('promissory_notes', orderBy: 'id DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<PromissoryNote?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'promissory_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  Future<List<PromissoryNote>> getByStatus(String status) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'promissory_notes',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<List<PromissoryNote>> getOverdue() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'promissory_notes',
      where: 'status = ? AND due_date < ?',
      whereArgs: ['Beklemede', now],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<int> update(PromissoryNote note) async {
    final db = await _dbHelper.database;
    return await db.update(
      'promissory_notes',
      _toMap(note),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'promissory_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<PromissoryNote>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'promissory_notes',
      where: 'note_no LIKE ? OR debtor_name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Map<String, dynamic> _toMap(PromissoryNote note) {
    return {
      'id': note.id,
      'note_no': note.noteNo,
      'debtor_name': note.debtorName,
      'debtor_phone': note.debtorPhone,
      'debtor_email': note.debtorEmail,
      'debtor_address': note.debtorAddress,
      'debtor_tc_no': note.debtorTcNo,
      'amount': note.amount,
      'issue_date': note.issueDate.toIso8601String(),
      'due_date': note.dueDate.toIso8601String(),
      'description': note.description,
      'status': note.status,
      'direction': note.direction,
      'payment_date': note.paymentDate?.toIso8601String(),
      'payment_method': note.paymentMethod,
      'payment_reference': note.paymentReference,
      'notes': note.notes,
      'related_income_id': note.relatedIncomeId,
      'related_expense_id': note.relatedExpenseId,
      'created_by': note.createdBy,
    };
  }

  PromissoryNote _fromMap(Map<String, dynamic> map) {
    return PromissoryNote(
      id: map['id'] as int?,
      noteNo: map['note_no'] as String,
      debtorName: map['debtor_name'] as String,
      debtorPhone: map['debtor_phone'] as String?,
      debtorEmail: map['debtor_email'] as String?,
      debtorAddress: map['debtor_address'] as String?,
      debtorTcNo: map['debtor_tc_no'] as String?,
      amount: (map['amount'] as num).toDouble(),
      issueDate: DateTime.parse(map['issue_date'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      description: map['description'] as String?,
      status: map['status'] as String,
      direction: map['direction'] as String? ?? 'Alınacak',
      paymentDate: map['payment_date'] != null
          ? DateTime.parse(map['payment_date'] as String)
          : null,
      paymentMethod: map['payment_method'] as String?,
      paymentReference: map['payment_reference'] as String?,
      notes: map['notes'] as String?,
      relatedIncomeId: map['related_income_id'] as int?,
      relatedExpenseId: map['related_expense_id'] as int?,
      createdBy: map['created_by'] as String?,
    );
  }
}
