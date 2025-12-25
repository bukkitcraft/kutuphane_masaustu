class BookSale {
  final int? id;
  final String saleNo;
  final int bookId;
  final String bookTitle;
  final String? bookIsbn;
  final String? bookAuthor;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final double discount;
  final double finalAmount;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerAddress;
  final int? memberId;
  final DateTime saleDate;
  final String? paymentMethod;
  final String? notes;
  final String? createdBy;

  BookSale({
    this.id,
    required this.saleNo,
    required this.bookId,
    required this.bookTitle,
    this.bookIsbn,
    this.bookAuthor,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalAmount,
    this.discount = 0,
    required this.finalAmount,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.customerAddress,
    this.memberId,
    required this.saleDate,
    this.paymentMethod,
    this.notes,
    this.createdBy,
  });

  BookSale copyWith({
    int? id,
    String? saleNo,
    int? bookId,
    String? bookTitle,
    String? bookIsbn,
    String? bookAuthor,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    double? discount,
    double? finalAmount,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customerAddress,
    int? memberId,
    DateTime? saleDate,
    String? paymentMethod,
    String? notes,
    String? createdBy,
  }) {
    return BookSale(
      id: id ?? this.id,
      saleNo: saleNo ?? this.saleNo,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      bookIsbn: bookIsbn ?? this.bookIsbn,
      bookAuthor: bookAuthor ?? this.bookAuthor,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      discount: discount ?? this.discount,
      finalAmount: finalAmount ?? this.finalAmount,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      customerAddress: customerAddress ?? this.customerAddress,
      memberId: memberId ?? this.memberId,
      saleDate: saleDate ?? this.saleDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  String get formattedSaleDate {
    return '${saleDate.day.toString().padLeft(2, '0')}.${saleDate.month.toString().padLeft(2, '0')}.${saleDate.year}';
  }
}

