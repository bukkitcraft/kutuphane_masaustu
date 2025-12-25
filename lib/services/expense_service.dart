import '../models/expense.dart';
import '../database/database_helper.dart';

class ExpenseService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.insert('expenses', _toMap(expense));
  }

  Future<List<Expense>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('expenses', orderBy: 'id DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<Expense?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('expenses', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  Future<List<Expense>> getByCategory(String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expenses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'expense_date DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<List<Expense>> getByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expenses',
      where: 'expense_date >= ? AND expense_date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'expense_date DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<int> update(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.update(
      'expenses',
      _toMap(expense),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expenses',
      where: 'title LIKE ? OR expense_no LIKE ? OR payee_name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'expense_date DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expenses',
      columns: ['SUM(amount) as total'],
      where: 'expense_date >= ? AND expense_date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    if (maps.isEmpty || maps.first['total'] == null) return 0.0;
    return (maps.first['total'] as num).toDouble();
  }

  Map<String, dynamic> _toMap(Expense expense) {
    return {
      'id': expense.id,
      'expense_no': expense.expenseNo,
      'title': expense.title,
      'description': expense.description,
      'amount': expense.amount,
      'category': expense.category,
      'expense_date': expense.expenseDate.toIso8601String(),
      'payee_name': expense.payeeName,
      'payee_phone': expense.payeePhone,
      'payee_email': expense.payeeEmail,
      'payment_method': expense.paymentMethod,
      'reference_no': expense.referenceNo,
      'invoice_no': expense.invoiceNo,
      'notes': expense.notes,
      'related_company_id': expense.relatedCompanyId,
      'created_by': expense.createdBy,
    };
  }

  Expense _fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      expenseNo: map['expense_no'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      expenseDate: DateTime.parse(map['expense_date'] as String),
      payeeName: map['payee_name'] as String?,
      payeePhone: map['payee_phone'] as String?,
      payeeEmail: map['payee_email'] as String?,
      paymentMethod: map['payment_method'] as String?,
      referenceNo: map['reference_no'] as String?,
      invoiceNo: map['invoice_no'] as String?,
      notes: map['notes'] as String?,
      relatedCompanyId: map['related_company_id'] as int?,
      createdBy: map['created_by'] as String?,
    );
  }
}

