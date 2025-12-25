import '../models/check.dart';
import '../database/database_helper.dart';

class CheckService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Check check) async {
    final db = await _dbHelper.database;
    return await db.insert('checks', _toMap(check));
  }

  Future<List<Check>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('checks', orderBy: 'id DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<Check?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('checks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  Future<List<Check>> getByStatus(String status) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'checks',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<List<Check>> getOverdue() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'checks',
      where: 'status = ? AND due_date < ?',
      whereArgs: ['Beklemede', now],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<int> update(Check check) async {
    final db = await _dbHelper.database;
    return await db.update(
      'checks',
      _toMap(check),
      where: 'id = ?',
      whereArgs: [check.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('checks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Check>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'checks',
      where: 'check_no LIKE ? OR bank_name LIKE ? OR drawer_name LIKE ? OR check_number LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Map<String, dynamic> _toMap(Check check) {
    return {
      'id': check.id,
      'check_no': check.checkNo,
      'bank_name': check.bankName,
      'account_no': check.accountNo,
      'iban': check.iban,
      'check_number': check.checkNumber,
      'amount': check.amount,
      'issue_date': check.issueDate.toIso8601String(),
      'due_date': check.dueDate.toIso8601String(),
      'drawer_name': check.drawerName,
      'drawer_phone': check.drawerPhone,
      'drawer_email': check.drawerEmail,
      'status': check.status,
      'direction': check.direction,
      'collection_date': check.collectionDate?.toIso8601String(),
      'collection_method': check.collectionMethod,
      'notes': check.notes,
      'related_income_id': check.relatedIncomeId,
      'related_expense_id': check.relatedExpenseId,
      'created_by': check.createdBy,
    };
  }

  Check _fromMap(Map<String, dynamic> map) {
    return Check(
      id: map['id'] as int?,
      checkNo: map['check_no'] as String,
      bankName: map['bank_name'] as String,
      accountNo: map['account_no'] as String,
      iban: map['iban'] as String?,
      checkNumber: map['check_number'] as String,
      amount: (map['amount'] as num).toDouble(),
      issueDate: DateTime.parse(map['issue_date'] as String),
      dueDate: DateTime.parse(map['due_date'] as String),
      drawerName: map['drawer_name'] as String?,
      drawerPhone: map['drawer_phone'] as String?,
      drawerEmail: map['drawer_email'] as String?,
      status: map['status'] as String,
      direction: map['direction'] as String? ?? 'Alınacak',
      collectionDate: map['collection_date'] != null ? DateTime.parse(map['collection_date'] as String) : null,
      collectionMethod: map['collection_method'] as String?,
      notes: map['notes'] as String?,
      relatedIncomeId: map['related_income_id'] as int?,
      relatedExpenseId: map['related_expense_id'] as int?,
      createdBy: map['created_by'] as String?,
    );
  }
}

