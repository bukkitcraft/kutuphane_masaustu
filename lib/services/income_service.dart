import '../models/income.dart';
import '../database/database_helper.dart';

class IncomeService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Income income) async {
    final db = await _dbHelper.database;
    return await db.insert('incomes', _toMap(income));
  }

  Future<List<Income>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('incomes', orderBy: 'id DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<Income?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('incomes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  Future<List<Income>> getByCategory(String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'incomes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'income_date DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<List<Income>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'incomes',
      where: 'income_date >= ? AND income_date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'income_date DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<int> update(Income income) async {
    final db = await _dbHelper.database;
    return await db.update(
      'incomes',
      _toMap(income),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Income>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'incomes',
      where: 'title LIKE ? OR income_no LIKE ? OR payer_name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'income_date DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'incomes',
      columns: ['SUM(amount) as total'],
      where: 'income_date >= ? AND income_date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    if (maps.isEmpty || maps.first['total'] == null) return 0.0;
    return (maps.first['total'] as num).toDouble();
  }

  Map<String, dynamic> _toMap(Income income) {
    return {
      'id': income.id,
      'income_no': income.incomeNo,
      'title': income.title,
      'description': income.description,
      'amount': income.amount,
      'category': income.category,
      'income_date': income.incomeDate.toIso8601String(),
      'payer_name': income.payerName,
      'payer_phone': income.payerPhone,
      'payer_email': income.payerEmail,
      'payment_method': income.paymentMethod,
      'reference_no': income.referenceNo,
      'notes': income.notes,
      'related_member_id': income.relatedMemberId,
      'related_escrow_id': income.relatedEscrowId,
      'created_by': income.createdBy,
    };
  }

  Income _fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as int?,
      incomeNo: map['income_no'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      incomeDate: DateTime.parse(map['income_date'] as String),
      payerName: map['payer_name'] as String?,
      payerPhone: map['payer_phone'] as String?,
      payerEmail: map['payer_email'] as String?,
      paymentMethod: map['payment_method'] as String?,
      referenceNo: map['reference_no'] as String?,
      notes: map['notes'] as String?,
      relatedMemberId: map['related_member_id'] as int?,
      relatedEscrowId: map['related_escrow_id'] as int?,
      createdBy: map['created_by'] as String?,
    );
  }
}

