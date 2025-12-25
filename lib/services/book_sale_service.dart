import '../models/book_sale.dart';
import '../database/database_helper.dart';

class BookSaleService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(BookSale sale) async {
    final db = await _dbHelper.database;
    return await db.insert('book_sales', _toMap(sale));
  }

  Future<List<BookSale>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('book_sales', orderBy: 'sale_date DESC, created_at DESC');
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<BookSale?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('book_sales', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  Future<List<BookSale>> getByBookId(int bookId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'book_sales',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'sale_date DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<int> update(BookSale sale) async {
    final db = await _dbHelper.database;
    return await db.update(
      'book_sales',
      _toMap(sale),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('book_sales', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BookSale>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'book_sales',
      where: 'book_title LIKE ? OR sale_no LIKE ? OR customer_name LIKE ? OR book_isbn LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'sale_date DESC, created_at DESC',
    );
    return maps.map((map) => _fromMap(map)).toList();
  }

  Future<double> getTotalSalesAmount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT SUM(final_amount) as total FROM book_sales');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getTotalSalesCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM book_sales');
    return (result.first['count'] as int?) ?? 0;
  }

  Map<String, dynamic> _toMap(BookSale sale) {
    return {
      'id': sale.id,
      'sale_no': sale.saleNo,
      'book_id': sale.bookId,
      'book_title': sale.bookTitle,
      'book_isbn': sale.bookIsbn,
      'book_author': sale.bookAuthor,
      'quantity': sale.quantity,
      'unit_price': sale.unitPrice,
      'total_amount': sale.totalAmount,
      'discount': sale.discount,
      'final_amount': sale.finalAmount,
      'customer_name': sale.customerName,
      'customer_phone': sale.customerPhone,
      'customer_email': sale.customerEmail,
      'customer_address': sale.customerAddress,
      'member_id': sale.memberId,
      'sale_date': sale.saleDate.toIso8601String(),
      'payment_method': sale.paymentMethod,
      'notes': sale.notes,
      'created_by': sale.createdBy,
    };
  }

  BookSale _fromMap(Map<String, dynamic> map) {
    return BookSale(
      id: map['id'] as int?,
      saleNo: map['sale_no'] as String,
      bookId: map['book_id'] as int,
      bookTitle: map['book_title'] as String,
      bookIsbn: map['book_isbn'] as String?,
      bookAuthor: map['book_author'] as String?,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (map['final_amount'] as num).toDouble(),
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      customerEmail: map['customer_email'] as String?,
      customerAddress: map['customer_address'] as String?,
      memberId: map['member_id'] as int?,
      saleDate: DateTime.parse(map['sale_date'] as String),
      paymentMethod: map['payment_method'] as String?,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as String?,
    );
  }
}

