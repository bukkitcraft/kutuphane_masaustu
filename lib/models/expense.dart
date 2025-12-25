class Expense {
  final int? id;
  final String expenseNo;
  final String title;
  final String? description;
  final double amount;
  final String category; // Kira, Maaş, Kırtasiye, Kitap Alımı, Bakım, Diğer
  final DateTime expenseDate;
  final String? payeeName;
  final String? payeePhone;
  final String? payeeEmail;
  final String? paymentMethod; // Nakit, Kredi Kartı, Banka Transferi, Çek
  final String? referenceNo;
  final String? invoiceNo;
  final String? notes;
  final int? relatedCompanyId;
  final String? createdBy;

  Expense({
    this.id,
    required this.expenseNo,
    required this.title,
    this.description,
    required this.amount,
    required this.category,
    required this.expenseDate,
    this.payeeName,
    this.payeePhone,
    this.payeeEmail,
    this.paymentMethod,
    this.referenceNo,
    this.invoiceNo,
    this.notes,
    this.relatedCompanyId,
    this.createdBy,
  });

  Expense copyWith({
    int? id,
    String? expenseNo,
    String? title,
    String? description,
    double? amount,
    String? category,
    DateTime? expenseDate,
    String? payeeName,
    String? payeePhone,
    String? payeeEmail,
    String? paymentMethod,
    String? referenceNo,
    String? invoiceNo,
    String? notes,
    int? relatedCompanyId,
    String? createdBy,
  }) {
    return Expense(
      id: id ?? this.id,
      expenseNo: expenseNo ?? this.expenseNo,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      expenseDate: expenseDate ?? this.expenseDate,
      payeeName: payeeName ?? this.payeeName,
      payeePhone: payeePhone ?? this.payeePhone,
      payeeEmail: payeeEmail ?? this.payeeEmail,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNo: referenceNo ?? this.referenceNo,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      notes: notes ?? this.notes,
      relatedCompanyId: relatedCompanyId ?? this.relatedCompanyId,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  String get formattedDate {
    return '${expenseDate.day.toString().padLeft(2, '0')}.${expenseDate.month.toString().padLeft(2, '0')}.${expenseDate.year}';
  }

  String get formattedAmount {
    return '₺${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}

